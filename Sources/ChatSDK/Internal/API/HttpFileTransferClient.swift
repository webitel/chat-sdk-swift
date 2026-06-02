//
//  HttpFileTransferClient.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 21.05.2026.
//

import Foundation


internal class HttpFileTransferClient: NSObject,
                                       URLSessionDelegate,
                                       URLSessionTaskDelegate,
                                       URLSessionDataDelegate {
    private let mediaPath = "im/media"
    
    private let sslDelegate: SSLPinningDelegate
    private let headerProvider: HeaderProvider
    private let context: ClientContext
    
    private let logger = SDKLogger.make("chat.api.FileTransfer")
    private let taskMapQueue = DispatchQueue(label: "com.api.FileTransfer")
    private let maxErrorBodySize: Int = 64 * 1024
    
    private var taskMap: [Int: TransferContext] = [:]
    
    private lazy var jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()
    
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: nil
        )
    }()
    
    
    init(
        context: ClientContext,
        headerProvider: HeaderProvider
    ) {
        self.context = context
        self.headerProvider = headerProvider
        
        sslDelegate = SSLPinningDelegate(
            context: self.context
        )
    }
    
    
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        guard case let .upload(ctx)? = taskMapQueue.sync(execute: {
            taskMap[task.taskIdentifier]
        }) else { return }
        
        logger.debug("Sent chunk \(bytesSent); total sent: \(totalBytesSent+ctx.uploadedSize)")
        
        ctx.observer.onProgress(uploaded: totalBytesSent, total: nil)
    }
    
    
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        sslDelegate.urlSession(session,
                               didReceive: challenge,
                               completionHandler: completionHandler)
    }
    
    
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        let ctx = taskMapQueue.sync {
            taskMap.removeValue(forKey: task.taskIdentifier)
        }
        
        guard let ctx else { return }
        
        if let error {
            let err = sslDelegate.lastSSLError
            ?? error.asChatError
            ctx.lifecycle.completeFailure(err)
            return
        }
        
        guard let response = task.response as? HTTPURLResponse else {
            let err = ChatError.unknown(
                code: ChatError.unknownCode,
                message: "Response is not HTTPURLResponse",
                underlying: error
            )
            ctx.lifecycle.completeFailure(err)
            return
        }
        
        guard (200...299).contains(response.statusCode) else {
            let serverMessage = ctx.serverErrorMessage
            let error = ChatError.from(
                statusCode: response.statusCode,
                message: serverMessage
            )
            
            ctx.lifecycle.completeFailure(error)
            return
        }
        ctx.lifecycle.completeSuccess()
    }
    
    
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) {
        guard let taskEntry = taskMapQueue.sync(execute: {
            taskMap[dataTask.taskIdentifier] })
        else { return }
        
        switch taskEntry {
            case let .upload(ctx):
                ctx.responseData.append(data)
            case let .download(ctx):
                if ctx.isErrorResponse {
                    guard ctx.responseData.count + data.count <= maxErrorBodySize else {
                        logger.error("Error body exceeds \(maxErrorBodySize) bytes, cancelling task")
                        
                        self.taskMapQueue.sync {
                            let _ = self.taskMap.removeValue(forKey: dataTask.taskIdentifier)
                        }
                        dataTask.cancel()
                        taskEntry.lifecycle.completeFailure(
                            ChatError.unknown(
                                code: ChatError.unknownCode,
                                message: "Error response too large",
                                underlying: nil
                            )
                        )
                        return
                    }
                    
                    ctx.responseData.append(data)
                } else {
                    logger.debug("download data received \(data.count) bytes")
                    ctx.onChunk(data)
                }
        }
    }
    
    
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        guard let http = response as? HTTPURLResponse else {
            completionHandler(.allow)
            return
        }
        
        let isSuccess = (200...299).contains(http.statusCode)
        logger.debug("didReceive response: isSuccess: \(isSuccess)")
        taskMapQueue.sync {
            if case .download(let ctx)? = taskMap[dataTask.taskIdentifier] {
                ctx.isErrorResponse = !isSuccess
            }
        }
        
        completionHandler(.allow)
    }
    
    
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        needNewBodyStream completionHandler: @escaping (InputStream?) -> Void
    ) {
        let stream: InputStream?
        
        if case let .upload(ctx)? = taskMapQueue.sync(execute: {
            taskMap[task.taskIdentifier]
        }) {
            if let baseStream = ctx.nextStream() {
                stream = OffsetInputStream(
                    underlying: baseStream,
                    offset: ctx.uploadedSize
                )
            } else {
                logger.warning("needNewBodyStream: stream already provided for task \(task.taskIdentifier)")
                stream = nil
            }
        } else {
            logger.warning("needNewBodyStream: upload context not found for task \(task.taskIdentifier)")
            stream = nil
        }
        
        completionHandler(stream)
        
        if stream == nil {
            task.cancel()
        }
    }
    
    
    func download(
        _ request: DownloadRequest,
        _ observer: DownloadObserver,
    ) -> Cancellable {
        var task: URLSessionDataTask? = nil
        do {
            let urlRequest = try makeDownloadRequest(request.fileId, offset: request.offset)
            logger.debug("download urlRequest: \(urlRequest.debugDescription)")
            
            let dataTask = session.dataTask(with: urlRequest)
            task = dataTask
            taskMapQueue.sync {
                taskMap[dataTask.taskIdentifier] = .download(
                    DownloadContext(observer)
                )
            }
            
            dataTask.resume()
        } catch let error as ChatError {
            observer.onError(error)
            
        } catch {
            if let err = sslDelegate.lastSSLError {
                logger.error("catch ssl pinning error: \(err)")
                observer.onError(err)
                
            }else {
                logger.error("catch error: \(error)")
                observer.onError(
                    ChatError.unknown(
                        code: ChatError.unknownCode,
                        message: error.localizedDescription,
                        underlying: error
                    )
                )
            }
        }
        
        return TransferCancellable { [weak self] in
            guard let self = self, let task = task else { return }
            
            let entry = self.taskMapQueue.sync {
                self.taskMap.removeValue(forKey: task.taskIdentifier)
            }
            
            guard case let .download(ctx)? = entry else {
                self.logger.warning("download process already finished/cancelled")
                return
            }
            
            logger.debug("client cancel download")
            ctx.cancel()
            task.cancel()
        }
    }
    
    
    func upload(
        request: UploadRequest,
        observer: UploadObserver
    ) -> Cancellable {
        var task: URLSessionUploadTask? = nil
        let job = Task {
            let uploadId: String
            let uploadedSize: Int64
            do {
                if let resumeId = request.resumeId, !resumeId.isEmpty {
                    uploadedSize = try await resumeUpload(resumeId)
                    uploadId = resumeId
                    observer.onCreated(uploadId: resumeId)
                    
                } else {
                    uploadedSize = 0
                    uploadId = try await newUpload(request)
                    observer.onCreated(uploadId: uploadId)
                }
                
            } catch {
                let err = sslDelegate.lastSSLError ?? error.asChatError
                observer.onError(err)
                return
            }
            
            let urlRequest = try makeUploadRequest(uploadId)
            
            logger.debug("upload urlRequest: \(urlRequest.debugDescription)")
            let uploadTask = session.uploadTask(withStreamedRequest: urlRequest)
            task = uploadTask
            let ctx = UploadContext(request: request, observer: observer, uploadedSize: uploadedSize)
            
            taskMapQueue.sync {
                taskMap[uploadTask.taskIdentifier] = .upload(ctx)
            }
            
            uploadTask.resume()
        }
        
        return TransferCancellable { [weak self] in
            guard let self = self, let task = task else { return }
            
            let entry = self.taskMapQueue.sync {
                self.taskMap.removeValue(forKey: task.taskIdentifier)
            }
            
            guard case let .upload(ctx)? = entry else {
                self.logger.warning("upload process already finished/cancelled")
                return
            }
            
            logger.debug("client cancel upload")
            ctx.cancel()
            task.cancel()
            job.cancel()
        }
    }
    
    
    private func makeUploadRequest(_ uploadId: String) throws -> URLRequest {
        let url = makeUploadURL()
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "uploadId", value: uploadId)
        ]
        
        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = "PUT"
        headerProvider.commonHeaders().forEach {
            urlRequest.setValue($1, forHTTPHeaderField: $0)
        }
        
        return urlRequest
    }
    
    
    private func newUpload(_ request: UploadRequest) async throws -> String {
        let urlRequest = try makeNewUploadRequest(
            fileName: request.fileName
        )
        logger.debug("newUpload urlRequest: \(urlRequest.debugDescription)")
        
        let (data, response) = try await session.data(for: urlRequest)
        logger.debug("newUpload response: \(String(decoding: data, as: UTF8.self))")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.invalidResponse
        }
        
        let validData =
            try httpResponse.validate(data: data, logger: logger)
        
        guard
            let json = try? JSONSerialization.jsonObject(with: validData) as? [String: Any],
            let uploadId = json["uploadId"] as? String
        else {
            throw ChatError.from(
                statusCode: ChatError.unknownCode,
                message: "Invalid response. No uploadId"
            )
        }
        
        return uploadId
    }
    
    
    private func makeNewUploadRequest(fileName: String) throws -> URLRequest {
        let url = makeUploadURL()
        let parameters = ["name": fileName] as [String: String]
        let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = jsonData
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        headerProvider.commonHeaders().forEach {
            urlRequest.setValue($1, forHTTPHeaderField: $0)
        }
        
        return urlRequest
    }
    
    
    private func resumeUpload(_ pid: String) async throws -> Int64 {
        let urlRequest = try makeResumeUploadURLRequest(uploadId: pid)
        logger.debug("resumeUpload urlRequest: \(urlRequest.debugDescription)")
        
        let (data, response) = try await session.data(for: urlRequest)
        logger.debug("resumeUpload response: \(String(decoding: data, as: UTF8.self))")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.invalidResponse
        }
        
        let validData =
            try httpResponse.validate(data: data, logger: logger)
        
        let result = try jsonDecoder.decode(
            ResumeUploadResponseDto.self,
            from: validData
        )
        return result.size
    }
    
    
    private func makeResumeUploadURLRequest(uploadId: String) throws -> URLRequest {
        let url = makeUploadURL()
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "uploadId", value: uploadId)
        ]
        
        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        headerProvider.commonHeaders().forEach {
            urlRequest.setValue($1, forHTTPHeaderField: $0)
        }
        
        return urlRequest
    }
    
    
    private func makeDownloadRequest(_ fileId: String, offset: Int64) throws -> URLRequest {
        guard let url = makeDownloadURL(fileId) else {
            throw ChatError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        
        if offset > 0 {
            urlRequest.setValue("bytes=\(offset)-", forHTTPHeaderField: "Range")
            logger.debug("Range: bytes=\(offset)-")
        }
        
        headerProvider.commonHeaders().forEach {
            urlRequest.setValue($1, forHTTPHeaderField: $0)
        }
        
        return urlRequest
    }
    
    
    private func makeUploadURL() -> URL {
        context.baseURL
            .appendingPathComponent(mediaPath)
    }
    
    
    private func makeDownloadURL(
        _ fileId: String
    ) -> URL? {
        
        let components = URLComponents(
            url: context.baseURL
                .appendingPathComponent(mediaPath)
                .appendingPathComponent(fileId)
                .appendingPathComponent("stream"),
            resolvingAgainstBaseURL: false
        )
        
        return components?.url
    }
}



final class OffsetInputStream: InputStream {
    private let underlying: InputStream
    private var offset: Int64
    private var _streamStatus: Stream.Status = .notOpen
    private let maxChunkSize = 4 * 1024
    
    init(underlying: InputStream, offset: Int64) {
        self.underlying = underlying
        self.offset = offset
        super.init(url: URL(fileURLWithPath: "/dev/null"))!
    }
    
    override var streamStatus: Stream.Status {
        return underlying.streamStatus
    }
    
    override var streamError: Error? {
        return underlying.streamError
    }
    
    override func open() {
        underlying.open()
        skipOffsetIfNeeded()
    }
    
    override func close() {
        underlying.close()
    }
    
    override var hasBytesAvailable: Bool {
        return underlying.hasBytesAvailable
    }
    
    override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        skipOffsetIfNeeded()
        let allowed = min(len, maxChunkSize)
        return underlying.read(buffer, maxLength: allowed)
    }
    
    override var delegate: StreamDelegate? {
        get { underlying.delegate }
        set { underlying.delegate = newValue }
    }
    
    override func schedule(in aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {
        underlying.schedule(in: aRunLoop, forMode: mode)
    }
    
    override func remove(from aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {
        underlying.remove(from: aRunLoop, forMode: mode)
    }
    
    private func skipOffsetIfNeeded() {
        guard offset > 0 else { return }
        
        if underlying.setProperty(NSNumber(value: offset), forKey: .fileCurrentOffsetKey) {
            offset = 0
            return
        }
        
        let bufferSize = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        
        while offset > 0 {
            let toRead = min(Int(offset), bufferSize)
            let bytesRead = underlying.read(buffer, maxLength: toRead)
            
            if bytesRead < 0 { break }
            if bytesRead == 0 { break }
            
            offset -= Int64(bytesRead)
        }
    }
    
    override func property(forKey key: Stream.PropertyKey) -> Any? {
        return underlying.property(forKey: key)
    }
    
    override func setProperty(_ property: Any?, forKey key: Stream.PropertyKey) -> Bool {
        return underlying.setProperty(property, forKey: key)
    }
}


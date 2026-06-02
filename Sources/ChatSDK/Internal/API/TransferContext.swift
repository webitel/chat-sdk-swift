//
//  TransferContext.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 25.05.2026.
//

import Foundation


enum TransferContext {
    case upload(UploadContext)
    case download(DownloadContext)
    
    var lifecycle: TransferLifecycle {
        switch self {
            case .upload(let ctx): return ctx
            case .download(let ctx): return ctx
        }
    }
}


extension TransferContext {
    var serverErrorMessage: String? {
        switch self {
            case .upload(let upload):
                return extractErrorMessage(from: upload.responseData)
            case .download(let download):
                return extractErrorMessage(from: download.responseData)
        }
    }
    
    private func extractErrorMessage(from data: Data) -> String? {
        guard !data.isEmpty else { return nil }
        if
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        {
            if let msg = json["message"] as? String { return msg }
            if let err = json["error"] as? String { return err }
            if let desc = json["description"] as? String { return desc }
            return json.description
        }
        
        if let text = String(data: data, encoding: .utf8), !text.isEmpty {
            return text
        }
        
        return nil
    }
}


final class UploadContext: TransferLifecycle {
    
    private let logger = SDKLogger.make("chat.api.UploadContext")
    private var streamProvided = false
    var responseData = Data()
    let request: UploadRequest
    let observer: UploadObserver
    let uploadedSize: Int64
    
    init(request: UploadRequest, observer: UploadObserver, uploadedSize: Int64) {
        self.request = request
        self.uploadedSize = uploadedSize
        self.observer = observer
    }
    
    
    func nextStream() -> InputStream? {
        guard !streamProvided else {
            logger.warning("Upload stream already provided")
            return nil
        }
        streamProvided = true
        return request.source.openStream()
    }
    
    
    func completeSuccess() {
        do {
            let result = try parseUploadResult()
            observer.onCompleted(result)
            
        } catch let error as ChatError {
            observer.onError(error)
        } catch {
            observer.onError(error.asChatError)
        }
    }
    
    
    func completeFailure(_ error: ChatError) {
        observer.onError(error)
    }
    
    
    func cancel() {
        observer.onError(.cancelled)
    }
    
    
    private func parseUploadResult() throws -> UploadResult {
        let jsonObject = try JSONSerialization.jsonObject(with: responseData)
        
        guard let json = jsonObject as? [String: Any] else {
            throw ChatError.unknown(
                code: ChatError.unknownCode,
                message: "Upload response is not JSON object",
                underlying: nil
            )
        }
        
        logger.debug("Upload response: \(json)")
        
        guard
            let hash = json["hash"] as? String,
            let fileId = json["fileId"] as? String,
            let name = json["name"] as? String
        else {
            throw ChatError.unknown(
                code: ChatError.unknownCode,
                message: "Missing fields in upload response",
                underlying: nil
            )
        }
        
        let mimeType = json["mimeType"] as? String ?? ""
        
        let size: Int64
        if let s = json["size"] as? Int64 {
            size = s
        } else if let s = json["size"] as? Int {
            size = Int64(s)
        } else {
            throw ChatError.unknown(
                code: ChatError.unknownCode,
                message: "Invalid file size",
                underlying: nil
            )
        }
        
        let file = UploadedFile(
            id: fileId,
            name: name,
            mimeType: mimeType,
            size: size
        )
        
        return UploadResult(
            file: file, hashes: ["sha256": hash]
        )
    }
}


final class DownloadContext: TransferLifecycle {
    private let observer: DownloadObserver
    var isErrorResponse = false
    var responseData = Data()
    var totalBytes: Int64 = 0
    
    init(_ observer: DownloadObserver) {
        self.observer = observer
    }
    
    func completeSuccess() {
        observer.onCompleted(
            DownloadResult(bytesDownloaded: totalBytes)
        )
    }
    
    func onChunk(_ chunk: Data) {
        totalBytes += Int64(chunk.count)
        observer.onChunk(chunk)
    }
    
    func completeFailure(_ error: ChatError) {
        observer.onError(error)
    }
    
    func cancel() {
        observer.onError(.cancelled)
    }
}


protocol TransferLifecycle {
    func completeSuccess()
    func completeFailure(_ error: ChatError)
    func cancel()
}


extension FileSource {
    
    func openStream() -> InputStream {
        switch self {
            case .stream(let stream):
                return stream
                
            case .data(let data):
                return InputStream(data: data)
        }
    }
}


struct EmptyCancellable: Cancellable {
    func cancel() {}
}


struct TransferCancellable: Cancellable {
    private let _cancel: () -> Void
    
    public init(_ cancel: @escaping () -> Void) {
        self._cancel = cancel
    }
    
    func cancel() {
        _cancel()
    }
}

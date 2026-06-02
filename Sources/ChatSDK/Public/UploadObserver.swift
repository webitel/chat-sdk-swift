//
//  UploadObserver.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 21.05.2026.
//

import Foundation


/// Receives upload lifecycle events.
public protocol UploadObserver: AnyObject {

    /// Called when a new upload session is created.
    ///
    /// The upload identifier can later be used
    /// to resume interrupted uploads.
    ///
    /// - Parameter uploadId: Unique upload session identifier.
    func onCreated(uploadId: String)

    /// Called when upload progress changes.
    ///
    /// - Parameters:
    ///   - uploaded: Number of bytes uploaded so far.
    ///   - total: Total file size in bytes, if known.
    func onProgress(
        uploaded: Int64,
        total: Int64?
    )

    /// Called when the upload completes successfully.
    ///
    /// - Parameter result: Upload result metadata.
    func onCompleted(_ result: UploadResult)
    
    /// Called when the upload fails or is canceled.
    ///
    /// If the transfer was canceled explicitly,
    /// the error will be `.canceled`.
    ///
    /// - Parameter error: Upload error.
    func onError(_ error: ChatError)
}

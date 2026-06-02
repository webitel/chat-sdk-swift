//
//  DownloadObserver.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 21.05.2026.
//

import Foundation


/// Receives download events for a file transfer operation.
///
/// Chunk data is delivered incrementally as it is downloaded.
public protocol DownloadObserver: AnyObject {

    /// Called when a new chunk of file data is received.
    ///
    /// The chunk contains only valid downloaded bytes and can be processed,
    /// stored, or forwarded immediately.
    ///
    /// - Parameter chunk: Downloaded file data chunk.
    func onChunk(_ chunk: Data)

    /// Called when the download completes successfully.
    ///
    /// - Parameter result: Final download statistics.
    func onCompleted(_ result: DownloadResult)

    /// Called when the download fails or is canceled.
    ///
    /// If the transfer was canceled explicitly,
    /// the error will be `.canceled`.
    ///
    /// - Parameter error: Download error.
    func onError(_ error: ChatError)
}

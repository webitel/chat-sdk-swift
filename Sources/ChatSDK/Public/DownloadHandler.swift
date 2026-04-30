//
//  DownloadListener.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 23.03.2026.
//

import Foundation


/// Callbacks used to observe file download progress.
public struct DownloadHandler {

    /// Called when a chunk of data is received.
    public let onChunk: (Data) -> Void

    /// Called when the download completes successfully.
    public let onComplete: () -> Void

    /// Called when the download is cancelled.
    public let onCanceled: () -> Void

    /// Called when an error occurs during download.
    public let onError: (ChatError) -> Void


    public init(
        onChunk: @escaping (Data) -> Void = { _ in },
        onComplete: @escaping () -> Void = {},
        onCanceled: @escaping () -> Void = {},
        onError: @escaping (ChatError) -> Void = { _ in }
    ) {
        self.onChunk = onChunk
        self.onComplete = onComplete
        self.onCanceled = onCanceled
        self.onError = onError
    }
}

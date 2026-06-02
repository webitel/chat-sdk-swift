//
//  DownloadRequest.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 21.05.2026.
//

import Foundation


/// Parameters used to start a file download.
public struct DownloadRequest {

    /// Remote file identifier.
    public let fileId: String

    /// Byte offset to start downloading from.
    ///
    /// Can be used to resume interrupted downloads.
    public let offset: Int64

    public init(
        fileId: String,
        offset: Int64 = 0
    ) {
        self.fileId = fileId
        self.offset = offset
    }
}

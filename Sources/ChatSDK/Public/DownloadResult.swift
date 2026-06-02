//
//  DownloadResult.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 21.05.2026.
//

import Foundation


/// Represents the result of a completed download operation.
public struct DownloadResult {
    
    /// Total number of bytes downloaded.
    public let bytesDownloaded: Int64
    
    public init(bytesDownloaded: Int64) {
        self.bytesDownloaded = bytesDownloaded
    }
}

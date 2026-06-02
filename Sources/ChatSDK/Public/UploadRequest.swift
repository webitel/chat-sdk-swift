//
//  UploadRequest.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 21.05.2026.
//

import Foundation


/// Parameters required to upload a file.
public struct UploadRequest {

    /// File content source.
    public let source: FileSource

    /// Original file name.
    public let fileName: String

    /// Total file size in bytes, if known.
    ///
    /// Providing the size allows more accurate
    /// progress reporting and resumable uploads.
    public let totalSize: Int64?

    /// Existing upload identifier used to resume
    /// a previously interrupted upload session.
    public let resumeId: String?

    public init(
        source: FileSource,
        fileName: String,
        totalSize: Int64? = nil,
        resumeId: String? = nil
    ) {
        self.source = source
        self.fileName = fileName
        self.totalSize = totalSize
        self.resumeId = resumeId
    }
}


/// Represents supported upload content sources.
public enum FileSource {
    
    /// File content provided as an `InputStream`.
    ///
    /// Useful for streaming large files
    /// without loading them fully into memory.
    case stream(InputStream)
    
    /// File content stored fully in memory.
    case data(Data)
}

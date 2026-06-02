//
//  UploadedFile.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 21.05.2026.
//

import Foundation


/// Metadata describing an uploaded file.
public struct UploadedFile {

    /// Unique remote file identifier.
    public let id: String

    /// Original file name.
    public let name: String

    /// MIME type reported by the backend.
    public let mimeType: String

    /// File size in bytes.
    public let size: Int64

    public init(
        id: String,
        name: String,
        mimeType: String,
        size: Int64
    ) {
        self.id = id
        self.name = name
        self.mimeType = mimeType
        self.size = size
    }
}

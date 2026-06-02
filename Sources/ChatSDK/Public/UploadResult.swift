//
//  UploadResult.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 21.05.2026.
//

import Foundation

/// Represents the result of a completed upload operation.
public struct UploadResult {

    /// Metadata of the uploaded file.
    public let file: UploadedFile

    /// Hash values calculated for the uploaded content.
    ///
    /// The key represents the hash algorithm name
    /// and the value contains the corresponding hash.
    ///
    /// Example:
    /// `sha256 -> abc123`
    public let hashes: [String: String]

    public init(
        file: UploadedFile,
        hashes: [String: String]
    ) {
        self.file = file
        self.hashes = hashes
    }
}

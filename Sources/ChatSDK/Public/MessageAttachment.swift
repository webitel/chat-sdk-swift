//
//  MessageAttachment.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 23.03.2026.
//

import Foundation


/// Metadata describing a message attachment.
public struct MessageAttachment:Hashable, Sendable, Codable {

    /// Remote file identifier.
    public let fileId: String

    /// Original file name.
    public let fileName: String

    /// MIME type.
    public let mimeType: String

    /// File size in bytes.
    public let size: Int64

    /// Direct download URL if provided.
    public let url: URL?

    public init(
        fileId: String,
        fileName: String,
        mimeType: String,
        size: Int64,
        url: URL? = nil
    ) {
        self.fileId = fileId
        self.fileName = fileName
        self.mimeType = mimeType
        self.size = size
        self.url = url
    }
}


public extension MessageAttachment {
    enum AttachmentType: Sendable {
        case image
        case video
        case audio
        case file
    }

    /// Attachment type derived from MIME type.
    var type: AttachmentType {
        switch mimeType {
        case let value where value.hasPrefix("image/"):
            return .image

        case let value where value.hasPrefix("video/"):
            return .video

        case let value where value.hasPrefix("audio/"):
            return .audio
                
        default:
            return .file
        }
    }

    var isImage: Bool {
        type == .image
    }

    var isVideo: Bool {
        type == .video
    }

    var isAudio: Bool {
        type == .audio
    }
}

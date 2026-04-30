//
//  MessageAttachment.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 23.03.2026.
//

import Foundation



public enum MessageAttachment: Hashable, Codable {
    case image(Image)
    case file(File)
}


public struct AttachmentBase: Hashable, Codable {

    /// Remote file identifier used for downloading
    public let fileId: String

    /// Original file name as provided by the sender
    public let fileName: String

    /// MIME type reported by backend
    public let mimeType: String

    /// File size in bytes
    public let size: Int64

    public init(
        fileId: String,
        fileName: String,
        mimeType: String,
        size: Int64
    ) {
        self.fileId = fileId
        self.fileName = fileName
        self.mimeType = mimeType
        self.size = size
    }
}


public struct Image: Hashable, Codable {

    public let base: AttachmentBase

    /// Optional preview (thumbnail)
    public let previewId: String?

    /// Width in pixels
    public let width: Int?

    /// Height in pixels
    public let height: Int?

    public init(
        base: AttachmentBase,
        previewId: String?,
        width: Int?,
        height: Int?
    ) {
        self.base = base
        self.previewId = previewId
        self.width = width
        self.height = height
    }
}


public struct File: Hashable, Codable {

    public let base: AttachmentBase
    public init(base: AttachmentBase) {
        self.base = base
    }
}

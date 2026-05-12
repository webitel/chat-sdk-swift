//
//  MetadataValue.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 11.05.2026.
//

import Foundation


public enum MetadataValue: Hashable, Codable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: MetadataValue])
    case array([MetadataValue])
    case null
}

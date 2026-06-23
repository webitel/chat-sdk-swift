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


public extension MetadataValue {
    var stringValue: String? {
        guard case let .string(value) = self else { return nil }
        return value
    }

    var numberValue: Double? {
        guard case let .number(value) = self else { return nil }
        return value
    }

    var boolValue: Bool? {
        guard case let .bool(value) = self else { return nil }
        return value
    }

    var objectValue: [String: MetadataValue]? {
        guard case let .object(value) = self else { return nil }
        return value
    }

    var arrayValue: [MetadataValue]? {
        guard case let .array(value) = self else { return nil }
        return value
    }
}

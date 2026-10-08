//
//  FlexibleDecoding.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 08.10.2026.
//

import Foundation


/// Decodes an Int64 sent either as a JSON number or a numeric string.
internal func decodeFlexibleInt64<Key: CodingKey>(
    _ container: KeyedDecodingContainer<Key>,
    key: Key
) -> Int64? {

    if let intValue = try? container.decodeIfPresent(Int64.self, forKey: key) {
        return intValue
    }

    if let stringValue = try? container.decodeIfPresent(String.self, forKey: key) {
        return Int64(stringValue)
    }

    return nil
}


/// Decodes an unread count sent either as a JSON number or a numeric string,
/// clamping negative values to zero. Returns `nil` when absent or malformed.
internal func decodeUnreadCount<Key: CodingKey>(
    _ container: KeyedDecodingContainer<Key>,
    key: Key
) -> Int? {

    decodeFlexibleInt64(container, key: key).map { Int(max(0, $0)) }
}

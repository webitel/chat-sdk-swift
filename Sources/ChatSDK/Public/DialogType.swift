//
//  DialogType.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 23.03.2026.
//

import Foundation


/// Type of dialog.
public enum DialogType: String, Codable, CaseIterable {

    /// One-to-one dialog between two participants.
    case direct

    /// Dialog with multiple participants.
    case group
    
    /// Channel-style dialog (broadcast or topic based communication).
    case channel
    
    /// Unknown or unsupported dialog type.
    case unknown

    /// Creates DialogType from raw API value.
    public static func from(_ value: String) -> DialogType {
        Self.allCases.first {
            $0.rawValue.caseInsensitiveCompare(value) == .orderedSame
        } ?? .unknown
    }
}

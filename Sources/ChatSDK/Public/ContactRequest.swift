//
//  ContactRequest.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 23.03.2026.
//

import Foundation


/// Request parameters used to load a page of contacts.
public struct ContactRequest: Hashable, Codable {

    /// Page number to load (starts from 1).
    public let page: Int

    /// Number of contacts per page.
    public let size: Int

    public init(
        page: Int = 1,
        size: Int = 50
    ) {
        self.page = page
        self.size = max(1, size)
    }
}

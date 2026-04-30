//
//  DialogRequest.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 20.03.2026.
//

import Foundation


/// Request parameters used to load a page of dialogs.
public struct DialogRequest: Hashable, Codable {

    /// Page number to load (starts from 1).
    public let page: Int

    /// Number of dialogs per page.
    public let size: Int
    
    /// Optional filter applied to dialogs.
    public let filter: DialogFilter?

    public init(
        page: Int = 1,
        size: Int = 50,
        filter: DialogFilter? = nil
    ) {
        self.page = page
        self.size = max(1, size)
        self.filter = filter
    }
}

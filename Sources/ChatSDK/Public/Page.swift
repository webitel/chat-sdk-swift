//
//  Page.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 23.03.2026.
//

import Foundation


public struct Page<T> {

    /// Current page number.
    public let page: Int

    /// Items contained in the page.
    public let items: [T]

    /// Indicates whether another page can be loaded.
    public let hasNext: Bool

    public init(
        page: Int,
        items: [T],
        hasNext: Bool
    ) {
        self.page = page
        self.items = items
        self.hasNext = hasNext
    }
}


public extension Page {

    var isEmpty: Bool {
        items.isEmpty
    }
}


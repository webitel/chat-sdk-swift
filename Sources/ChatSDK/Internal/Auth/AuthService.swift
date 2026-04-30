//
//  AuthService.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 25.03.2026.
//

import Foundation


internal protocol AuthService {

    var currentContact: ContactDto? { get }

    func refresh() async throws

    func endSession() async throws
}


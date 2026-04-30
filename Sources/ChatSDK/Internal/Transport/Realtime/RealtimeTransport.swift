//
//  RealtimeTransport.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 08.04.2026.
//

import Foundation


internal protocol RealtimeTransport {

    func connect()
    func disconnect()
    func setObserver(
        _ observer: RealtimeObserver
    )
    var connectionState: ConnectionState { get }
}

//
//  RealtimeHub.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 26.03.2026.
//

import Foundation


internal final class RealtimeHub {

    private var globalObservers = NSHashTable<AnyObject>.weakObjects()
    private var dialogObservers: [String: NSHashTable<AnyObject>] = [:]
    private var connectionObservers = NSHashTable<AnyObject>.weakObjects()
    private var publishedState: ConnectionState = .disconnected
    private let logger = SDKLogger.make("chat.core.hub")
    
    private let queue = DispatchQueue(
        label: "chat.core.hub",
        attributes: .concurrent
    )
    
    
    func addGlobalObserver(
        _ observer: ChatEventObserver
    ) {
        queue.async(flags: .barrier) {
            self.globalObservers.add(observer)
        }
    }
    
    
    func addDialogObserver(
        dialogId: String,
        observer: ChatEventObserver
    ) {

        queue.async(flags: .barrier) {
            let table =
                self.dialogObservers[dialogId]
                ?? NSHashTable.weakObjects()

            table.add(observer)
            self.dialogObservers[dialogId] = table
        }
    }
    
    
    func removeGlobalObserver(
        _ observer: ChatEventObserver
    ) {
        queue.async(flags: .barrier) {
            self.globalObservers.remove(observer)
        }
    }
    
    
    func removeDialogObserver(
        dialogId: String,
        observer: ChatEventObserver
    ) {
        queue.async(flags: .barrier) {
            guard let table = self.dialogObservers[dialogId]
            else { return }

            table.remove(observer)
            if table.allObjects.isEmpty {
                self.dialogObservers.removeValue(
                    forKey: dialogId
                )
            }
        }
    }
    
    
    func dispatch(
        _ event: ChatEvent
    ) {
        let observers: (global: [ChatEventObserver], dialog: [ChatEventObserver]) = queue.sync {
            let global = self.globalObservers.allObjects
                .compactMap { $0 as? ChatEventObserver }

            let dialog = self.dialogObservers[event.dialogId]?.allObjects
                .compactMap { $0 as? ChatEventObserver } ?? []

            return (global: global, dialog: dialog)
        }

        notify(
            observers.global,
            scope: "global",
            event: event
        )

        notify(
            observers.dialog,
            scope: "dialog:\(event.dialogId)",
            event: event
        )
    }
    
    
    func addConnectionObserver(
        _ observer: ConnectionObserver
    ) {
        queue.async(flags: .barrier) {
            self.connectionObservers.add(observer)
            observer.onStateChanged(
                self.publishedState
            )
        }
    }
    
    
    func removeConnectionObserver(
        _ observer: ConnectionObserver
    ) {
        queue.async(flags: .barrier) {
            self.connectionObservers.remove(observer)
        }
    }
    
    
    func updateState(
        _ newState: ConnectionState
    ) {
        queue.async(flags: .barrier) {
            guard
                self.publishedState != newState
            else { return }

            self.logger.debug("new connection state: \(newState)")
            
            self.publishedState = newState

            let observers = self.connectionObservers.allObjects
                .compactMap { $0 as? ConnectionObserver }

            observers.forEach { observer in
                self.safeNotify(
                    scope: "connection",
                    event: newState
                ) {
                    observer.onStateChanged(newState)
                }
            }
        }
    }
    
    
    private func notify(
        _ observers: [ChatEventObserver],
        scope: String,
        event: ChatEvent
    ) {
        observers.forEach { observer in
            self.safeNotify(
                scope: scope,
                event: event
            ) {
                observer.onEvent(event)
            }
        }
    }
    
    
    private func safeNotify<T>(
        scope: String,
        event: T,
        block: () throws -> Void
    ) {
        do {
            try block()

        } catch {
            logger.error(
                """
                Client listener crashed
                Scope: \(scope)
                Event: \(event)
                """
            )
        }
    }
}


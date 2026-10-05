//
//  UpdatesSynchronizer.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 28.09.2026.
//

import Foundation


internal protocol UpdatesSynchronizerDelegate: AnyObject {

    func fetchUpdates(cursor: String) async throws -> UpdatesResponseDto

    /// Applies one page of recovered changes. Called on the synchronizer queue.
    func applyUpdates(_ threads: [ThreadUpdatesDto])

    /// Incremental sync is impossible, all client state must be reloaded.
    func resyncRequired()
}


/// Owns the updates cursor and recovers changes missed
/// while the realtime connection was unavailable.
///
/// Realtime events are routed through `submit(cursor:work:)`: while a sync
/// is running they are buffered and replayed afterwards, skipping those
/// already covered by the recovered changes.
internal final class UpdatesSynchronizer {

    private struct PendingEvent {
        let cursor: String?
        let work: () -> Void
    }

    weak var delegate: UpdatesSynchronizerDelegate?

    private let maxAttempts: Int
    private let retryDelay: (Int) -> TimeInterval
    private let logger = SDKLogger.make("chat.core.sync")
    private let queue = DispatchQueue(label: "chat.core.sync")

    private var cursor: String?
    /// False between `reset()` and `activate()`: late frames of an ended
    /// session must not seed the cursor of the next one.
    private var isActive = true
    private var isSyncing = false
    private var pending: [PendingEvent] = []
    private var syncTask: Task<Void, Never>?
    private var generation = 0

    init(
        maxAttempts: Int,
        retryDelay: @escaping (Int) -> TimeInterval
    ) {
        self.maxAttempts = max(1, maxAttempts)
        self.retryDelay = retryDelay
    }


    var currentCursor: String? {
        queue.sync { cursor }
    }


    /// Server confirmed the connection (`connected_event`).
    ///
    /// Without a known cursor this is the first connection in the session:
    /// the server cursor becomes the baseline. Otherwise it is a reconnection
    /// and changes missed since the known cursor are recovered, unless the
    /// server cursor is not newer than the known one (nothing was missed).
    func onConnected(serverCursor: String?) {
        queue.async {
            guard self.isActive else { return }

            if let from = self.cursor {
                if let server = serverCursor, !Self.isNewer(server, than: from) {
                    self.logger.debug("cursor \(from) is up to date, sync skipped")
                    return
                }

                self.startSync(from: from)
            } else {
                self.cursor = serverCursor
            }
        }
    }


    /// Processes a realtime event and advances the cursor, or buffers it
    /// while a sync is running.
    ///
    /// Buffering is required because the updates response is a snapshot
    /// taken before it reaches the client: applying live events first would
    /// let that older snapshot overwrite newer state (e.g. revive a message
    /// deleted in the meantime). Keeping the cursor frozen until the sync
    /// succeeds also prevents skipping over an unrecovered gap.
    func submit(
        cursor eventCursor: String?,
        work: @escaping () -> Void
    ) {
        queue.async {
            if self.isSyncing {
                self.pending.append(PendingEvent(cursor: eventCursor, work: work))
                return
            }

            work()

            if self.isActive {
                self.advance(to: eventCursor)
            }
        }
    }


    /// Resumes cursor tracking after `reset()` (e.g. on `connect()`).
    func activate() {
        queue.async {
            self.isActive = true
        }
    }


    /// Forgets the cursor and all pending state (e.g. on session end).
    /// Cursor tracking stays suspended until `activate()`.
    func reset() {
        queue.async {
            self.isActive = false
            self.generation += 1
            self.syncTask?.cancel()
            self.syncTask = nil
            self.cursor = nil
            self.isSyncing = false
            self.pending.removeAll()
        }
    }


    // MARK: - Sync

    private func startSync(from: String) {
        generation += 1
        let current = generation

        syncTask?.cancel()
        isSyncing = true

        logger.debug("sync started from cursor \(from)")

        syncTask = Task { [weak self] in
            await self?.runSync(from: from, generation: current)
        }
    }


    private func runSync(from: String, generation: Int) async {
        var from = from
        var attempt = 0

        while !Task.isCancelled {
            guard let delegate else {
                // Nobody to apply changes to: release buffered events
                // instead of keeping the sync running forever
                await onQueue {
                    guard self.generation == generation else { return }
                    self.pending.removeAll()
                    self.finishSync()
                }
                return
            }

            do {
                let response = try await delegate.fetchUpdates(cursor: from)
                attempt = 0

                let next = await onQueue { [from] () -> String? in
                    guard self.generation == generation else { return nil }
                    return self.applyPage(response, from: from)
                }

                guard let next else { return }
                from = next

            } catch {
                if Task.isCancelled { return }

                attempt += 1
                logger.warning("sync attempt \(attempt) failed: \(error)")

                if attempt >= maxAttempts {
                    await onQueue {
                        guard self.generation == generation else { return }
                        self.giveUp()
                    }
                    return
                }

                let delay = retryDelay(attempt)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }


    /// Applies a page on the queue. Returns the cursor for the next page,
    /// or nil when the sync is finished.
    private func applyPage(_ response: UpdatesResponseDto, from: String) -> String? {
        if response.resync {
            logger.debug("server requested full resync")

            cursor = response.cursor
            pending.removeAll()
            finishSync()
            delegate?.resyncRequired()
            return nil
        }

        delegate?.applyUpdates(response.threads)
        cursor = response.cursor

        if response.hasMore {
            if Self.isNewer(response.cursor, than: from) {
                return response.cursor
            }

            // Requesting the same cursor again would loop forever
            logger.warning("has_more with non-advancing cursor \(response.cursor), sync stopped")
        }

        flushPending()
        finishSync()
        return nil
    }


    /// Replays buffered events not covered by the recovered changes.
    private func flushPending() {
        let events = pending
        pending.removeAll()

        for event in events {
            if let eventCursor = event.cursor,
               let current = cursor,
               !Self.isNewer(eventCursor, than: current) {
                continue
            }

            event.work()
            advance(to: event.cursor)
        }
    }


    /// Sync kept failing: the gap cannot be recovered incrementally.
    private func giveUp() {
        logger.error("sync failed, full resync required")

        let events = pending
        pending.removeAll()
        finishSync()

        events.forEach {
            $0.work()
            advance(to: $0.cursor)
        }

        delegate?.resyncRequired()
    }


    private func finishSync() {
        isSyncing = false
        syncTask = nil
        logger.debug("sync finished at cursor \(cursor ?? "-")")
    }


    private func advance(to eventCursor: String?) {
        guard let eventCursor else { return }

        if let current = cursor, !Self.isNewer(eventCursor, than: current) {
            return
        }

        cursor = eventCursor
    }


    private func onQueue<T>(_ block: @escaping () -> T) async -> T {
        await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: block())
            }
        }
    }


    /// Cursors are monotonic numeric strings. Non-numeric cursors
    /// cannot be ordered and are treated as newer when they differ.
    static func isNewer(_ candidate: String, than current: String) -> Bool {
        if let lhs = Int64(candidate), let rhs = Int64(current) {
            return lhs > rhs
        }

        return candidate != current
    }
}

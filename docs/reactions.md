# Reactions

Users can react to messages with a single emoji.

Only one reaction per user is allowed per message — sending a new emoji replaces the previous one.


## Model

```swift
public struct MessageReaction: Hashable, Codable {
    public let emoji: String
    public let count: Int
    public let reactedByMe: Bool
    public let reactorIds: [String]
    public let lastReactedAt: Date?
}
```

- `emoji` — the reacted-with emoji  
- `count` — number of users who reacted with this emoji  
- `reactedByMe` — whether the current user is among the reactors  
- `reactorIds` — identifiers of users who reacted with this emoji  
- `lastReactedAt` — time of the most recent reaction with this emoji, if known  

`Message.reactions` holds the current set of `MessageReaction` for a message.


## Setting a Reaction

Reactions can be set via a dialog instance or via the client (with an explicit `messageId`).

```swift
/// Sets or updates the current user's reaction on a message using a completion handler.
///
/// Only one reaction per user is allowed per message; sending a new emoji
/// replaces the previous one. Use `removeReaction` to clear it.
///
/// - Parameters:
///   - messageId: Identifier of the message being reacted to.
///   - emoji: Emoji to set as the reaction.
///   - sendId: Optional client-generated request identifier.
///   - completion: Completion handler returning the resulting reaction state or error.
func setReaction(
    messageId: String,
    emoji: String,
    sendId: String?,
    completion: @escaping (Result<ReactionResult, ChatError>) -> Void
)

/// Sets or updates the current user's reaction on a message using async/await.
func setReaction(
    messageId: String,
    emoji: String,
    sendId: String?
) async throws -> ReactionResult
```

`sendId` is optional and defaults to `nil` — use it to correlate the request with realtime confirmation, similar to `sendId` for messages.

```swift
// Set reaction (completion-based)
dialog.setReaction(messageId: message.id, emoji: "👍") { result in
    switch result {

        case .success(let reactionResult):
            print("Reaction updated: \(reactionResult.action)")

        case .failure(let error):
            print("Failed to set reaction: \(error)")
    }
}

// Or using async/await
do {

    let result = try await dialog.setReaction(messageId: message.id, emoji: "👍")
    print("Reaction updated: \(result.action)")

} catch {

    print("Failed to set reaction: \(error)")
}
```


## Removing a Reaction

`removeReaction` clears the current user's reaction from a message.

```swift
/// Removes the current user's reaction from a message, if any, using a completion handler.
func removeReaction(
    messageId: String,
    completion: @escaping (Result<ReactionResult, ChatError>) -> Void
)

/// Removes the current user's reaction from a message, if any, using async/await.
func removeReaction(
    messageId: String
) async throws -> ReactionResult
```

There is no separate removal endpoint — `removeReaction` is implemented as `setReaction(messageId:emoji: "", sendId: nil)` under the hood.


## Result

```swift
/// Result of a reaction request, describing what happened to the reaction.
public enum ReactionAction: String, Hashable, Codable {

    /// The reaction was set (added or replaced a previous one).
    case set = "REACTION_ACTION_SET"

    /// The reaction was removed.
    case removed = "REACTION_ACTION_REMOVED"

    /// The request had no effect (the same reaction was already present).
    case unchanged = "REACTION_ACTION_UNCHANGED"
}
```

```swift
/// Outcome of setting or removing a reaction on a message.
public struct ReactionResult: Hashable, Codable {

    /// What happened to the reaction as a result of the request.
    public let action: ReactionAction

    /// Emoji associated with the reaction, if provided by the server.
    public let emoji: String?

    /// Time the reaction was changed, if provided by the server.
    public let reactedAt: Date?
}
```


## Receiving Reaction Updates

Reaction changes (from any user) are delivered via realtime events as `MessageEvent.reactionsChanged`:

```swift
case reactionsChanged(
    dialogId: String,
    messageId: String,
    reactions: [MessageReaction]
)
```

```swift
func onEvent(_ event: ChatEvent) {
    switch event {
        case .message(.reactionsChanged(let dialogId, let messageId, let reactions)):
            print("Reactions on \(messageId): \(reactions)")

        default:
            break
    }
}
```

See [Events](events.md) for how to register an observer.

The dialog's cached `lastMessage.reactions` is updated automatically when this event is received for that message.

# Messages

## Sending Messages

Messages can be sent in two ways:
- via a dialog instance: `dialog.sendMessage(...)`  
- via the client: `chatClient.sendMessage(...)` (with an explicit target)  

After a successful send, the server returns the `messageId` of the created message.

If realtime is active, the same message will also be delivered via events.


## Tracking Outgoing Messages (`sendId`)

To correctly update UI state (for example: `pending → delivered`), you can provide a `sendId` — a client-generated unique identifier.

This `sendId` will also be included in the message received via realtime events, allowing the client to match the local message with the server-confirmed one.


## Example

```swift
// Define message target
let target: MessageTarget = .dialog(id: "dialogId")
// or:
// let target: MessageTarget = .contact(
//     contactId: ContactID(sub: contactSUB, iss: contactISS)
// )

// Create message options
let sendId = UUID().uuidString

let options = MessageOptions(
    content: .text("Hello!"),
    sendId: sendId
)

// Send message (completion-based)
chatClient.sendMessage(to: target, options: options) { result in
    switch result {

        case .success(let messageId):
            print("Message sent: \(messageId)")

        case .failure(let error):
            print("Failed to send message: \(error)")
    }
}

// Or using async/await
do {

    let messageId = try await chatClient.sendMessage(
        to: target,
        options: options
    )

    print("Message sent: \(messageId)")

} catch {

    print("Failed to send message: \(error)")
}
```


## Message Content

The SDK uses two different content models depending on the direction of the message:

- `SendContent` — used when sending messages  
- `MessageContent` — used for messages received from the server  



## Sending Content (`SendContent`)

`SendContent` defines what the client is allowed to send.

Supported content types:

- text
- attachments
- composite (text + attachments)
- contact
- location

Example:

```swift
let content = SendContent.composite(
    text: "See attached file",
    attachments: [file]
)
```

Usage:

```swift
let options = MessageOptions(
    content: content,
    sendId: UUID().uuidString
)
```


## Received Content (`MessageContent`)

`MessageContent` represents the final message as delivered by the server.

It may include additional data not present in the original request.

Supported content types:

- text
- attachments
- composite
- contact
- location
- keyboardOnly
- system

Example:

```swift
switch message.content {

    case .text(let text):
        print(text)

    case .composite(let content):
        print(content.text)

    default:
        break
}
```


## Message Model

```swift
public struct Message: Hashable, Codable {

    /// Unique message identifier
    public let id: String

    /// Dialog identifier
    public let dialogId: String

    /// Message creation date
    public let createdAt: Date

    /// Last edit date, nil if the message was never edited
    public let editedAt: Date?

    /// Sender of the message
    public let from: Participant

    /// Final message content delivered by the server
    public let content: MessageContent

    /// Client-generated request ID
    public let sendId: String?

    /// Indicates whether message is outgoing
    public let isOutgoing: Bool
}
```


## Message History

Message history is retrieved via a dialog instance:

```swift
let request = HistoryRequest()

// Get history slice (completion-based)
dialog.getHistory(request: request) { result in

    switch result {

        case .success(let historySlice):
            break

        case .failure(let error):
            break
    }
}

// Or using async/await
let slice = try await dialog.getHistory(request: request)
```


## Request Parameters

`HistoryRequest` supports:

- `limit` — number of messages to load  
- `cursor` — pagination position (`HistoryCursor`)  

```swift
/// Cursor pointing to a specific message in history.
public struct HistoryCursor: Hashable, Codable {

    /// Identifier of the reference message.
    public let messageId: String

    /// Direction in which history should be loaded.
    public let direction: MoveDirection
}
```


### Result

```swift
/// Represents a portion of message history with cursors for pagination.
public struct HistorySlice: Hashable, Codable {

    /// Messages returned in this slice of history.
    public let items: [Message]

    /// Cursor used to load messages newer than this slice.
    public let newerCursor: HistoryCursor?

    /// Cursor used to load messages older than this slice.
    public let olderCursor: HistoryCursor?
}
```

- `olderCursor` — used to load older messages  
- `newerCursor` — used to load newer messages  


## Working with Cursors

Cursors can also be created manually.

This is useful, for example, after reconnect:

- take the last known message ID  
- set direction to `.newer`  

This allows checking whether new messages appeared while the connection was unavailable.


## Deleting Messages

Messages are deleted in batch via a dialog instance or via the client:
- via a dialog instance: `dialog.deleteMessages(ids:)`
- via the client: `chatClient.deleteMessages(ids:)`

```swift
/// Deletes messages by identifier using a completion handler.
func deleteMessages(
    ids: [String],
    completion: @escaping (Result<DeleteMessagesResult, ChatError>) -> Void
)

/// Deletes messages by identifier using async/await.
func deleteMessages(
    ids: [String]
) async throws -> DeleteMessagesResult
```

```swift
// Delete messages (completion-based)
dialog.deleteMessages(ids: [messageId]) { result in
    switch result {

        case .success(let deleteResult):
            print("Deleted: \(deleteResult.deletedIds)")
            print("Skipped: \(deleteResult.skipped.map { "\($0.id) (\($0.reason))" })")

        case .failure(let error):
            print("Failed to delete messages: \(error)")
    }
}

// Or using async/await
do {

    let result = try await dialog.deleteMessages(ids: [messageId])
    print("Deleted: \(result.deletedIds)")
    print("Skipped: \(result.skipped.map { "\($0.id) (\($0.reason))" })")

} catch {

    print("Failed to delete messages: \(error)")
}
```

### Result

```swift
/// Outcome of a message deletion request.
public struct DeleteMessagesResult: Hashable, Codable {

    /// Time the deletion was performed. `nil` if no messages were deleted.
    public let deletedAt: Date?

    /// Identifiers of the messages that were deleted.
    public let deletedIds: [String]

    /// Messages that were not deleted, with the reason for each (e.g. not found or not permitted).
    public let skipped: [SkippedMessage]
}

/// A message that was not deleted, along with the reason.
public struct SkippedMessage: Hashable, Codable {

    /// Identifier of the message that was not deleted.
    public let id: String

    /// Reason the message was skipped.
    public let reason: SkippedMessageReason
}

/// Reason a message was not deleted.
public enum SkippedMessageReason: String, Hashable, Codable, CaseIterable {
    case unspecified = "REASON_UNSPECIFIED"
    case notFound = "REASON_NOT_FOUND"
    case notAuthor = "REASON_NOT_AUTHOR"
    case alreadyDeleted = "REASON_ALREADY_DELETED"
    case chatClosed = "REASON_CHAT_CLOSED"
    case notAllowed = "REASON_NOT_ALLOWED"

    /// Unknown or unsupported reason — returned for values not recognized by this version of the SDK.
    case unknown
}
```

`skipped` lists messages the server did not delete along with the reason — for example messages that no longer exist or that the current user is not allowed to delete. `reason` falls back to `.unknown` for values the SDK does not yet recognize, so switching over it should always handle `.unknown` (or be non-exhaustive).

`ids` are not restricted to the dialog `deleteMessages` was called on — the underlying endpoint has no notion of a dialog, so any accessible message id can be passed regardless of which `Dialog` instance you call this on, or whether you call it via `chatClient` instead. This mirrors `setReaction`/`removeReaction`, which are available on both `Dialog` and `ChatClient` the same way. Scoping and authorization are enforced server-side; unauthorized or non-existent ids are reported back via `skipped`.

A realtime `ChatEvent.message(.deleted(dialogId:deletion:))` is dispatched when a message is deleted — including deletions made by another participant — and the dialog's cached `lastMessage` is cleared automatically if it was the deleted message. See [Events](events.md) for details.


## Editing a Message

A message's text can be edited via a dialog instance or via the client:
- via a dialog instance: `dialog.editMessage(messageId:text:)`
- via the client: `chatClient.editMessage(messageId:text:)`

```swift
/// Edits the text of a message using a completion handler.
func editMessage(
    messageId: String,
    text: String,
    completion: @escaping (Result<EditMessageResult, ChatError>) -> Void
)

/// Edits the text of a message using async/await.
func editMessage(
    messageId: String,
    text: String
) async throws -> EditMessageResult
```

```swift
// Edit message (completion-based)
dialog.editMessage(messageId: message.id, text: "Updated text") { result in
    switch result {

        case .success(let editResult):
            print("Message edited at \(editResult.editedAt)")

        case .failure(let error):
            print("Failed to edit message: \(error)")
    }
}

// Or using async/await
do {

    let result = try await dialog.editMessage(messageId: message.id, text: "Updated text")
    print("Message edited at \(result.editedAt)")

} catch {

    print("Failed to edit message: \(error)")
}
```

### Result

```swift
/// Outcome of editing a message.
public struct EditMessageResult: Hashable, Codable {

    /// Identifier of the edited message.
    public let id: String

    /// Time the edit was applied.
    public let editedAt: Date
}
```

`messageId` is not restricted to the dialog `editMessage` was called on — the underlying endpoint has no notion of a dialog, so any accessible message id can be passed regardless of which `Dialog` instance you call this on, or whether you call it via `chatClient` instead. This mirrors `setReaction`/`deleteMessages`, which are available on both `Dialog` and `ChatClient` the same way.

Only the message's author is allowed to edit it — the server enforces this and rejects the request otherwise, the same way it does for deletion.

A `ChatEvent.message(.edited(dialogId:, message:))` event is dispatched to every participant of the dialog once the edit is applied, and the dialog's cached `lastMessage` is updated automatically (in place, preserving its existing reactions) if the edited message was the last one. See [Events](events.md) for details.

# Messages

## Sending Messages

Messages can be sent in two ways:
- via a dialog instance: dialog.sendMessage(...)  
- via the client: chatClient.sendMessage(...) (with an explicit target)  

After a successful send, the server returns the messageId of the created message.

If realtime is active, the same message will also be delivered via events.


## Tracking outgoing messages (sendId)
To correctly update UI state (e.g. “pending → delivered”), you can provide a sendId — a client-generated unique identifier.

This sendId will be included in the message received via realtime events, allowing you to match the local message with the server-confirmed one.


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
let options = try MessageOptions(text: "Hello!", sendId: sendId)

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
    let messageId = try await chatClient.sendMessage(to: target, options: options)
    print("Message sent: \(messageId)")
} catch {
    print("Failed to send message: \(error)")
}
```


## Message model

```swift
public struct Message: Hashable, Codable {

    /// Unique message identifier
    public let id: String

    /// Dialog identifier
    public let dialogId: String

    /// Message creation date
    public let createdAt: Date

    /// Last edit date
    public let editedAt: Date

    /// Sender of the message
    public let from: Participant

    /// Text content of the message
    ///
    /// May be nil when message contains only attachments
    public let text: String?

    /// Client-generated request ID
    public let sendId: String?

    /// Indicates whether message is outgoing
    public let isOutgoing: Bool

    /// Attachments metadata
    public let attachments: [MessageAttachment]
}
```


## Message History

Message history is retrieved via a dialog instance:
```swift
let request = HistoryRequest()

// get history slice (completion-based)
dialog.getHistory(request: request) { result in
    switch result {
        case .success(let historySlice):
        case .failure(let error):
    }
}

// Or using async/await
try await dialog.getHistory(request: request)
```


### Request parameters
HistoryRequest supports:
- limit — number of messages to load  
- cursor — pagination position (HistoryCursor)  

```swift
/// Cursor pointing to a specific message in history.
struct HistoryCursor: Hashable, Codable {

    /// Identifier of the reference message.
    public let messageId: String

    /// Direction in which history should be loaded.
    public let direction: MoveDirection
}
```


### Result

```swift
/// Represents a portion of message history with cursors for pagination.
struct HistorySlice: Hashable, Codable {

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


### Working with cursors

Cursors can also be created manually. This is useful, for example, after reconnect:
- take the last known message and use id   
- set direction to MoveDirection.NEWER  

This allows checking whether new messages after the connection was restored.

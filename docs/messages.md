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

    /// Last edit date
    public let editedAt: Date

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

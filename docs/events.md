# Events

Realtime Event Handling

To receive messages and other realtime updates, the SDK uses an event observer that subscribes to WebSocket events.

Observer can be registered:  
- globally — to receive events from all dialogs  
- per dialog — to receive events only for a specific dialog  

Global observer:
```swift
chatClient.addEventObserver(self)
```

Dialog-specific observer:
```swift
dialog.addObserver(self)
```
Receives only events related to the specific dialog.


## Protocol

```swift
/// Observer used to receive chat-related events from the SDK.
protocol ChatEventObserver: AnyObject {

    /// Called when a new ChatEvent is emitted.
    func onEvent(_ event: ChatEvent)
}
```


## Event model
All events are represented by the ChatEvent:
```swift
/// Chat-related events emitted by the SDK.
enum ChatEvent {

    case message(MessageEvent)
    case dialog(DialogEvent)
    case activity(ActivityEvent)
    case receipt(ReceiptEvent)

    /// Dialog identifier associated with the event.
    public var dialogId: String 
}
```


## Event types

### Message events

```swift
enum MessageEvent {
    case received(
        dialogId: String,
        message: Message
    )

    case edited(
        dialogId: String,
        message: Message
    )

    case deleted(
        dialogId: String,
        deletion: MessageDeletion
    )

    case reactionsChanged(
        dialogId: String,
        messageId: String,
        reactions: [MessageReaction]
    )
}
```

`.edited` is dispatched whenever a message is edited — since only the message's author may edit it, `message.from` and `message.isOutgoing` reflect the editor. The dialog's cached `lastMessage` is updated automatically (in place, preserving its existing reactions and reply) if the edited message was the last one.

`.deleted` is dispatched whenever a message is deleted — including deletions made by another participant — carrying who deleted it and when:
```swift
struct MessageDeletion {
    let messageId: String
    let deletedBy: Participant
    let deletedAt: Date
}
```
The dialog's cached `lastMessage` is cleared automatically if the deleted message was the last one.

See [Reactions](reactions.md) for details on `.reactionsChanged`.

### Dialog events

```swift
enum DialogEvent {

    case created(
        dialogId: String,
        dialog: any Dialog
    )
}
```

### Activity events

```swift
enum ActivityEvent {

    case typing(
        dialogId: String,
        member: Participant,
        previewText: String?,
        timeoutMs: Int?
    )
}
```

See [Typing Indicators](typing.md) for details on `.typing`.

### Receipt events

```swift
enum ReceiptEvent {

    case delivered(
        dialogId: String,
        member: Participant,
        sequence: Int64
    )

    case read(
        dialogId: String,
        member: Participant,
        sequence: Int64
    )

    case deliveryFailed(
        dialogId: String,
        messageId: String,
        member: Participant,
        error: String
    )
}
```

Reserved for future use — not yet emitted by the server.


## Handling events

```swift
func onEvent(_ event: ChatEvent) {
    switch event {
        case .message(let messageEvent):
            handleMessageEvent(messageEvent)
        case .dialog(let dialogEvent):
            handleDialogEvent(dialogEvent)
        case .activity(_):
            return
        case .receipt(_):
            return
    }
}
```

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

The SDK updates the cached `Dialog` state (`lastMessage`, `unreadCount`, `participantStates`) **before** dispatching any event for that dialog. There are no separate "dialog changed" events — on any event, re-read the dialog's properties to refresh its UI.


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

`.received` also updates `Dialog.unreadCount`: the server's `unread_count` is used when the event carries it; otherwise an incoming message newer than the current user's read horizon increments the count. Outgoing messages, including ones sent from another device, are not counted. Any drift is corrected by the next read receipt for the current user (even a duplicate one) or by a [synchronization](#synchronization).

```swift
case .message(.received(let dialogId, _)):
    guard let dialog = dialogs[dialogId] else { return }
    reloadRow(dialog) // lastMessage and unreadCount are already up to date
```

See [Reactions](reactions.md) for details on `.reactionsChanged`.

### Dialog events

```swift
enum DialogEvent {

    case created(
        dialogId: String,
        dialog: any Dialog
    )

    case synchronized(
        dialogId: String,
        changes: DialogSyncChanges
    )
}
```

`.synchronized` is dispatched after a reconnect for every dialog that changed while the realtime connection was unavailable. See [Synchronization](#synchronization).

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
        upToSequence: Int64
    )

    case read(
        dialogId: String,
        member: Participant,
        upToSequence: Int64,
        unreadCount: Int?
    )

    case deliveryFailed(
        dialogId: String,
        exception: DeliveryException
    )
}
```

Receipts are cumulative horizons: `.read(upToSequence: 108)` means every message with `Message.sequence <= 108` is read by `member`.

The SDK first advances `Dialog.participantStates`, then dispatches the event — only when the horizon actually moved forward. Duplicate or stale receipts are dropped, so a horizon never goes back. `read` and `delivered` are tracked independently.

`.read` carries `unreadCount` — the current user's unread count after the receipt. It is set only when `member` is the current user (e.g. after `markAsRead` or reading on another device); for receipts from other participants it is `nil`. The SDK updates `Dialog.unreadCount` before dispatching the event, so both always match. A duplicate read receipt for the current user is not dispatched, but its `unreadCount` is still applied to `Dialog.unreadCount`.

```swift
struct ParticipantState {
    let member: Participant
    let deliveredUpToSequence: Int64
    let readUpToSequence: Int64
}
```

The same `participantStates` are loaded with the dialog and refreshed after a reconnect (see [Synchronization](#synchronization)), so the dialog always holds the current state regardless of the source:

```swift
case .receipt(.read(let dialogId, let member, let upToSequence, let unreadCount)):
    markRead(dialogId: dialogId, memberId: member.id, upTo: upToSequence)

    if let unreadCount {
        setUnreadBadge(dialogId: dialogId, count: unreadCount)
    }
```

`.deliveryFailed` is reserved for future use — not yet emitted by the server.


## Synchronization

When the realtime connection drops (network loss, backgrounding, backoff), the SDK remembers the position of the last processed event. On every **re**connect it fetches the changes missed since that position and dispatches them as `DialogEvent.synchronized` — one event per changed dialog. If the server reports on reconnect that nothing changed since that position, no request is made and no events are dispatched. Realtime events received while the sync is in progress are held back and delivered afterwards, without duplicates.

```swift
struct DialogSyncChanges {
    let unreadCount: Int
    /// Changed messages, sorted by `sequence`. Upsert by `id`.
    let messages: [Message]
    /// Messages to remove from local state.
    let deletedMessageIds: [String]
    /// Current delivery/read horizons; compare with `Message.sequence`.
    /// Same merged values as `Dialog.participantStates`.
    let participantStates: [ParticipantState]
    let deliveryExceptions: [DeliveryException]
    let memberChanges: [MemberChange]
    /// The current user has left the dialog.
    let hasLeft: Bool
}
```

The dialog's cached `lastMessage`, `unreadCount` and `participantStates` are updated automatically. Recovered horizons are merged with the ones received in realtime and never move back.

Dialogs created while offline are announced first, so they are handled by the same code as realtime `.created`:

```
.dialog(.created(dialogId:, dialog:))
.dialog(.synchronized(dialogId:, changes:))
```

If a `.synchronized` still refers to a dialog unknown to the client, fetch it by `dialogId`:

```swift
case .dialog(.synchronized(let dialogId, let changes)):
    if dialogs[dialogId] == nil {
        let page = try await chatClient.getDialogs(
            request: DialogRequest(filter: DialogFilter(ids: [dialogId]))
        )
        page.items.first.map { dialogs[dialogId] = $0 }
    }
    apply(changes, to: dialogId)
```

### Full resync

If too many changes were missed, or fetching them fails twice (one retry), the SDK notifies client observers instead. This is not a `ChatEvent`, because it is not bound to a dialog:

```swift
protocol ChatClientObserver: AnyObject {
    /// Default implementation is empty.
    func onResyncRequired()
}
```

```swift
final class ChatStore: ChatClientObserver {
    init(chatClient: ChatClient) {
        chatClient.addClientObserver(self)
    }

    func onResyncRequired() {
        reloadAll() // dialog list and any opened message histories
    }
}
```

Observers are held weakly; remove them with `removeClientObserver(_:)`.

### Cold start

The position is kept in memory only and starts with the first realtime connection. Call `connect()` **before** the initial `getDialogs` / `getHistory`, or reload them after the first `.connected` state — otherwise changes made between the initial load and the connection are not recovered. The position is reset by `endSession()`.


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

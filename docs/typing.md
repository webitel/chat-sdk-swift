# Typing Indicators

Notifies other dialog participants that the user is currently composing a message.


## Model

```swift
/// Parameters used when sending a typing indicator.
public struct TypingRequest: Hashable, Codable {

    /// Preview of the text currently being composed.
    public let previewText: String?

    /// How long the typing indicator should remain active, in milliseconds.
    public let timeoutMs: Int?

    public init(
        previewText: String? = nil,
        timeoutMs: Int? = nil
    )
}
```

Both fields are optional — `TypingRequest()` sends a plain typing indicator with no preview and no explicit timeout.


## Sending a Typing Indicator

Typing indicators are sent via a dialog instance.

```swift
/// Sends a typing indicator to the dialog.
///
/// Typically used to notify other participants that
/// the user is currently composing a message.
///
/// - Parameter request: Optional typing parameters (preview text, timeout).
func sendTyping(
    request: TypingRequest,
    completion: @escaping (Result<Void, ChatError>) -> Void
)

/// Sends a typing indicator using async/await.
func sendTyping(
    request: TypingRequest
) async throws
```

```swift
let request = TypingRequest(previewText: "Hey, are yo", timeoutMs: 5000)

// Send typing indicator (completion-based)
dialog.sendTyping(request: request) { result in
    switch result {

        case .success:
            break

        case .failure(let error):
            print("Failed to send typing indicator: \(error)")
    }
}

// Or using async/await
try await dialog.sendTyping(request: request)
```


## Receiving Typing Events

Typing state from other participants is delivered via realtime events as `ActivityEvent.typing`:

```swift
case typing(
    dialogId: String,
    member: Participant,
    previewText: String?,
    timeoutMs: Int?
)
```

- `member` — the participant who is typing  
- `previewText` — preview of the text they're composing, if provided  
- `timeoutMs` — how long the indicator should remain active; use it to decide when to clear the indicator from the UI if no follow-up event arrives  

```swift
func onEvent(_ event: ChatEvent) {
    switch event {
        case .activity(.typing(let dialogId, let member, let previewText, let timeoutMs)):
            print("\(member.contact.id) is typing in \(dialogId)")

        default:
            break
    }
}
```

See [Events](events.md) for how to register an observer.

# ChatSDK

Swift SDK for realtime chat messaging with WebSocket transport, session management, push notifications, and flexible authentication.

Designed for easy integration into iOS applications.

Documentation is available in the [/docs](./docs) directory.

---

## Installation

Swift Package Manager

```swift
.package(url: "https://github.com/webitel/chat-sdk-swift.git", from: "0.1.1")
```

---

## Creating a ChatClient

Create a ChatClient instance using ChatClientFactory:

```swift
let chatClient = ChatClientFactory.create(
    baseURL: "https://demo.webitel.com",
    authMethod: .token {
        return "jwt"
    }
) {
    $0.clientToken = "client-token"
    $0.logLevel = .debug
}
```

---

## Authentication

The SDK supports multiple authentication strategies:

- Token-based authentication
- ContactIdentity-based authentication

For token-based authentication, the token is provided via a closure.
The SDK will request a token when needed.

---

## Realtime Connection

Enable realtime updates:

```swift
chatClient.connect()
```

Disable realtime:

```swift
chatClient.disconnect()
```

Connection state can be observed via ConnectionObserver.

---

## Listening for Events

Register an event observer:

```swift
chatClient.addEventObserver(self)
```

Events are delivered only when realtime connection is active.

---

## Loading Dialogs

Retrieve dialogs for the current session:

```swift
let request = DialogRequest(page: 1, size: 50)

chatClient.getDialogs(request) { result in
    switch result {
    case .success(let page):
        let dialogs = page.items
    case .failure(let error):
        print(error)
    }
}
```

---

## Sending Messages

```swift
let target: MessageTarget = .dialog(id: "dialogId")
let options = MessageOptions(
    content: .text("Hello!"),
    sendId: sendId
)

chatClient.sendMessage(to: target, options: options) { result in
    switch result {
    case .success(let messageId):
        print("Sent: \\(messageId)")

    case .failure(let error):
        print(error)
    }
}

// Or using async/await
try await chatClient.sendMessage(to: target, options: options)
```

Sending does not require an active realtime connection.

---

## Receiving Messages

Incoming messages are delivered via realtime events when connection is active.

---

## Loading Message History

```swift
dialog.getHistory(request: HistoryRequest()) { result in
    switch result {
    case .success(let slice):
        let messages = slice.items

    case .failure(let error):
        print(error)
    }
}

// Or using async/await
try await dialog.getHistory(request: HistoryRequest())
```

---

## Session Management

End the current session:

```swift
try await chatClient.endSession()
```

This:
- terminates the server session  
- stops push notifications  
- closes realtime connection  

---

## Error Handling

All errors are returned as ChatError.

```swift
switch result {
case .failure(let error):
    if case .unauthorized = error {
        // handle auth
    }
```

---

## Security

### SSL Public Key Pinning

```swift
config.pinnedPublicKeys = [
    "sha256/AAAA...",
    "sha256/BBBB..."
]
```

At least one pin must match the server certificate chain.

---

## Requirements

- iOS 13+

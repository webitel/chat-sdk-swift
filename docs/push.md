# Push Notifications

To receive push notifications, register a device.

## Registration

```swift
// Send message (completion-based)
chatClient.registerDevice(pushToken: "token", pushTokenType: .apns) { result in
    switch result {
        case .success():
        case .failure(let error):
    }
}

// Or using async/await
try await chatClient.registerDevice(pushToken: "token", pushTokenType: .apns)
```

Re-register on token refresh.

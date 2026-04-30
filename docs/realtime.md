# Realtime

Realtime functionality is implemented using WebSocket.


## Connect

```swift
chatClient.connect()
```
After calling:
- WebSocket connection is established  
- realtime events are enabled  
- automatic reconnection is handled  


## Configuration
```swift
/// Configuration for realtime (WebSocket) connection behavior.
struct RealtimeConfig {

    /// Maximum number of reconnect attempts before giving up.
    public let maxRetries: Int

    /// Interval between ping frames to keep the connection alive.
    public let pingInterval: TimeInterval

    /// Base delay used for calculating reconnect backoff.
    public let retryBaseDelay: TimeInterval

    /// Maximum delay between reconnect attempts.
    public let maxRetryDelay: TimeInterval
}
```


### Reconnect behavior

- automatic reconnect attempts are performed  
- backoff strategy is used  
- after exceeding maxRetries, state becomes Failed  

In Failed state, automatic reconnects stop.

To restart:
```swift
chatClient.connect()
```
Retry counter resets after this call.  


## Connection state observer
```swift
chatClient.addConnectionObserver(self)
```

States:
- Connecting
- Connected
- Disconnected
- Reconnecting
- Failed  


## Disconnect

```swift
chatClient.disconnect()
```

# SDK Initialization

The entry point to the SDK is the `ChatClientFactory`.

```swift
let client = ChatClientFactory.create(
    baseURL: baseURL,
    authMethod: .contact(identity: user)
) {
    $0.clientToken = clientToken
    $0.logLevel = .debug
}
client.addEventObserver(self)
client.addConnectionObserver(self)

```


## Required parameters

- `endpoint` — server connection URL (e.g. `https://demo.webitel.com`)  
- `clientToken` — client identifier generated on the server  
- `auth` — authentication method  

Authentication is performed automatically. No explicit login method is required.


## Optional parameters

- `logLevel` — logging level  
- `logHandler` — log handler  
- `deviceId` — unique device identifier  
- `networkConfig` — network configuration  
- `pinnedPublicKeys` — collection of Base64-encoded SHA-256 public key hashes  

    
## Network configuration

Allows configuring HTTP and WebSocket separately.

```swift
struct NetworkConfig {

    /// HTTP API configuration.
    public let api: ApiConfig

    /// Realtime WebSocket configuration.
    public let realtime: RealtimeConfig
}

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

/// Configuration for HTTP API requests.
struct ApiConfig {

    /// Maximum time allowed for an API call before it times out.
    public let callTimeout: TimeInterval
}
```

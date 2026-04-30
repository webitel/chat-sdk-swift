# Authentication

Authentication is configured via `auth()` during initialization.

The SDK performs authentication automatically using provided data.


## Supported methods

- Token-based (JWT, Opaque, etc.)  
- ContactIdentity  

```swift
/// Authentication method used by the chat client.
public enum AuthMethod {

    /// Authentication using an access token.
    /// The token is provided via closure to allow dynamic refresh.
    case token(
        tokenProvider: () -> String
    )

    /// Authentication using a contact identity.
    case contact(
        identity: ContactIdentity
    )
}
```


## ContactIdentity

```swift
/// Represents contact identity information used for session creation.
///
/// This model is provided by the SDK client and sent to backend
/// to create or restore a chat session.
///
/// The structure is compatible with common OpenID Connect identity claims.
public struct ContactIdentity: Encodable {

    /// Unique subject identifier (stable contact ID).
    ///
    /// This is the primary identity field.
    /// Example: external CRM ID, UUID, or internal user ID.
    public let sub: String

    /// Issuer identifier
    public let iss: String

    /// Full display name
    public let name: String

    /// First name
    public let givenName: String?

    /// Middle name
    public let middleName: String?

    /// Last name
    public let familyName: String?

    /// Email address
    public let email: String?

    /// Whether email was verified
    public let emailVerified: Bool?

    /// Phone number in E.164 format
    public let phoneNumber: String?

    /// Whether phone number was verified
    public let phoneNumberVerified: Bool?

    /// Birthdate (ISO 8601: YYYY-MM-DD)
    public let birthdate: String?

    /// Gender (free text, e.g. "male", "female", "other")
    public let gender: String?

    /// Locale (e.g. "en-US", "uk-UA")
    public let locale: String?

    /// Timezone (e.g. "Europe/Kyiv")
    public let zoneinfo: String?

    /// Additional custom metadata associated with this identity.
    public let metadata: [String: String?]?
}
```


## Error handling

- On 401 → re-authentication  
- Request is retried automatically  

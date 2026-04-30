# Contacts

Contacts are core entities used in dialogs and messages.

A contact is created automatically on first authentication.

## Model

```swift
public struct Contact: Hashable, Codable {

    /// Unique identifier of the contact.
    public let id: ContactID

    /// Display name of the contact.
    public let name: String

    /// Source of the contact (e.g. telegram, facebook, webitel, custom).
    /// Corresponds to the `iss` field configured on the server.
    public let source: String

    /// Indicates whether the contact represents a bot.
    public let isBot: Bool
}


/// Unique identity of a contact.
public struct ContactID: Hashable, Codable {

    /// Subject identifier of the contact.
    public let sub: String

    /// Issuer of the contact identity.
    public let iss: String
}
```


## Fetch contacts

```swift
let request = ContactRequest(page: 1, size: 50)

chatClient.getContacts(request) { result in }
```

Returns: `Result<Page<Contact>, ChatError>`


## Pagination

```swift
public struct Page<T> {
    /// Current page number.
    public let page: Int

    /// Items contained in the page.
    public let items: [T]

    /// Indicates whether another page can be loaded.
    public let hasNext: Bool
}
```

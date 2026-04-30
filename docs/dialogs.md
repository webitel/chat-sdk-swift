# Dialogs

Dialogs represent conversations between users.


## Types
- direct — One-to-one private dialog between two users.  
- group — Dialog with multiple participants.  
- channel — Broadcast or topic-based dialog.  


## channel behavior
- Created automatically on first message  
- Only one dialog exists per pair of users  


## MessageTarget

```swift
enum MessageTarget: Equatable {

    /// Target an existing dialog by its unique identifier.
    case dialog(id: String)

    /// Target a contact directly (a dialog may be created automatically).
    case contact(contactId: ContactID)
}
```


## Model

```swift
protocol Dialog: Hashable {

    /// Unique identifier of the dialog.
    var id: String { get }

    /// Display name or subject of the dialog.
    var subject: String { get }

    /// Type of the dialog (direct, group, etc.).
    var type: DialogType { get }

    /// List of dialog participants.
    var members: [Participant] { get }

    /// Last message sent in the dialog, if available.
    var lastMessage: Message? { get }
}
```


## Participants

Each dialog contains a list of participants (`members`).

A participant represents a user **within the context of a specific dialog** and includes:

- underlying contact information (`Contact`)
- role in the dialog (e.g. owner, admin, member)
- a dialog-scoped identifier

Important:

- the same contact may have different roles in different dialogs
- participant data should be used for permissions and UI logic
- do not confuse `Participant` with `Contact` — they serve different purposes

```swift
/// Represents a participant in a dialog or conversation.
///
/// A participant wraps a `Contact` with additional context,
/// such as their role within the dialog
struct Participant: Hashable, Codable {
    
    /// Unique identifier of the participant within the dialog.
    public let id: String
    
    /// Underlying contact information associated with this participant.
    public let contact: Contact
    
    /// Role of the participant in the dialog.
    public let role: ParticipantRole
}
```


## Fetch dialogs

```swift
let request = DialogRequest(
    page: 1,
    size: 50,
    filter: DialogFilter(
        query: "support",
        types: [.direct, .group]
    )
)

chatClient.getDialogs(request) { result in }
```

Returns: `Result<Page<Dialog>, ChatError>`


## Filtering

DialogFilter allows narrowing the result set:  

- query — full-text search query (up to 256 characters).  
Performs a case-insensitive partial match (`ilike`) against:  
    * `subject` for group/channel dialogs  
    * `title` for direct dialogs  
Matches both exact values and substrings anywhere in the text.  

- ids — include only specific dialogs by ID  
- types — filter by dialog types  
    * unknown is ignored  

If multiple filter fields are provided, they are combined (AND).  


## Pagination

```swift
struct Page<T> {
    public let page: Int
    public let items: [T]
    public let hasNext: Bool
}
```

* page — current page number
* items — list of dialogs
* hasNext — indicates if more pages are available

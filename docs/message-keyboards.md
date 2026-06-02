# Interactive Messages

## Overview

Messages may contain interactive keyboards that allow users to perform actions directly from the chat UI.

Keyboards are delivered by the server as part of `MessageContent`.

Supported keyboard styles:

- inline button grid
- list-style menu with sections


## Keyboard Types

```swift
public enum ChatKeyboard
```

### Buttons Keyboard

Grid-style keyboard where buttons are arranged into rows.

```swift
let keyboard = ChatKeyboard.buttons(
    .init(
        rows: [
            ChatKeyboardRow(
                buttons: [
                    ChatKeyboardButton(...),
                    ChatKeyboardButton(...)
                ]
            )
        ]
    )
)
```

### List Menu Keyboard

List-style keyboard with sections.

Typically rendered as a single trigger button that opens a menu.

```swift
let keyboard = ChatKeyboard.listMenu(
    .init(
        title: "Open menu",
        sections: [
            ChatKeyboardSection(
                title: "Main",
                buttons: [
                    ...
                ]
            )
        ]
    )
)
```

## Keyboard Structure

### Row

```swift
public struct ChatKeyboardRow {
    public let buttons: [ChatKeyboardButton]
}
```

### Section

```swift
public struct ChatKeyboardSection {
    public let title: String
    public let buttons: [ChatKeyboardButton]
}
```

### Button

```swift
public struct ChatKeyboardButton {
    public let id: String
    public let label: String
    public let action: ChatButtonAction
    public let metadata: [String: MetadataValue]?
}
```

Fields:

- `id` — unique button identifier
- `label` — text shown to the user
- `action` — action executed on tap
- `metadata` — optional UI-related data

Example metadata:

```swift
[
    "color": .string("primary"),
    "danger": .bool(true)
]
```


## Button Actions

```swift
public enum ChatButtonAction
```

### Open URL

Opens an external link.

```swift
.openURL("https://example.com")
```

The client application is responsible for handling navigation.


### Send Callback

Sends a callback event to the backend.

```swift
.callback("confirm_order")
```

This action is typically used for bots or interactive workflows.


### Request Data

Requests information from the client device.

```swift
.requestData("location")
```

Common request types:

- `location`
- `contact`


## Receiving Interactive Messages

Keyboards may be included in:

- `MessageContent.keyboard`
- `MessageContent.composite`

Example:

```swift
switch message.content {

    case .keyboard(let keyboard):
        renderKeyboard(keyboard)

    case .composite(let content):

        if let keyboard = content.keyboard {
            renderKeyboard(keyboard)
        }

    default:
        break
}
```


## Sending Button Actions

When the user taps a button, the client should send a corresponding `MessageAction`.

```swift
chatClient.sendAction(
    .buttonClick(
        messageId: message.id,
        buttonId: button.id,
        data: "confirm_order"
    )
)
```


## MessageAction

```swift
public enum MessageAction
```

## Button Click

Represents a button tap event.

```swift
.buttonClick(
    messageId: message.id,
    buttonId: button.id,
    data: "confirm_order"
)
```

Fields:

- `messageId` — identifier of the related message
- `buttonId` — identifier of the clicked button
- `data` — callback payload associated with the button

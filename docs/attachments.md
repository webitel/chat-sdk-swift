# Files

## Overview

The SDK supports:

- uploading files to remote storage
- downloading files from storage
- attaching uploaded files to messages

Files are uploaded separately before sending a message.
After a successful upload, the server returns a file identifier that can later be attached to outgoing messages.


## Uploading Files
File uploads are asynchronous and support:

- progress tracking
- cancellation 
- resumable uploads

Example
```swift
let request = UploadRequest(
    source: .stream(inputStream),
    fileName: "image.png",
    totalSize: fileSize
)

let task = chatClient.upload(
    request: request,
    observer: self
)
```

```swift
extension ChatViewModel: UploadObserver {

    func onCreated(uploadId: String) {
        // Save uploadId if resumable uploads are needed
    }

    func onProgress(
        uploaded: Int64,
        total: Int64?
    ) {}

    func onCompleted(_ result: UploadResult) {
        let uploadedFile = result.file
    }
    
    func onError(_ error: ChatError) {}
}
```


### Upload Sources

The SDK supports multiple upload sources.


#### ByteArray
```swift
.data(data)
```


#### InputStream
```swift
.stream(inputStream)
```


### Resuming Uploads

Uploads may be resumed using resumeId.

The upload identifier is provided via:

```swift
UploadObserver.onCreated(uploadId:)
```

Example:
```swift
let request = UploadRequest(
    source: .stream(inputStream),
    fileName: "video.mp4",
    resumeId: savedUploadId
)
```


### Upload Result

After a successful upload, the SDK returns file metadata.

```swift
public struct UploadResult {
    public let file: UploadedFile
    public let hashes: [String: String]
}
```

Example:

```swift
let fileId = result.file.id
```


### Sending Attachments

Uploaded files can be attached to messages using SendAttachment.file.

```swift
let content = SendContent.composite(
    text: "See attached file",
    attachments: [
        .file(uploadedFile.id)
    ]
)
```

Or attachment-only message:

```swift
let content = SendContent.attachments([
    .file(uploadedFile.id)
])
```

External URLs are also supported:

```swift
let content = SendContent.attachments([
    .url(URL(string: "https://example.com/image.jpg"), "image.jpg")
])
```


## Downloading Files

File downloads are asynchronous and support:

- streaming downloads
- resumable downloads
- cancellation

Example:

```swift
let task = chatClient.download(
    request: DownloadRequest(
        fileId: fileId
    ),
    observer: self
)
```
```swift
extension ChatViewModel: DownloadObserver {

    func onChunk(_ chunk: Data) {
        outputStream.write(chunk)
    }
    
    func onCompleted(_ result: DownloadResult) {}
    
    func onError(_ error: ChatError) {}
}
```


### Resuming Downloads

Downloads can resume from a specific byte offset.

Example:

```swift
let request = DownloadRequest(
    fileId: fileId,
    offset: alreadyDownloadedBytes
)
```


## Cancelling Transfers

Both uploads and downloads return a Cancellable.

Example:

```swift
let task = chatClient.download(...)

task.cancel()
```
Cancellation interrupts the active transfer operation.

The listener will receive:

```swift
ChatError.canceled
```

via: 
```swift
onError(_:)
```

# QRCodeReader

A framework for iOS which easily lets you scan QR codes.

This will require you to set the `NSCameraUsageDescription` in your `Info.plist` or the application will crash.

## Example

```swift
reader = QRCodeReader()
do {
	try	reader!.startScanning() {
		decodedQrCode in

		guard let decodedQrCode = decodedQrCode else {
			return
		}

		DispatchQueue.main.async {
			UIPasteboard.general.string = decodedQrCode
		}

		self.reader = nil
	}
} catch {
	print("\(error.localizedDescription)")
	reader = nil
}
```


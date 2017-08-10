# QRCodeReader

[![Documentation](https://blochberger.github.io/QRCodeReader/iphone/public/badge.svg)](https://blochberger.github.io/QRCodeReader)

A framework for iOS which easily lets you scan QR codes.

- Repository: https://github.com/blochberger/QRCodeReader
- Documentation: https://blochberger.github.io/QRCodeReader
  - iOS: [public](https://blochberger.github.io/QRCodeReader/iphone/public), [internal](https://blochberger.github.io/QRCodeReader/iphone/internal), [private](https://blochberger.github.io/QRCodeReader/iphone/private)
- Issues: https://github.com/blochberger/QRCodeReader/issues

**Note**: This will require you to set the `NSCameraUsageDescription` in your `Info.plist` or the application will crash.

## Example

```swift
reader = QRCodeReader()
do {
  try  reader!.startScanning() {
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


import AVFoundation
import UIKit

/**
	This class can be used to conveniently read QR codes from the integrated
	camera of the device. The first QR code detected is returned as a string and
	the user is given indication how to enable permissions is denied or
	restricted.
*/
public class QRCodeReader: NSObject, AVCaptureMetadataOutputObjectsDelegate {

	/**
		This enum indicates possible errors that can occur during capturing a QR
		code.
	*/
	public enum Error: Swift.Error {
		/**
			This error occurs if the NIB/XIB of the application has not loaded
			or the application is otherwise not correctly initialized.
		*/
		case noKeyWindow

		/**
			This error occurs if the user has denied access to the camera or if
			camera access on the device is restricted in general. There is no
			need to ask the user to enable the permissions, as this is taken
			care of in `startScanning`. The purpose is to gracefully handle
			cases where the user does not want to grant the permission.
		*/
		case permissionsNotGranted

		/**
			This error occurs if there is no available camera device.
		*/
		case noCaptureDevice
	}

	/**
		This is a convenience type for the callback that is executed if the scan
		did finish.
	*/
	public typealias FinishedScan = (String?) -> Void

	/**
		This sets the color of the text of the **Cancel** button.

		- note:
			This needs to be set before calling `startScaning`.
	*/
	public var cancelButtonTextColor = UIView().tintColor

	/**
		This sets the background color of the **Cancel** button.

		- note:
			This needs to be set before calling `startScaning`.
	*/
	public var cancelButtonBackgroundColor = UIColor.white

	/**
		This sets the height of the **Cancel** button.

		- note:
			This needs to be set before calling `startScaning`.
	*/
	public var cancelButtonHeight = CGFloat(60)

	/**
		This sets the margin around the **Cancel** button.

		- note:
			This needs to be set before calling `startScaning`.
	*/
	public var cancelButtonMargin = CGFloat(20)

	/**
		This enables vibrating the device or blinking the screen (if vibration
		is not supported) upon successful detection of a QR code.
	*/
	public var feedbackOnSuccess = true

	/**
		The function that is invoked if the scan is finished.
	*/
	private var callback: FinishedScan?

	/**
		The layer that is showing the actual video input from the camera, so
		that the user sees where he is pointing the device.
	*/
	private var videoLayer: AVCaptureVideoPreviewLayer!

	/**
		The current capturing session.
	*/
	private var session: AVCaptureSession!

	/**
		The cancel button.
	*/
	private var cancelButton: UIButton!

	/**
		Upon deinitalization the scan is aborted.
	*/
	deinit {
		stopScanning()
	}

	/**
		Aborts a current scan.
	*/
	public func stopScanning() {
		session.stopRunning()

		cancelButton?.removeFromSuperview()
		cancelButton = nil
		videoLayer?.removeFromSuperlayer()
		videoLayer = nil
	}

	/**
		Starts scanning for a QR code.
	
		This will activate the default camera, which is the camera on the
		backside of the iOS device. The user will be asked to grant permissions
		if this did not happen already. If the user previously had denied
		access to the camera or access is restricted on the device in general
		instructions for enabling the camere will be provided to the user.
 
		- parameters:
			- finishedScan: A callback that is invoked once the scan has
				finished. The argument will be the QR code if that was detected
				successfully, `nil` else, i.e., if the user canceled the scan.
	
		- note:
			You need to set the `NSCameraUsageDescription` in your `Info.plist`
			else the application will crash when trying to access the camera.
	
		- precondition:
			You must not call this method until a previous scan has finished.
	*/
	public func startScanning(_ finishedScan: @escaping FinishedScan) throws {

		precondition(callback == nil, "Do not start scanning while still active!")

		callback = finishedScan

		guard let window = UIApplication.shared.keyWindow else {
			throw QRCodeReader.Error.noKeyWindow
		}

		var permissionsGranted = false
		let permissionStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)

		switch permissionStatus {
			case .authorized:
				permissionsGranted = true
			case .notDetermined:
				let semaphore = DispatchSemaphore.init(value: 0)
				AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) {
					permissionsGranted = $0
					semaphore.signal()
				}
				semaphore.wait()
			case .denied:
				let alert = UIAlertController(title: "No permission to access the camera", message: "Permission to access the camera is required to read QR codes. You can grant permissions from the application's settings.", preferredStyle: .alert)

				alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
				alert.addAction(UIAlertAction(title: "Open Settings", style: .default, handler: {
					action in

					UIApplication.shared.open(URL(string:UIApplicationOpenSettingsURLString)!)
				}))

				window.rootViewController?.present(alert, animated: true)

				permissionsGranted = false
			case .restricted:
				let alert = UIAlertController(title: "Camera access is restricted", message: "Permission to access the camera is required to read QR codes. You can undo the restriction via Settings → Restrictions → Camera.", preferredStyle: .alert)

				alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

				window.rootViewController?.present(alert, animated: true)

				permissionsGranted = false
		}

		guard permissionsGranted else {
			// This is also triggered if the user is hinted that the permission
			// is denied or restricted.
			throw QRCodeReader.Error.permissionsNotGranted
		}

		guard let camera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) else {
			throw QRCodeReader.Error.noCaptureDevice
		}

		let input = try AVCaptureDeviceInput(device: camera)

		session = AVCaptureSession()
		session.addInput(input)

		let output = AVCaptureMetadataOutput()
		session.addOutput(output)

		output.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
		output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)

		videoLayer = AVCaptureVideoPreviewLayer(session: session)
		videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
		videoLayer.frame = window.layer.bounds
		window.layer.addSublayer(videoLayer)

		cancelButton = UIButton(frame: CGRect(x: cancelButtonMargin, y: window.frame.height - (cancelButtonHeight + cancelButtonMargin), width: window.frame.width - (2 * cancelButtonMargin), height: cancelButtonHeight))
		cancelButton.setTitle("Cancel", for: .normal)
		cancelButton.setTitleColor(cancelButtonTextColor, for: .normal)
		cancelButton.backgroundColor = cancelButtonBackgroundColor
		cancelButton.layer.cornerRadius = 7.5
		cancelButton.clipsToBounds = true
		cancelButton.addTarget(self, action: #selector(stopScanning), for: .primaryActionTriggered)
		window.addSubview(cancelButton)

		session.startRunning()
	}

	// MARK: AVCaptureMetadataOutputObjectsDelegate

	/**
		- see: `AVCaptureMetadataOutputObjectsDelegate`
	*/
	public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
		guard (metadataObjects != nil && !metadataObjects.isEmpty) else {
			return
		}

		let metadataObject = metadataObjects.first as! AVMetadataObject

		if metadataObject.type == AVMetadataObjectTypeQRCode {
			let qrCode = videoLayer.transformedMetadataObject(for: metadataObject) as! AVMetadataMachineReadableCodeObject

			if qrCode.stringValue != nil {

				// Vibrate or blink the screen to indicate success
				if feedbackOnSuccess {
					let feedback = UIImpactFeedbackGenerator(style: .light)
					feedback.impactOccurred()
				}

				stopScanning()

				callback!(qrCode.stringValue)
				
				callback = nil
			}
		}
	}
}

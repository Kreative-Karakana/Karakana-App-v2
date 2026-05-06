import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var secureOverlay: UIView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "karakana/screenshot", binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { [weak self] call, result in
        switch call.method {
        case "enableScreenshotPrevention":
          self?.enableSecureOverlay()
          result(nil)
        case "disableScreenshotPrevention":
          self?.disableSecureOverlay()
          result(nil)
        case "isScreenCaptured":
          result(UIScreen.main.isCaptured)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func enableSecureOverlay() {
    guard let root = window else { return }
    if secureOverlay != nil { return }

    let overlay = UIView(frame: root.bounds)
    overlay.backgroundColor = UIColor.clear
    overlay.isUserInteractionEnabled = false

    let secureField = UITextField(frame: overlay.bounds)
    secureField.isSecureTextEntry = true
    secureField.isUserInteractionEnabled = false
    secureField.backgroundColor = UIColor.clear
    overlay.addSubview(secureField)

    root.addSubview(overlay)
    secureOverlay = overlay
  }

  private func disableSecureOverlay() {
    secureOverlay?.removeFromSuperview()
    secureOverlay = nil
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

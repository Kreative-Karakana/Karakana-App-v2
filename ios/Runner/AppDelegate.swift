import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // The secure UITextField container that wraps the Flutter view.
  // A view that is a direct subview of a UITextField with isSecureTextEntry = true
  // is rendered black by iOS in both screenshots and screen recordings —
  // the same protection used by banking and streaming apps.
  private var secureContainer: UITextField?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "karakana/screenshot", binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { [weak self] call, result in
        switch call.method {
        case "enableScreenshotPrevention":
          self?.enableSecureMode()
          result(nil)
        case "disableScreenshotPrevention":
          self?.disableSecureMode()
          result(nil)
        case "isScreenCaptured":
          // isCaptured is true during AirPlay mirroring, screen recording, etc.
          result(UIScreen.main.isCaptured)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Wraps the Flutter view inside a secure UITextField so iOS blacks it out
  /// in both screenshots and screen recordings (works on iOS 13+).
  private func enableSecureMode() {
    guard secureContainer == nil,
          let flutterVC = window?.rootViewController as? FlutterViewController,
          let flutterView = flutterVC.view,
          let parent = flutterView.superview else { return }

    let field = UITextField(frame: flutterView.frame)
    field.isSecureTextEntry = true
    field.isUserInteractionEnabled = true
    field.backgroundColor = .clear
    field.autoresizingMask = flutterView.autoresizingMask

    // Insert at the same z-position in the parent hierarchy.
    let index = parent.subviews.firstIndex(of: flutterView) ?? parent.subviews.count
    parent.insertSubview(field, at: index)

    // Move the Flutter view inside the secure field.
    // This is the key step: iOS protects all content that is a direct subview
    // of a UITextField whose isSecureTextEntry is true.
    field.addSubview(flutterView)
    flutterView.frame = field.bounds
    flutterView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

    secureContainer = field
  }

  /// Restores the Flutter view to its original parent, removing the secure wrapper.
  private func disableSecureMode() {
    guard let field = secureContainer,
          let parent = field.superview else {
      secureContainer = nil
      return
    }

    if let flutterView = (window?.rootViewController as? FlutterViewController)?.view {
      let index = parent.subviews.firstIndex(of: field) ?? parent.subviews.count
      parent.insertSubview(flutterView, at: index)
      flutterView.frame = field.frame
      flutterView.autoresizingMask = field.autoresizingMask
    }

    field.removeFromSuperview()
    secureContainer = nil
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // The secure UITextField container that wraps the Flutter view.
  // A view that is a direct subview of a UITextField with isSecureTextEntry = true
  // is rendered black by iOS in both screenshots and screen recordings —
  // the same protection used by banking and streaming apps.
  private var secureContainer: UITextField?
  private weak var protectedFlutterView: UIView?

  private var activeWindow: UIWindow? {
    if let window, window.isKeyWindow {
      return window
    }

    return UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)
  }

  private func findFlutterViewController(
    from controller: UIViewController?
  ) -> FlutterViewController? {
    guard let controller else { return nil }
    if let flutterController = controller as? FlutterViewController {
      return flutterController
    }
    if let presented = findFlutterViewController(from: controller.presentedViewController) {
      return presented
    }
    for child in controller.children {
      if let flutterController = findFlutterViewController(from: child) {
        return flutterController
      }
    }
    return nil
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func registerScreenshotChannel(binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "karakana/screenshot",
      binaryMessenger: binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "enableScreenshotPrevention":
        #if targetEnvironment(simulator)
        // The simulator cannot faithfully provide or validate production
        // screenshot protection. Allow reader QA here without weakening the
        // fail-closed behavior compiled for physical iOS devices.
        result(true)
        #else
        result(self?.enableSecureMode() ?? false)
        #endif
      case "disableScreenshotPrevention":
        self?.disableSecureMode()
        result(true)
      case "isScreenCaptured":
        #if targetEnvironment(simulator)
        result(false)
        #else
        // isCaptured is true during AirPlay mirroring, screen recording, etc.
        result(UIScreen.main.isCaptured)
        #endif
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Wraps the Flutter view inside a secure UITextField so iOS blacks it out
  /// in both screenshots and screen recordings (works on iOS 13+).
  private func enableSecureMode() -> Bool {
    if secureContainer != nil { return true }

    guard let flutterVC = findFlutterViewController(
            from: activeWindow?.rootViewController
          ),
          let flutterView = flutterVC.view,
          let parent = flutterView.superview else { return false }

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
    protectedFlutterView = flutterView
    return true
  }

  /// Restores the Flutter view to its original parent, removing the secure wrapper.
  private func disableSecureMode() {
    guard let field = secureContainer,
          let parent = field.superview else {
      secureContainer = nil
      return
    }

    if let flutterView = protectedFlutterView {
      let index = parent.subviews.firstIndex(of: field) ?? parent.subviews.count
      parent.insertSubview(flutterView, at: index)
      flutterView.frame = field.frame
      flutterView.autoresizingMask = field.autoresizingMask
    }

    field.removeFromSuperview()
    secureContainer = nil
    protectedFlutterView = nil
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerScreenshotChannel(
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
  }
}

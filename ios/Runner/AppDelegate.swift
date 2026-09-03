import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "com.example.helloIosApp/shared",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { (call, result) in
      if call.method == "saveDevices" {
        if let devices = call.arguments as? [String] {
          let defaults = UserDefaults(suiteName: "group.com.example.helloIosApp.shared")
          defaults?.set(devices, forKey: "deviceList")
          WidgetCenter.shared.reloadAllTimelines()
          result(true)
        } else {
          result(FlutterError(code: "BAD_ARGS", message: "Expected array of strings", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

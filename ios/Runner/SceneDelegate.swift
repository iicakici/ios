import Flutter
import UIKit
import WidgetKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    guard let windowScene = scene as? UIWindowScene,
          let window = windowScene.windows.first,
          let controller = window.rootViewController as? FlutterViewController else {
      return
    }

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
  }
}

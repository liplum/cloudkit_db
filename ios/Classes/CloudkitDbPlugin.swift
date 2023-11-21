import Flutter
import UIKit

public class CloudkitDbPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "cloudkit_db", binaryMessenger: registrar.messenger())
    let instance = CloudkitDbPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let parts = call.method.split(separator: ".")
    if parts.count == 1 {
      result(FlutterMethodNotImplemented)
    } else if parts.count == 2 {
      if parts[0] == "documents" {
        handleDocuments(call, result: result)
      } else if parts[0] == "kv" {
        handleKv(call, result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    } else {
      result(FlutterMethodNotImplemented)
    }
  }

  public func handleDocuments(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let containerId = args["containerId"] as? String
    else {
      result(argumentError)
      return
    }
    result("OK")
  }

  public func handleKv(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let containerId = args["containerId"] as? String
    else {
      result(argumentError)
      return
    }
    result("OK")
  }
}

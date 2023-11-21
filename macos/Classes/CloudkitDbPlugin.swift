import CloudKit
import Cocoa
import FlutterMacOS

public class CloudkitDbPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "cloudkit_db", binaryMessenger: registrar.messenger)
    let instance: CloudkitDbPlugin = CloudkitDbPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "getPlatformVersion" {
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
    }
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
let argumentError = FlutterError(code: "E_ARG", message: "Invalid Arguments", details: nil)
let containerError = FlutterError(
  code: "E_CTR",
  message: "Invalid containerId, or user is not signed in, or user disabled iCloud permission",
  details: nil)
let fileNotFoundError = FlutterError(
  code: "E_FNF", message: "The file does not exist", details: nil)

public class CloudKitDbKv {
  public func getString(containerId: String, key: String, result: @escaping FlutterResult) {
    let database = CKContainer(identifier: containerId).privateCloudDatabase

    let query = CKQuery(recordType: "StorageItem", predicate: NSPredicate(value: true))

    database.perform(query, inZoneWith: nil) { (records, error) in
      let foundRecords = records?.compactMap({ $0.value(forKey: key) as? String })
      result(foundRecords)
    }
  }
}

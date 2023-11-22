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
      return
    }
    let parts = call.method.split(separator: ".")
    if parts.count == 1 {
      result(FlutterMethodNotImplemented)
    } else if parts.count == 2 {
      guard let args = call.arguments as? [String: Any]
      else {
        result(argumentError)
        return
      }
      if parts[0] == "documents" {
        handleDocuments(method: String(parts[1]), args: args, result)
      } else if parts[0] == "kv" {
        handleKv(method: String(parts[1]), args: args, result)
      } else {
        result(FlutterMethodNotImplemented)
        return
      }
    } else {
      result(FlutterMethodNotImplemented)
      return
    }
  }

  public func handleDocuments(
    method: String, args: [String: Any?], _ result: @escaping FlutterResult
  ) {
    guard let containerId = args["containerId"] as? String
    else {
      result(argumentError)
      return
    }
    switch method {
    case "upload":
      guard let key = args["key"] as? String,
        let localFilePath = args["localFilePath"] as? String,
        let cloudFilePath = args["cloudFilePath"] as? String
      else {
        result(argumentError)
        return
      }
      upload(
        containerId: containerId, localFilePath: localFilePath, cloudFilePath: cloudFilePath,
        result)
    case "list":
      break
    default: break
    }
    result(nil)
    return
  }

  public func handleKv(
    method: String, args: [String: Any?], _ result: @escaping FlutterResult
  ) {
    guard let containerId = args["containerId"] as? String
    else {
      result(argumentError)
      return
    }
    switch method {
    case "getString":
      guard let key = args["key"] as? String else {
        result(argumentError)
        return
      }
      getString(containerId: containerId, key: key, result)
    case "putString":
      guard let key = args["key"] as? String, let value = args["value"] as Any? else {
        result(argumentError)
        return
      }
      putString(containerId: containerId, key: key, value: value, result)
    default: break
    }
    result(nil)
    return
  }

  public func list(
    containerId: String,
    _ result: @escaping FlutterResult
  ) {

  }

  public func upload(
    containerId: String, localFilePath: String, cloudFilePath: String,
    _ result: @escaping FlutterResult
  ) {
    guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: containerId)
    else {
      result(containerError)
      return
    }
    debugPrint("containerURL: \(containerURL.path)")

    let cloudFileURL = containerURL.appendingPathComponent(cloudFilePath)
    let localFileURL = URL(fileURLWithPath: localFilePath)

    do {
      if FileManager.default.fileExists(atPath: cloudFileURL.path) {
        try FileManager.default.removeItem(at: cloudFileURL)
      } else {
        let cloudFileDirURL = cloudFileURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: cloudFileDirURL.path) {
          try FileManager.default.createDirectory(
            at: cloudFileDirURL, withIntermediateDirectories: true, attributes: nil)
        }
      }
      try FileManager.default.copyItem(at: localFileURL, to: cloudFileURL)
      result(nil)
    } catch {
      result(nativeCodeError(error))
    }
  }

  public func getString(containerId: String, key: String, _ result: @escaping FlutterResult) {
    let database = CKContainer(identifier: containerId).privateCloudDatabase

    let query = CKQuery(recordType: "StorageItem", predicate: NSPredicate(value: true))

    /// `result([String])` if saved, otherwise, `result(nil)`
    database.perform(query, inZoneWith: nil) { (records, error) in
      if records != nil, error == nil {
        let foundRecords = records!.compactMap({ $0.value(forKey: key) as? String })
        result(foundRecords)
      } else {
        result(nil)
      }
    }
  }

  /// `result(true)` if saved, otherwise, `result(false)`
  public func putString(
    containerId: String, key: String, value: Any?, _ result: @escaping FlutterResult
  ) {
    let database = CKContainer(identifier: containerId).privateCloudDatabase
    let record = CKRecord(recordType: "StorageItem")
    record.setValue(value, forKey: key)

    database.save(record) { (record, error) in
      if record != nil, error == nil {
        result(true)
      } else {
        result(false)
      }
    }
  }
}
let argumentError = FlutterError(code: "E_ARG", message: "Invalid Arguments", details: nil)
let containerError = FlutterError(
  code: "E_CTR",
  message: "Invalid containerId, or user is not signed in, or user disabled iCloud permission",
  details: nil)
let fileNotFoundError = FlutterError(
  code: "E_FNF", message: "The file does not exist", details: nil)

func nativeCodeError(_ error: Error) -> FlutterError {
  return FlutterError(code: "E_NAT", message: "Native Code Error", details: "\(error)")
}

func debugPrint(_ message: String) {
  #if DEBUG
    print(message)
  #endif
}

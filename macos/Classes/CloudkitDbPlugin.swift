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
      guard let args = call.arguments as? [String: Any]
      else {
        result(argumentError)
        return
      }
      if parts[0] == "documents" {
        handleDocuments(method: String(parts[1]), args: args, result: result)
      } else if parts[0] == "kv" {
        handleKv(method: String(parts[1]), args: args, result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    } else {
      result(FlutterMethodNotImplemented)
    }
  }

  public func handleDocuments(
    method: String, args: [String: Any?], result: @escaping FlutterResult
  ) {
    guard let containerId = args["containerId"] as? String
    else {
      result(argumentError)
      return
    }
    result("OK")
  }

  public func handleKv(
    method: String, args: [String: Any?], result: @escaping FlutterResult
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
      CloudKitDbKv.getString(containerId: containerId, key: key, result: result)
    case "putString":
      guard let key = args["key"] as? String, let value = args["value"] as Any? else {
        result(argumentError)
        return
      }
      CloudKitDbKv.putString(containerId: containerId, key: key, value: value, result: result)
    default: break
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

func nativeCodeError(_ error: Error) -> FlutterError {
  return FlutterError(code: "E_NAT", message: "Native Code Error", details: "\(error)")
}

public class CloudKitDbKv {
  public static func getString(containerId: String, key: String, result: @escaping FlutterResult) {
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
  public static func putString(
    containerId: String, key: String, value: Any?, result: @escaping FlutterResult
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

func debugPrint(_ message: String) {
  #if DEBUG
    print(message)
  #endif
}

public class CloudKitDbDocuments {
  private static func upload(
    containerId: String, localFilePath: String, cloudFileName: String,
    result: @escaping FlutterResult
  ) {
    guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: containerId)
    else {
      result(containerError)
      return
    }
    debugPrint("containerURL: \(containerURL.path)")

    let cloudFileURL = containerURL.appendingPathComponent(cloudFileName)
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
}

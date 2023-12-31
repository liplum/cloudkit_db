import CloudKit
import Cocoa
import FlutterMacOS

public class CloudkitDbPlugin: NSObject, FlutterPlugin {
  var listStreamHandler: StreamHandler?
  var messenger: FlutterBinaryMessenger?
  var streamHandlers: [String: StreamHandler] = [:]
  let querySearchScopes = [
    NSMetadataQueryUbiquitousDataScope, NSMetadataQueryUbiquitousDocumentsScope,
  ]

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
        return
      } else if parts[0] == "kv" {
        handleKv(method: String(parts[1]), args: args, result)
        return
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
      guard let localFilePath = args["localFilePath"] as? String,
        let cloudFilePath = args["cloudFilePath"] as? String,
        let eventChannelName = args["eventChannelName"] as? String
      else {
        result(argumentError)
        return
      }
      upload(
        containerId: containerId, localFilePath: localFilePath, cloudFilePath: cloudFilePath,
        eventChannelName: eventChannelName,
        result)
    case "gather":
      guard let eventChannelName = args["eventChannelName"] as? String
      else {
        result(argumentError)
        return
      }
      gather(containerId: containerId, eventChannelName: eventChannelName, result)
    case "download":
      guard let localFilePath = args["localFilePath"] as? String,
        let cloudFilePath = args["cloudFilePath"] as? String,
        let eventChannelName = args["eventChannelName"] as? String
      else {
        result(argumentError)
        return
      }
      download(
        containerId: containerId, cloudFilePath: cloudFilePath, localFilePath: localFilePath,
        eventChannelName: eventChannelName, result)
    case "delete":
      guard let cloudFilePath = args["cloudFilePath"] as? String
      else {
        result(argumentError)
        return
      }
      delete(containerId: containerId, cloudFilePath: cloudFilePath, result)
    case "move":
      guard let fromCloudPathFile = args["fromCloudPathFile"] as? String,
        let toCloudPathFile = args["toCloudPathFile"] as? String
      else {
        result(argumentError)
        return
      }
      move(containerId: containerId, fromCloudPathFile: fromCloudPathFile, toCloudPathFile: toCloudPathFile, result)
    case "createEventChannel":
      guard let eventChannelName = args["eventChannelName"] as? String
      else {
        result(argumentError)
        return
      }
      createEventChannel(eventChannelName: eventChannelName, result)
    default:
      result(FlutterMethodNotImplemented)
    }
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
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func gather(
    containerId: String,
    eventChannelName: String,
    _ result: @escaping FlutterResult
  ) {
    guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: containerId)
    else {
      result(containerError)
      return
    }
    debugPrint("containerURL: \(containerURL.path)")

    let query = NSMetadataQuery.init()
    query.operationQueue = .main
    query.searchScopes = querySearchScopes
    query.predicate = NSPredicate(
      format: "%K beginswith %@", NSMetadataItemPathKey, containerURL.path)
    addGatherFilesObservers(
      query: query, containerURL: containerURL, eventChannelName: eventChannelName, result: result)

    if !eventChannelName.isEmpty {
      let streamHandler = self.streamHandlers[eventChannelName]!
      streamHandler.onCancelHandler = { [self] in
        removeObservers(query)
        query.stop()
        removeStreamHandler(eventChannelName)
      }
    }
    query.start()
  }

  private func addGatherFilesObservers(
    query: NSMetadataQuery, containerURL: URL, eventChannelName: String,
    result: @escaping FlutterResult
  ) {
    NotificationCenter.default.addObserver(
      forName: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: query,
      queue: query.operationQueue
    ) {
      [self] (notification) in
      let files = mapFileAttributesFromQuery(query: query, containerURL: containerURL)
      removeObservers(query)
      if eventChannelName.isEmpty { query.stop() }
      result(files)
    }

    if !eventChannelName.isEmpty {
      NotificationCenter.default.addObserver(
        forName: NSNotification.Name.NSMetadataQueryDidUpdate, object: query,
        queue: query.operationQueue
      ) {
        [self] (notification) in
        let files = mapFileAttributesFromQuery(query: query, containerURL: containerURL)
        let streamHandler = self.streamHandlers[eventChannelName]!
        streamHandler.setEvent(files)
      }
    }
  }

  private func mapFileAttributesFromQuery(query: NSMetadataQuery, containerURL: URL) -> [[String:
    Any?]]
  {
    var fileMaps: [[String: Any?]] = []
    for item in query.results {
      guard let fileItem = item as? NSMetadataItem else { continue }
      guard let fileURL = fileItem.value(forAttribute: NSMetadataItemURLKey) as? URL else {
        continue
      }
      if fileURL.absoluteString.last == "/" { continue }

      let map: [String: Any?] = [
        "relativePath": String(fileURL.absoluteString.dropFirst(containerURL.absoluteString.count)),
        "sizeInBytes": fileItem.value(forAttribute: NSMetadataItemFSSizeKey),
        "creationDate": (fileItem.value(forAttribute: NSMetadataItemFSCreationDateKey) as? Date)?
          .timeIntervalSince1970,
        "contentChangeDate":
          (fileItem.value(forAttribute: NSMetadataItemFSContentChangeDateKey) as? Date)?
          .timeIntervalSince1970,
        "hasUnresolvedConflicts": fileItem.value(
          forAttribute: NSMetadataUbiquitousItemHasUnresolvedConflictsKey),
        "downloadStatus": fileItem.value(
          forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey),
        "isDownloading": fileItem.value(forAttribute: NSMetadataUbiquitousItemIsDownloadingKey),
        "isUploaded": fileItem.value(forAttribute: NSMetadataUbiquitousItemIsUploadedKey),
        "isUploading": fileItem.value(forAttribute: NSMetadataUbiquitousItemIsUploadingKey),
      ]
      fileMaps.append(map)
    }
    return fileMaps
  }

  public func upload(
    containerId: String, localFilePath: String, cloudFilePath: String,
    eventChannelName: String,
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
    } catch {
      result(nativeCodeError(error))
    }
    if !eventChannelName.isEmpty {
      let query = NSMetadataQuery.init()
      query.operationQueue = .main
      query.searchScopes = querySearchScopes
      query.predicate = NSPredicate(format: "%K == %@", NSMetadataItemPathKey, cloudFileURL.path)

      let uploadStreamHandler = self.streamHandlers[eventChannelName]!
      uploadStreamHandler.onCancelHandler = { [self] in
        removeObservers(query)
        query.stop()
        removeStreamHandler(eventChannelName)
      }
      addUploadObservers(query: query, eventChannelName: eventChannelName)

      query.start()
    }

    result(nil)
  }

  private func addUploadObservers(query: NSMetadataQuery, eventChannelName: String) {
    NotificationCenter.default.addObserver(
      forName: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: query,
      queue: query.operationQueue
    ) { [self] (notification) in
      onUploadQueryNotification(query: query, eventChannelName: eventChannelName)
    }

    NotificationCenter.default.addObserver(
      forName: NSNotification.Name.NSMetadataQueryDidUpdate, object: query,
      queue: query.operationQueue
    ) { [self] (notification) in
      onUploadQueryNotification(query: query, eventChannelName: eventChannelName)
    }
  }

  private func onUploadQueryNotification(query: NSMetadataQuery, eventChannelName: String) {
    if query.results.count == 0 {
      return
    }

    guard let fileItem = query.results.first as? NSMetadataItem else { return }
    guard let fileURL = fileItem.value(forAttribute: NSMetadataItemURLKey) as? URL else { return }
    guard
      let fileURLValues = try? fileURL.resourceValues(forKeys: [.ubiquitousItemUploadingErrorKey])
    else { return }
    guard let streamHandler = self.streamHandlers[eventChannelName] else { return }

    if let error = fileURLValues.ubiquitousItemUploadingError {
      streamHandler.setEvent(nativeCodeError(error))
      return
    }

    if let progress = fileItem.value(forAttribute: NSMetadataUbiquitousItemPercentUploadedKey)
      as? Double
    {
      streamHandler.setEvent(progress)
      if progress >= 100 {
        streamHandler.setEvent(FlutterEndOfEventStream)
        removeStreamHandler(eventChannelName)
      }
    }
  }

  private func download(
    containerId: String, cloudFilePath: String, localFilePath: String, eventChannelName: String,
    _ result: @escaping FlutterResult
  ) {
    guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: containerId)
    else {
      result(containerError)
      return
    }
    debugPrint("containerURL: \(containerURL.path)")

    let cloudFileURL = containerURL.appendingPathComponent(cloudFilePath)
    do {
      try FileManager.default.startDownloadingUbiquitousItem(at: cloudFileURL)
    } catch {
      result(nativeCodeError(error))
    }

    let query = NSMetadataQuery.init()
    query.operationQueue = .main
    query.searchScopes = querySearchScopes
    query.predicate = NSPredicate(format: "%K == %@", NSMetadataItemPathKey, cloudFileURL.path)

    let downloadStreamHandler = self.streamHandlers[eventChannelName]
    downloadStreamHandler?.onCancelHandler = { [self] in
      removeObservers(query)
      query.stop()
      removeStreamHandler(eventChannelName)
    }

    let localFileURL = URL(fileURLWithPath: localFilePath)
    addDownloadObservers(
      query: query, cloudFileURL: cloudFileURL, localFileURL: localFileURL,
      eventChannelName: eventChannelName)

    query.start()
    result(nil)
  }

  private func addDownloadObservers(
    query: NSMetadataQuery, cloudFileURL: URL, localFileURL: URL, eventChannelName: String
  ) {
    NotificationCenter.default.addObserver(
      forName: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: query,
      queue: query.operationQueue
    ) { [self] (notification) in
      onDownloadQueryNotification(
        query: query, cloudFileURL: cloudFileURL, localFileURL: localFileURL,
        eventChannelName: eventChannelName)
    }

    NotificationCenter.default.addObserver(
      forName: NSNotification.Name.NSMetadataQueryDidUpdate, object: query,
      queue: query.operationQueue
    ) { [self] (notification) in
      onDownloadQueryNotification(
        query: query, cloudFileURL: cloudFileURL, localFileURL: localFileURL,
        eventChannelName: eventChannelName)
    }
  }

  private func onDownloadQueryNotification(
    query: NSMetadataQuery, cloudFileURL: URL, localFileURL: URL, eventChannelName: String
  ) {
    if query.results.count == 0 {
      return
    }

    guard let fileItem = query.results.first as? NSMetadataItem else { return }
    guard let fileURL = fileItem.value(forAttribute: NSMetadataItemURLKey) as? URL else { return }
    guard
      let fileURLValues = try? fileURL.resourceValues(forKeys: [
        .ubiquitousItemDownloadingErrorKey, .ubiquitousItemDownloadingStatusKey,
      ])
    else { return }
    let streamHandler = self.streamHandlers[eventChannelName]

    if let error = fileURLValues.ubiquitousItemDownloadingError {
      streamHandler?.setEvent(nativeCodeError(error))
      return
    }

    if let progress = fileItem.value(forAttribute: NSMetadataUbiquitousItemPercentDownloadedKey)
      as? Double
    {
      streamHandler?.setEvent(progress)
    }

    if fileURLValues.ubiquitousItemDownloadingStatus == URLUbiquitousItemDownloadingStatus.current {
      do {
        try moveCloudFile(at: cloudFileURL, to: localFileURL)
        streamHandler?.setEvent(FlutterEndOfEventStream)
        removeStreamHandler(eventChannelName)
      } catch {
        streamHandler?.setEvent(nativeCodeError(error))
      }
    }
  }

  private func moveCloudFile(at: URL, to: URL) throws {
    do {
      if FileManager.default.fileExists(atPath: to.path) {
        try FileManager.default.removeItem(at: to)
      }
      try FileManager.default.copyItem(at: at, to: to)
    } catch {
      throw error
    }
  }

  private func delete(containerId: String, cloudFilePath: String, _ result: @escaping FlutterResult)
  {
    guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: containerId)
    else {
      result(containerError)
      return
    }
    debugPrint("containerURL: \(containerURL.path)")

    let fileURL = containerURL.appendingPathComponent(cloudFilePath)
    let fileCoordinator = NSFileCoordinator(filePresenter: nil)
    fileCoordinator.coordinate(
      writingItemAt: fileURL, options: NSFileCoordinator.WritingOptions.forDeleting, error: nil
    ) {
      writingURL in
      do {
        var isDir: ObjCBool = false
        if !FileManager.default.fileExists(atPath: writingURL.path, isDirectory: &isDir) {
          result(fileNotFoundError)
          return
        }
        try FileManager.default.removeItem(at: writingURL)
        result(nil)
      } catch {
        debugPrint("error: \(error.localizedDescription)")
        result(nativeCodeError(error))
      }
    }
  }

  private func move(
    containerId: String, fromCloudPathFile: String, toCloudPathFile: String,
    _ result: @escaping FlutterResult
  ) {
    guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: containerId)
    else {
      result(containerError)
      return
    }
    debugPrint("containerURL: \(containerURL.path)")

    let atURL = containerURL.appendingPathComponent(fromCloudPathFile)
    let toURL = containerURL.appendingPathComponent(toCloudPathFile)
    let fileCoordinator = NSFileCoordinator(filePresenter: nil)
    fileCoordinator.coordinate(
      writingItemAt: atURL, options: NSFileCoordinator.WritingOptions.forMoving,
      writingItemAt: toURL, options: NSFileCoordinator.WritingOptions.forReplacing, error: nil
    ) {
      atWritingURL, toWritingURL in
      do {
        let toDirURL = toWritingURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: toDirURL.path) {
          try FileManager.default.createDirectory(
            at: toDirURL, withIntermediateDirectories: true, attributes: nil)
        }
        try FileManager.default.moveItem(at: atWritingURL, to: toWritingURL)
        result(nil)
      } catch {
        debugPrint("error: \(error.localizedDescription)")
        result(nativeCodeError(error))
      }
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
  private func removeObservers(_ query: NSMetadataQuery) {
    NotificationCenter.default.removeObserver(
      self, name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: query)
    NotificationCenter.default.removeObserver(
      self, name: NSNotification.Name.NSMetadataQueryDidUpdate, object: query)
  }

  private func createEventChannel(eventChannelName: String, _ result: @escaping FlutterResult) {
    let streamHandler = StreamHandler()
    let eventChannel = FlutterEventChannel(name: eventChannelName, binaryMessenger: self.messenger!)
    eventChannel.setStreamHandler(streamHandler)
    self.streamHandlers[eventChannelName] = streamHandler

    result(nil)
  }

  private func removeStreamHandler(_ eventChannelName: String) {
    self.streamHandlers[eventChannelName] = nil
  }
}
class StreamHandler: NSObject, FlutterStreamHandler {
  private var _eventSink: FlutterEventSink?
  var onCancelHandler: (() -> Void)?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    _eventSink = events
    debugPrint("on listen")
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    onCancelHandler?()
    _eventSink = nil
    debugPrint("on cancel")
    return nil
  }

  func setEvent(_ data: Any) {
    _eventSink?(data)
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

import CloudKit

public protocol CloudKitDbKvProtocol {
  func getString(containerId: String, key: String)
}

public class CloudKitDbKv: CloudKitDbKvProtocol {
  public func getString(containerId: String, key: String) {
    let database = CKContainer(identifier: containerId).privateCloudDatabase

    let query = CKQuery(recordType: "StorageItem", predicate: NSPredicate(value: true))

    database.perform(query, inZoneWith: nil) { (records, error) in
      let foundRecords = records?.compactMap({ it.value(forKey: key) as? String })
      result(foundRecords)
    }
  }
}

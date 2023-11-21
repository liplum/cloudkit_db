import 'cloudkit_db_platform_interface.dart';
import 'documents.dart';
import 'kv.dart';

class CloudkitDb {
  final String containerId;
  final CloudKitDocuments documents;
  final CloudKitKv kv;

  CloudkitDb({
    required this.containerId,
  })  : documents = CloudKitDocuments(containerId: containerId),
        kv = CloudKitKv(containerId: containerId);

  Future<String?> getPlatformVersion() {
    return CloudkitDbPlatform.instance.getPlatformVersion();
  }
}

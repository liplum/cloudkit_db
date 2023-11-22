import 'cloudkit_db_platform_interface.dart';
import 'documents.dart';
import 'kv.dart';

class CloudkitDb {
  final String containerId;
  final CloudKitDbDocuments documents;
  final CloudKitDbKv kv;

  CloudkitDb({
    required this.containerId,
  })  : documents = CloudKitDbDocuments(containerId: containerId),
        kv = CloudKitDbKv(containerId: containerId);

  Future<String?> getPlatformVersion() {
    return CloudkitDbPlatform.instance.getPlatformVersion();
  }
}

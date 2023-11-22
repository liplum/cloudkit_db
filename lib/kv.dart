import 'cloudkit_db_platform_interface.dart';

class CloudKitDbKv {
  final String containerId;

  CloudKitDbKv({
    required this.containerId,
  });

  Future<String?> getString(String key) async {
    return CloudkitDbPlatform.instance.getKvString(
      containerId: containerId,
      key: key,
    );
  }
}

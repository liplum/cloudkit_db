import 'cloudkit_db_platform_interface.dart';

class CloudKitKv {
  final String containerId;

  CloudKitKv({
    required this.containerId,
  });

  Future<String?> getString(String key) async {
    return CloudkitDbPlatform.instance.kvGetString(
      containerId: containerId,
      key: key,
    );
  }
}

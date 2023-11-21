import 'cloudkit_db_platform_interface.dart';

class CloudkitDb {
  final String containerId;

  const CloudkitDb({
    required this.containerId,
  });

  Future<String?> getPlatformVersion() {
    return CloudkitDbPlatform.instance.getPlatformVersion();
  }
}


import 'cloudkit_db_platform_interface.dart';

class CloudkitDb {
  Future<String?> getPlatformVersion() {
    return CloudkitDbPlatform.instance.getPlatformVersion();
  }
}

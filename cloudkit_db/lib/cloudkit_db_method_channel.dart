import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'cloudkit_db_platform_interface.dart';

/// An implementation of [CloudkitDbPlatform] that uses method channels.
class MethodChannelCloudkitDb extends CloudkitDbPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('cloudkit_db');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}

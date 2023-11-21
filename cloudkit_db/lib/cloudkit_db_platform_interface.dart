import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'cloudkit_db_method_channel.dart';

abstract class CloudkitDbPlatform extends PlatformInterface {
  /// Constructs a CloudkitDbPlatform.
  CloudkitDbPlatform() : super(token: _token);

  static final Object _token = Object();

  static CloudkitDbPlatform _instance = MethodChannelCloudkitDb();

  /// The default instance of [CloudkitDbPlatform] to use.
  ///
  /// Defaults to [MethodChannelCloudkitDb].
  static CloudkitDbPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CloudkitDbPlatform] when
  /// they register themselves.
  static set instance(CloudkitDbPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}

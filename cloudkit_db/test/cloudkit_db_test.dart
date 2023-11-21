import 'package:flutter_test/flutter_test.dart';
import 'package:cloudkit_db/cloudkit_db.dart';
import 'package:cloudkit_db/cloudkit_db_platform_interface.dart';
import 'package:cloudkit_db/cloudkit_db_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockCloudkitDbPlatform
    with MockPlatformInterfaceMixin
    implements CloudkitDbPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final CloudkitDbPlatform initialPlatform = CloudkitDbPlatform.instance;

  test('$MethodChannelCloudkitDb is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelCloudkitDb>());
  });

  test('getPlatformVersion', () async {
    CloudkitDb cloudkitDbPlugin = CloudkitDb();
    MockCloudkitDbPlatform fakePlatform = MockCloudkitDbPlatform();
    CloudkitDbPlatform.instance = fakePlatform;

    expect(await cloudkitDbPlugin.getPlatformVersion(), '42');
  });
}

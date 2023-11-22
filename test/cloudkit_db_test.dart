import 'package:cloudkit_db/file.dart';
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

  @override
  Future<String?> getKvString({
    required String containerId,
    required String key,
  }) =>
      Future.value('[$containerId] value of "$key"');

  @override
  Future<void> deleteDocument(
      {required String containerId, required String cloudFilePath}) {
    // TODO: implement deleteDocument
    throw UnimplementedError();
  }

  @override
  Future<void> downloadDocument(
      {required String containerId,
      required String cloudSourceFilePath,
      required String localDestFilePath,
      void Function(Stream<double> p1)? onProgress}) {
    // TODO: implement downloadDocument
    throw UnimplementedError();
  }

  @override
  Future<List<ICloudFile>> gatherDocument(
      {required String containerId,
      void Function(Stream<List<ICloudFile>> p1)? onUpdate}) {
    // TODO: implement gatherDocument
    throw UnimplementedError();
  }

  @override
  Future<void> moveDocument({
    required String containerId,
    required String fromCloudPathFile,
    required String toCloudPathFile,
  }) {
    // TODO: implement moveDocument
    throw UnimplementedError();
  }

  @override
  Future<void> uploadDocument(
      {required String containerId,
      required String localSourceFilePath,
      required String cloudDestFilePath,
      void Function(Stream<double> p1)? onProgress}) {
    // TODO: implement uploadDocument
    throw UnimplementedError();
  }
}

void main() {
  const testContainerId = "net.liplum.CloudKitDb";
  final CloudkitDbPlatform initialPlatform = CloudkitDbPlatform.instance;

  test('$MethodChannelCloudkitDb is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelCloudkitDb>());
  });

  test('getPlatformVersion', () async {
    final cloudkitDbPlugin = CloudkitDb(containerId: testContainerId);
    MockCloudkitDbPlatform fakePlatform = MockCloudkitDbPlatform();
    CloudkitDbPlatform.instance = fakePlatform;

    expect(await cloudkitDbPlugin.getPlatformVersion(), '42');
  });
}

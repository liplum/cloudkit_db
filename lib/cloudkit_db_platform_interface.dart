import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'cloudkit_db_method_channel.dart';
import 'file.dart';

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

  /// Gather all the files' meta data from iCloud container.
  ///
  /// [containerId] is the iCloud Container Id.
  ///
  /// [onUpdate] is an optional parameter can be used as a call back every time
  /// when the list of files are updated. It won't be triggered when the
  /// function initially returns the list of files.
  ///
  /// The function returns a future of list of ICloudFile.
  Future<List<ICloudFile>> gatherDocument({
    required String containerId,
    void Function(Stream<List<ICloudFile>>)? onUpdate,
  }) async {
    throw UnimplementedError('gatherDocument() has not been implemented.');
  }

  /// Upload a local file to iCloud.
  ///
  /// [containerId] is the iCloud Container Id.
  ///
  /// [localSourceFilePath] is the full path of the local file.
  ///
  /// [cloudDestFilePath] is the relative path of the file to be stored in
  /// iCloud.
  ///
  /// [onProgress] is an optional callback to track the progress of the
  /// upload. It takes a Stream<double> as input, which is the percentage of
  /// the data being uploaded.
  ///
  /// The returned future completes without waiting for the file to be uploaded
  /// to iCloud.
  Future<void> uploadDocument({
    required String containerId,
    required String localSourceFilePath,
    required String cloudDestFilePath,
    void Function(Stream<double>)? onProgress,
  }) async {
    throw UnimplementedError('uploadDocument() has not been implemented.');
  }

  /// Download a file from iCloud.
  ///
  /// [containerId] is the iCloud Container Id.
  ///
  /// [cloudSourceFilePath] is the relative path of the file on iCloud, such as file1
  /// or folder/file2.
  ///
  /// [localDestFilePath] is the full path of the local file to be saved as.
  ///
  /// [onProgress] is an optional callback to track the progress of the
  /// download. It takes a Stream<double> as input, which is the percentage of
  /// the data being downloaded.
  ///
  /// The returned future completes without waiting for the file to be
  /// downloaded.
  Future<void> downloadDocument({
    required String containerId,
    required String cloudSourceFilePath,
    required String localDestFilePath,
    void Function(Stream<double>)? onProgress,
  }) async {
    throw UnimplementedError('downloadDocument() has not been implemented.');
  }

  /// Delete a file from iCloud container directory, whether it is been
  /// downloaded or not
  ///
  /// [containerId] is the iCloud Container Id.
  ///
  /// [cloudFilePath] is the relative path of the file on iCloud, such as file1
  /// or folder/file2
  ///
  /// PlatformException with code PlatformExceptionCode.fileNotFound will be
  /// thrown if the file does not exist
  Future<void> deleteDocument({
    required String containerId,
    required String cloudFilePath,
  }) async {
    throw UnimplementedError('deleteDocument() has not been implemented.');
  }

  /// Move a file from one location to another in the iCloud container
  ///
  /// [containerId] is the iCloud Container Id.
  ///
  /// [fromRelativePath] is the relative path of the file to be moved, such as
  /// folder1/file
  ///
  /// [toRelativePath] is the relative path to move to, such as folder2/file
  ///
  /// PlatformException with code PlatformExceptionCode.fileNotFound will be
  /// thrown if the file does not exist
  Future<void> moveDocument({
    required String containerId,
    required String fromCloudPathFile,
    required String toCloudPathFile,
  }) async {
    throw UnimplementedError('moveDocument() has not been implemented.');
  }

  Future<String?> getKvString({
    required String containerId,
    required String key,
  }) async {
    throw UnimplementedError('getKvString() has not been implemented.');
  }
}

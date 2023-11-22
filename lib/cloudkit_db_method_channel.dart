import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'cloudkit_db_platform_interface.dart';
import 'file.dart';

/// An implementation of [CloudkitDbPlatform] that uses method channels.
class MethodChannelCloudkitDb extends CloudkitDbPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('cloudkit_db');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<List<ICloudFile>> gatherDocument({
    required String containerId,
    void Function(Stream<List<ICloudFile>>)? onUpdate,
  }) async {
    final eventChannelName = onUpdate == null
        ? ''
        : _generateEventChannelName('gather', containerId);

    if (onUpdate != null) {
      await methodChannel.invokeMethod(
        'createEventChannel',
        {'eventChannelName': eventChannelName},
      );

      final gatherEventChannel = EventChannel(eventChannelName);
      final stream = gatherEventChannel
          .receiveBroadcastStream()
          .where((event) => event is List)
          .map<List<ICloudFile>>((event) =>
              List<Map<dynamic, dynamic>>.from(event)
                  .map(ICloudFile.fromMap)
                  .toList());

      onUpdate(stream);
    }

    final mapList = await methodChannel
        .invokeListMethod<Map<dynamic, dynamic>>('documents.gather', {
      'containerId': containerId,
      'eventChannelName': eventChannelName,
    });

    return (mapList ?? const []).map(ICloudFile.fromMap).toList();
  }

  @override
  Future<void> uploadDocument({
    required String containerId,
    required String filePath,
    required String destinationRelativePath,
    void Function(Stream<double>)? onProgress,
  }) async {
    var eventChannelName = '';

    if (onProgress != null) {
      eventChannelName = _generateEventChannelName('upload', containerId);

      await methodChannel.invokeMethod('documents.createEventChannel', {
        'eventChannelName': eventChannelName,
      });

      final uploadEventChannel = EventChannel(eventChannelName);
      final stream = uploadEventChannel
          .receiveBroadcastStream()
          .where((event) => event is double)
          .map((event) => event as double);

      onProgress(stream);
    }

    await methodChannel.invokeMethod('documents.upload', {
      'containerId': containerId,
      'localFilePath': filePath,
      'cloudFilePath': destinationRelativePath,
      'eventChannelName': eventChannelName
    });
  }

  @override
  Future<void> downloadDocument({
    required String containerId,
    required String relativePath,
    required String destinationFilePath,
    void Function(Stream<double>)? onProgress,
  }) async {
    var eventChannelName = '';

    if (onProgress != null) {
      eventChannelName = _generateEventChannelName('download', containerId);

      await methodChannel.invokeMethod(
        'documents.createEventChannel',
        {'eventChannelName': eventChannelName},
      );

      final downloadEventChannel = EventChannel(eventChannelName);
      final stream = downloadEventChannel
          .receiveBroadcastStream()
          .where((event) => event is double)
          .map((event) => event as double);

      onProgress(stream);
    }

    await methodChannel.invokeMethod('documents.download', {
      'containerId': containerId,
      'cloudFilePath': relativePath,
      'localFilePath': destinationFilePath,
      'eventChannelName': eventChannelName
    });
  }

  @override
  Future<void> deleteDocument({
    required containerId,
    required String relativePath,
  }) async {
    await methodChannel.invokeMethod('documents.delete', {
      'containerId': containerId,
      'cloudFilePath': relativePath,
    });
  }

  @override
  Future<void> moveDocument({
    required containerId,
    required String fromRelativePath,
    required String toRelativePath,
  }) async {
    await methodChannel.invokeMethod('documents.move', {
      'containerId': containerId,
      'atRelativePath': fromRelativePath,
      'toRelativePath': toRelativePath,
    });
  }

  /// Private method to generate event channel names
  String _generateEventChannelName(
    String eventType,
    String containerId,
  ) =>
      [
        'cloudkit_db',
        'event',
        eventType,
        containerId,
        '${DateTime.now().millisecondsSinceEpoch}_${Object().hashCode}'
      ].join('/');

  @override
  Future<String?> getKvString({
    required String containerId,
    required String key,
  }) async {
    return await methodChannel.invokeMethod<String>('kv.getString', {
      "containerId": containerId,
      "key": key,
    });
  }
}

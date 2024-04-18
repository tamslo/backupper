import 'dart:io';

import 'package:yaml/yaml.dart';

import 'module.dart';

class Constants {
  Constants._(dynamic config)
      : today = DateTime.now(),
        backupVolumePath = config['backupVolumePath'],
        encryptedVolumePath = config['encryptedVolumePath'],
        backupLocations = config['backupLocations'].map<BackupLocation>(
          (object) =>
            BackupLocation.fromPath(object['path'], name: object['name']))
            .toList();
  static Constants? _constants;

  static Future<Constants> getInstance() async {
    if (_constants == null) {
      
      final configString = await File('config.yaml').readAsString();
      final config = loadYaml(configString);
      _constants = Constants._(config);
    }
    return _constants!;
  }

  final zipEnding = '.zip';
  final gibBytes = 1073741824;
  int get compressionThreshold => 9 * gibBytes;
  final ignoredFiles = [ '.DS_Store' ];

  late DateTime today;
  late String backupVolumePath;
  late String encryptedVolumePath;
  late List<BackupLocation> backupLocations;

  String get dateStamp =>
    '${today.year.toString().substring(today.year.toString().length - 2)}-'
    '${today.month.toString().padLeft(2,'0')}-'
    '${today.day.toString().padLeft(2,'0')}';

  String get backupDestination =>  '$backupVolumePath/$dateStamp';
}

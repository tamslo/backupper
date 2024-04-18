import 'dart:io';
import 'package:path/path.dart' as path;

import 'module.dart';

String getEncryptedPath(String zipPath, Constants constants) =>
  zipPath.replaceAll(
    constants.backupDestination,
    constants.encryptedVolumePath,
  );

String getZipPath(
  BackupLocation backupLocation,
  String zipDestination,
  Constants constants,
) =>
  path.join(
    zipDestination,
    '${backupLocation.name}${constants.zipEnding}',
  );

List<String> getBackupPaths(Constants constants) {
  return Directory(constants.backupDestination).listSync()
    .map((file) => file.path)
    .toList();
}

String getSubfolderBackupDestination(
  BackupLocation backupLocation,
  String backupDestination,
) {
  return path.join(
    backupDestination,
    backupLocation.name,
  );
}

Future<bool> _runProcessForPath(
  String path,
  String command,
  List<String> arguments,
  { int logLevel = 1 }
)
 async {
  if (FileSystemEntity.isDirectorySync(path)) {
    arguments = [ '-r', ...arguments ];
  }
  final result = await Process.run(command, arguments);
  final success = result.exitCode == 0;
  if (!success) {
    writeLog(
      'Command `$command ${arguments.join(' ')}` failed ❌\n\n'
      '${result.stderr.toString()}\n\n',
      logLevel: logLevel);
  }
  return success;
}

Future<bool> removePath(String path) =>
  _runProcessForPath(path, 'rm', [ path ]);

Future<bool> copyPath(String originalPath, String destinationPath) =>
  _runProcessForPath(originalPath, 'cp', [ originalPath, destinationPath ]);

Future<int> getFolderSize(String path) async {
  var folderSize = 0;
  final directory = Directory(path);
  for (final file in await directory.list(recursive: true).toList()) {
    folderSize += file.statSync().size;
  }
  return folderSize;
}

Future<int> getBackupSize(String backupPath) async {
  if (FileSystemEntity.isDirectorySync(backupPath)) {
    return getFolderSize(backupPath);
  } else {
    final file = File(backupPath);
    return file.length();
  }
}

Future<int> getFullBackupGiBs() async {
  final constants = await Constants.getInstance();
  var backupBytes = 0;
  for (final backupPath in getBackupPaths(constants)) {
    backupBytes += await getBackupSize(backupPath);
  }
  return (backupBytes / constants.gibBytes).ceil();
}

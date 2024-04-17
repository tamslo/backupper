import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;

import 'module.dart';

List<String> getBackupPaths(Constants constants) {
  return Directory(constants.backupDestination).listSync()
    .map((file) => file.path)
    .toList();
}

String getSubfolderBackupDestination(
  BackupLocation backupLocation,
  Constants constants,
) =>
  path.join(
    constants.backupDestination,
    backupLocation.name,
  );

Future<bool> runProcessForBackup(
  String backupPath,
  String command,
  List<String> arguments,
  { int logLevel = 1 }
)
 async {
  if (FileSystemEntity.isDirectorySync(backupPath)) {
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

Future<bool> cleanUpBackup(String backupPath) async {
  return await runProcessForBackup(backupPath, 'rm', [ backupPath ]);
}

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
    return await getFolderSize(backupPath);
  } else {
    final file = File(backupPath);
    return await file.length();
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

String getEncryptedPath(String zipPath, Constants constants) =>
  zipPath.replaceAll(
    constants.backupDestination,
    constants.encryptedVolumePath,
  );

Future<void> copyBackupsToEncryptedVolume() async {
  final constants = await Constants.getInstance();
  for (final backupPath in getBackupPaths(constants)) {
    writeLog('Encrypting $backupPath 🏃', logLevel: 1);
    final success = await runProcessForBackup(
      backupPath,
      'cp',
      [ backupPath, getEncryptedPath(backupPath, constants) ],
    );
    if (success) {
      writeLog('Encrypting $backupPath done ✅', logLevel: 1);
    }
  }
}

bool isIncludedInSubfolderWiseBackup(FileSystemEntity fileEntity) =>
  fileEntity is Directory && !path.basename(fileEntity.path).startsWith('.');

String getZipPath(
  BackupLocation backupLocation,
  String zipDestination,
  Constants constants,
) =>
  path.join(
    zipDestination,
    '${backupLocation.name}${constants.zipEnding}',
  );

Future<bool> createZip(
  BackupLocation backupLocation,
  String zipDestination,
  { int logLevel = 1 }
) async {
  final constants = await Constants.getInstance();
  var success = true;
  final destinationPath = getZipPath(backupLocation, zipDestination, constants);
  final backupPresent = await File(destinationPath).exists();
  if (backupPresent) {
    writeLog(
      'Backup for ${backupLocation.name} already exists ✅',
      logLevel: logLevel,
    );
    return success;
  }
  writeLog('Backing up ${backupLocation.name} 🏃', logLevel: logLevel);
  final encoder = ZipFileEncoder();
  encoder.create(destinationPath);
  try {
    await encoder.addDirectory(backupLocation.directory);
    writeLog('Back up of ${backupLocation.name} done ✅', logLevel: logLevel);
  } catch (e) {
    writeLog(
      '⛔️ Error while backing up ${backupLocation.name}\n\n'
      '${newLogLinePadding(logLevel: logLevel)}${e.toString()}\n\n'
      '${newLogLinePadding(logLevel: logLevel)}Removing ${destinationPath} 🧹',
      logLevel: logLevel,
    );
    if (File(destinationPath).existsSync()) File(destinationPath).deleteSync();
    success = false;
  }
  encoder.close();
  return success;
}

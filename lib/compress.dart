import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;

import 'module.dart';

Future<bool> compress(
  BackupLocation backupLocation,
  String backupDestination,
  { int logLevel = 1 }
) async {
  final constants = await Constants.getInstance();
  final folderSize = await getFolderSize(backupLocation.directory.path);
  if (folderSize > constants.compressionThreshold) {
    final prettyFolderSize =
      (folderSize / constants.gibBytes).toStringAsFixed(2);
    writeLog(
      'Backing up ${backupLocation.name} folder-wise '
      '($prettyFolderSize GiB) 🏃',
      logLevel: logLevel,
    );
    return compressContents(
      backupLocation,
      backupDestination,
      logLevel: logLevel + 1,
    );
  }
  var success = true;
  final destinationPath = getZipPath(
    backupLocation,
    backupDestination,
    constants,
  );
  final backupPresent = File(destinationPath).existsSync();
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
      '${newLogLinePadding(logLevel: logLevel)}Removing $destinationPath 🧹',
      logLevel: logLevel,
    );
    if (File(destinationPath).existsSync()) File(destinationPath).deleteSync();
    success = false;
  }
  encoder.close();
  return success;
}

Future<bool> compressContents(
  BackupLocation backupLocation,
  String backupDestination,
  { required int logLevel }
) async {
  final constants = await Constants.getInstance();
  final subfolderBackupDestination =
    getSubfolderBackupDestination(backupLocation, backupDestination);
  // Might still be present from earlier backups
  if (!Directory(subfolderBackupDestination).existsSync()) {
    Directory(subfolderBackupDestination).createSync();
  }
  var backupSuccess = true;
  for (final fileEntity in backupLocation.directory.listSync()) {
    if (fileEntity is! Directory) {
      final fileName = path.basename(fileEntity.path);
      if (constants.ignoredFiles.contains(fileName)) {
        writeLog('ℹ️  Ignoring $fileName', logLevel: logLevel);
        continue;
      }
      backupSuccess = await copyPath(
        fileEntity.path,
        path.join(subfolderBackupDestination, fileName,
      )) && backupSuccess;
      continue;
    }
    final subfolderBackupLocation = BackupLocation.fromPath(
      fileEntity.path,
      name: path.basename(fileEntity.path),
    );
    backupSuccess = await compress(
      subfolderBackupLocation,
      subfolderBackupDestination,
      logLevel: logLevel,
    ) && backupSuccess;
  }
  return backupSuccess;
}
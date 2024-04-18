import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;

import 'module.dart';

Future<bool> compress(
  BackupLocation backupLocation,
  String zipDestination,
  { int logLevel = 1 }
) async {
  final constants = await Constants.getInstance();
  // final folderSize = await getFolderSize(backupLocation.directory.path);
  // if (folderSize > constants.compressionThreshold) {
  //   return compressContents(backupLocation);
  // }
  var success = true;
  final destinationPath = getZipPath(backupLocation, zipDestination, constants);
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

Future<bool> compressContents(BackupLocation backupLocation) async {
  final constants = await Constants.getInstance();
  final subfolders = backupLocation.directory.listSync()
    .where(isIncludedInSubfolderWiseBackup);
  final ignoredFiles = backupLocation.directory.listSync()
    .where((fileEntity) => !isIncludedInSubfolderWiseBackup(fileEntity))
    .map((file) => path.basename(file.path));
  if (ignoredFiles.isNotEmpty) {
    writeLog(
      '⚠️  Warning: files in ${backupLocation.name} that are hidden or no '
      'directories will be ignored: ${ignoredFiles.join(', ')}',
      logLevel: 1,
    );
  }
  final subfolderBackupDestination =
    getSubfolderBackupDestination(backupLocation, constants);
  // Might still be present from earlier backups
  if (!Directory(subfolderBackupDestination).existsSync()) {
    Directory(subfolderBackupDestination).createSync();
  }
  var backupSuccess = true;
  for (final subfolder in subfolders) {
    final subfolderBackupLocation = BackupLocation.fromPath(
      subfolder.path,
      name: path.basename(subfolder.path),
    );
    backupSuccess = await compress(
      subfolderBackupLocation,
      subfolderBackupDestination,
      logLevel: 2,
    ) && backupSuccess;
  }
  return backupSuccess;
}
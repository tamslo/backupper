import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;

import 'module.dart';

Future<bool> move(
  BackupLocation backupLocation,
  String backupDestination,
  { int logLevel = 1 }
) async {
  final constants = await Constants.getInstance();
  var success = true;
  final destinationFilePath = getZipPath(
    backupLocation,
    backupDestination,
    constants,
  );
  final backupFilePresent = File(destinationFilePath).existsSync();
  if (backupFilePresent) {
    writeLog(
      'Backup for ${backupLocation.name} already exists ✅',
      logLevel: logLevel,
    );
    return success;
  }
  writeLog(
    'Calculating folder size for ${backupLocation.name} 🧮',
    logLevel: logLevel,
  );
  final folderSize = await getFolderSize(backupLocation.directory.path);
  final folderSizeInfo =
      '(${(folderSize / constants.gibBytes).toStringAsFixed(2)} GiB)';
  if (folderSize > constants.compressionThreshold) {
    writeLog(
      'Backing up ${backupLocation.name} folder-wise $folderSizeInfo  🏃',
      logLevel: logLevel,
    );
    return moveContents(
      backupLocation,
      backupDestination,
      logLevel: logLevel + 1,
    );
  }
  writeLog('Backing up ${backupLocation.name} $folderSizeInfo 🏃', logLevel: logLevel);
  final encoder = ZipFileEncoder();
  encoder.create(destinationFilePath);
  try {
    await encoder.addDirectory(backupLocation.directory);
    writeLog('Back up of ${backupLocation.name} done ✅', logLevel: logLevel);
  } catch (e) {
    writeLog(
      '⛔️ Error while backing up ${backupLocation.name}\n\n'
      '${newLogLinePadding(logLevel: logLevel)}${e.toString()}\n\n'
      '${newLogLinePadding(logLevel: logLevel)}Removing $destinationFilePath 🧹',
      logLevel: logLevel,
    );
    if (File(destinationFilePath).existsSync()) File(destinationFilePath).deleteSync();
    success = false;
  }
  encoder.close();
  return success;
}

Future<bool> moveContents(
  BackupLocation backupLocation,
  String backupDestination,
  { required int logLevel }
) async {
  final subfolderBackupDestination =
    getSubfolderBackupDestination(backupLocation, backupDestination);
  // Might still be present from earlier backups
  if (!Directory(subfolderBackupDestination).existsSync()) {
    Directory(subfolderBackupDestination).createSync();
  }
  var backupSuccess = true;
  for (final fileEntity in backupLocation.directory.listSync()) {
    final fileEntityName = path.basename(fileEntity.path);
    if (
      fileEntityName.startsWith('.') &&
      !fileEntityName.startsWith('.git') &&
      !fileEntityName.startsWith('.bash')
    ) {
      final fileEntityType = fileEntity.runtimeType.toString()
        .toLowerCase()
        .replaceAll('_', '');
      writeLog(
        'ℹ️  Ignoring $fileEntityType $fileEntityName',
        logLevel: logLevel,
      );
      continue;
    }
    if (fileEntity is! Directory) {
      backupSuccess = await copyPath(
        fileEntity.path,
        path.join(subfolderBackupDestination, fileEntityName,
      )) && backupSuccess;
      continue;
    }
    final subfolderBackupLocation = BackupLocation.fromPath(
      fileEntity.path,
      name: path.basename(fileEntity.path),
    );
    backupSuccess = await move(
      subfolderBackupLocation,
      subfolderBackupDestination,
      logLevel: logLevel,
    ) && backupSuccess;
  }
  return backupSuccess;
}
import 'dart:io';

import 'package:path/path.dart' as path;

import 'module.dart';

String _formatSizeInfo(Constants constants, int size) =>
  '(${(size / constants.gibBytes).toStringAsFixed(2)} GiB)';

Future<bool> _moveSingle({
  required String originPath,
  required String destinationPath,
  required Future<bool> Function(
    String originalPath,
    String destinationPath,
  ) moveSingle,
  int? originSize,
  required int logLevel,
}) async {
  final constants = await Constants.getInstance();
  final originName = path.basename(originPath);
  writeLog('Backing up $originName ${
    _formatSizeInfo(constants, originSize ?? File(originPath).statSync().size)
  } 🏃', logLevel: logLevel);
  final success = await moveSingle(originPath, destinationPath);
  if (success) {
    writeLog('Back up of $originName done ✅', logLevel: logLevel);
  } else {
    writeLog(
      '⛔️ Error while backing up $originName,'
      ' 🧹 removing $destinationPath',
      logLevel: logLevel,
    );
    if (File(destinationPath).existsSync()) File(destinationPath).deleteSync();
  }
  return success;
}

Future<bool> move(
  BackupLocation backupLocation,
  String backupDestination,
  { int logLevel = 1 }
) async {
  final constants = await Constants.getInstance();
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
    return true;
  }
  final backupFolderPresent = 
    Directory(
      getSubfolderBackupDestination(backupLocation, backupDestination)
    ).existsSync();

  Future<bool> moveCurrentContent() => moveContents(
    backupLocation,
    backupDestination,
    logLevel: logLevel + 1,
  );
  if (backupFolderPresent) {
    writeLog(
      'Continuing folder-wise backup for ${backupLocation.name} 🏃',
      logLevel: logLevel,
    );
    return moveCurrentContent();
  }
  writeLog(
    'Calculating folder size for ${backupLocation.name} 🧮',
    logLevel: logLevel,
  );
  final folderSize = await getFolderSize(backupLocation.directory.path);
  if (folderSize > constants.compressionThreshold) {
    writeLog(
      'Backing up ${backupLocation.name} folder-wise ${
        _formatSizeInfo(constants, folderSize)
      }  🏃',
      logLevel: logLevel,
    );
    return moveCurrentContent();
  }
  return _moveSingle(
    originPath: backupLocation.directory.path,
    destinationPath: destinationFilePath,
    moveSingle: zipPath,
    logLevel: logLevel,
    originSize: folderSize,
  );
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
    Directory(subfolderBackupDestination).createSync(recursive: true);
  }
  var backupSuccess = true;
  for (final fileEntity in backupLocation.directory.listSync()) {
    final fileEntityName = path.basename(fileEntity.path);
    if (
      (
        fileEntityName.startsWith('.') &&
        !fileEntityName.startsWith('.git') &&
        !fileEntityName.startsWith('.bash')
      ) ||
      fileEntityName == ('desktop.ini')
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
    if (fileEntity is Directory) {
      final subfolderBackupLocation = BackupLocation.fromPath(
      fileEntity.path,
      name: path.basename(fileEntity.path),
      );
      backupSuccess = await move(
        subfolderBackupLocation,
        subfolderBackupDestination,
        logLevel: logLevel,
      ) && backupSuccess;
      continue;
    }
    final fileDestinationPath = path.join(
      subfolderBackupDestination,
      fileEntityName,
    );
    if (File(fileDestinationPath).existsSync()) {
      writeLog(
        'Backup for $fileEntityName already exists ✅',
        logLevel: logLevel,
      );
      continue;
    }
    backupSuccess = await _moveSingle(
      originPath: fileEntity.path,
      destinationPath: fileDestinationPath,
      moveSingle: copyPath,
      logLevel: logLevel,
    ) && backupSuccess;
  }
  return backupSuccess;
}
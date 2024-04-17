import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:create_backup/module.dart';

Future<bool> backupSubfolderWise(BackupLocation backupLocation) async {
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
    backupSuccess = await createZip(
      subfolderBackupLocation,
      subfolderBackupDestination,
      logLevel: 2,
    ) && backupSuccess;
  }
  return backupSuccess;
}

void main(List<String> arguments) async {
  writeLog('Started backup 💽 🚀');
  final constants = await Constants.getInstance();
  var backupSuccess = true;
  for (final backupLocation in constants.backupLocations) {
    if (backupLocation.subfolderWise) {
      backupSuccess = await backupSubfolderWise(backupLocation)
        && backupSuccess;
    } else {
      backupSuccess =
        await createZip(backupLocation, constants.backupDestination)
        && backupSuccess;
    }
  }
  writeLog('Files backed up 💽 🏁');
  if (backupSuccess) {
    final fileSize = await getFullBackupGiBs();
    writeLog(
      '⏭️  To continue, an encrypted volume needs to be present:\n'
      '${newLogLinePadding()}'
      '1️⃣  Create an encrypted volume ${constants.dateStamp} with at least '
      '${fileSize.toString()} GiB 🔒, e.g., using VeraCrypt 🦊\n'
      '${newLogLinePadding()}'
      '2️⃣  Mount the volume as ${constants.encryptedVolumePath} (default when '
      'mounting with VeraCrypt) ⛰️\n'
      '${newLogLinePadding()}'
      '3️⃣  When you are done, run '
      '`dart /Volumes/Backup/create_backup/encrypt.dart` 📜',
    );
  } else {
    writeLog(
      '⛔️ However, errors are present; please fix the errors and try '
      'again to continue'
    );
  }
  exit(0);
}

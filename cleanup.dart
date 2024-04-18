import 'dart:io';

import 'package:create_backup/module.dart';

void main(List<String> arguments) async {
  writeLog('Started backup cleanup 🧹 🚀');
  final constants = await Constants.getInstance();
  final cleanupSuccesses = <bool>[];
  for (final backupPath in getBackupPaths(constants)) {
    final backupSize = await getBackupSize(backupPath);
    final copiedSize =
      await getBackupSize(getEncryptedPath(backupPath, constants));
    if (backupSize != copiedSize) {
      writeLog(
        'File sizes do not match for $backupPath; skipping cleanup 🧹 ❌',
        logLevel: 1,
      );
      cleanupSuccesses.add(false);
      continue;
    }
    writeLog('Cleaning up $backupPath 🧹', logLevel: 1);
    final success = await runProcessForBackup(backupPath, 'rm', [ backupPath ]);
    cleanupSuccesses.add(success);
  }
  Directory(constants.backupDestination).deleteSync();
  var logMessage = 'Cleanup done 🧹 🏁 ';
  if (cleanupSuccesses.any((result) => result == false)) {
    logMessage += 'however, errors are present; you might want to run the '
      'encryption again for failed checks or try moving files manually 🔁';
  } else {
    logMessage += 'you can dismount ${constants.encryptedVolumePath} and eject '
      '${constants.backupVolumePath} now ⏏️';
  }
  writeLog(logMessage);
  exit(0);
}

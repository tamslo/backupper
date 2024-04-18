import 'dart:io';

import 'package:create_backup/module.dart';

void main(List<String> arguments) async {
  writeLog(
    'Started backup encryption 🔒 🚀 by moving files to encrypted volume 📦',
  );
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
  writeLog(
    'Encryption done 🔒 📦 🏁 \n\n'
    '⏭️  To continue with sanity checks and the cleanup, run '
    '`bash start.sh cleanup <LOG_PATH>` 📜',
  );
  exit(0);
}

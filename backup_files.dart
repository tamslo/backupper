import 'dart:io';

import 'package:create_backup/module.dart';

void main(List<String> arguments) async {
  writeLog('Started backup 💽 🚀');
  final constants = await Constants.getInstance();
  var backupSuccess = true;
  for (final backupLocation in constants.backupLocations) {
  backupSuccess =
      await compress(backupLocation, constants.backupDestination)
      && backupSuccess;
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
      '`bash start.sh encrypt <LOG_PATH>` 📜',
    );
  } else {
    writeLog(
      '⛔️ However, errors are present; please fix the errors and try '
      'again to continue'
    );
  }
  exit(0);
}

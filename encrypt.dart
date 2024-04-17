import 'dart:io';

import 'package:create_backup/module.dart';

void main(List<String> arguments) async {
  writeLog(
    'Started backup encryption 🔒 🚀 by moving files to encrypted volume 📦',
  );
  await copyBackupsToEncryptedVolume();
  writeLog(
    'Encryption done 🔒 📦 🏁 \n\n'
    '⏭️  To continue with sanity checks and the cleanup, run `dart /Volumes/Backup/create_backup/cleanup.dart` 📜',
  );
  exit(0);
}

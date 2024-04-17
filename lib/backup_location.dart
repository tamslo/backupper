import 'dart:io';

class BackupLocation {
  BackupLocation.fromPath(
    String path,
    {
      required this.name,
      this.subfolderWise = false,
    }
  ) : directory = Directory(path);
  final Directory directory;
  final String name;
  final bool subfolderWise;
}
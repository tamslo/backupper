import 'dart:io';

class BackupLocation {
  BackupLocation.fromPath(
    String path,
    {
      required this.name,
    }
  ) : directory = Directory(path);
  final Directory directory;
  final String name;
}
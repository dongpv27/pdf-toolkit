import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// One PDF file produced by the app, with its size and last-modified time.
class StoredFile {
  const StoredFile({
    required this.file,
    required this.size,
    required this.modified,
  });

  final File file;
  final int size;
  final DateTime modified;

  String get path => file.path;
  String get name => file.path.split(RegExp(r'[\\/]')).last;
}

/// Lists, renames and deletes the PDF files the app has written to its own
/// documents directory. Fully offline; no storage permission required.
class FileStoreService {
  const FileStoreService();

  /// All `.pdf` files in the app documents directory, newest first.
  Future<List<StoredFile>> listPdfs() async {
    final dir = await getApplicationDocumentsDirectory();
    if (!dir.existsSync()) return const [];

    final files = <StoredFile>[];
    for (final entity in dir.listSync()) {
      if (entity is! File) continue;
      if (!entity.path.toLowerCase().endsWith('.pdf')) continue;
      final stat = entity.statSync();
      files.add(StoredFile(
        file: entity,
        size: stat.size,
        modified: stat.modified,
      ));
    }
    files.sort((a, b) => b.modified.compareTo(a.modified));
    return files;
  }

  Future<void> delete(StoredFile stored) async {
    if (await stored.file.exists()) await stored.file.delete();
  }

  /// Renames [stored] to [newName] (a `.pdf` suffix is added if missing).
  ///
  /// Throws [Exception] if a file with the target name already exists.
  Future<File> rename(StoredFile stored, String newName) async {
    var name = newName.trim();
    name = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '').trim();
    if (name.isEmpty) name = 'document';
    if (!name.toLowerCase().endsWith('.pdf')) name = '$name.pdf';

    final dir = stored.file.parent.path;
    final target = File('$dir/$name');
    if (target.path != stored.file.path && target.existsSync()) {
      throw Exception('A file named "$name" already exists.');
    }
    return stored.file.rename(target.path);
  }
}

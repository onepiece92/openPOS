import 'dart:io';

import 'package:path/path.dart' as p;

/// Whether [path] names a regular file directly inside [receiptsDir], after
/// symbolic links are resolved on both sides. A path with a `..` part, a
/// relative path, a link that leads elsewhere, a folder or a missing file
/// all answer false. Receipt photo paths come from the database, which a
/// restored backup may have crafted: nothing outside the receipts folder is
/// ever treated as a photo.
bool isReceiptPhotoFile(String path, Directory receiptsDir) {
  if (!p.isAbsolute(path)) return false;
  if (p.split(path).contains('..')) return false;
  try {
    if (FileSystemEntity.typeSync(path) != FileSystemEntityType.file) {
      return false;
    }
    final real = File(path).resolveSymbolicLinksSync();
    final dir = receiptsDir.resolveSymbolicLinksSync();
    return p.equals(p.dirname(real), dir);
  } on FileSystemException {
    return false;
  }
}

/// Deletes the receipt photo at [path] when it is one ([isReceiptPhotoFile]);
/// anything else is left alone. Returns whether a file was deleted. Never
/// throws.
Future<bool> deleteReceiptPhoto(String? path, Directory receiptsDir) async {
  if (path == null || !isReceiptPhotoFile(path, receiptsDir)) return false;
  try {
    await File(path).delete();
    return true;
  } on FileSystemException {
    return false;
  }
}

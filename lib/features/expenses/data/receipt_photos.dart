import 'dart:io';

import 'package:path/path.dart' as p;

/// The receipt photo [path] stands for on this device, or null when it
/// is not one. A stored path whose file is gone is looked for by its file
/// name in [receiptsDir] (iOS moves the app's container between installs,
/// so yesterday's absolute path no longer exists). Either way the answer
/// must be a regular file directly inside [receiptsDir], after symbolic
/// links are resolved on both sides: a path with a `..` part, a relative
/// path, a link that leads elsewhere, a folder or a missing file all give
/// null. Receipt photo paths come from the database, which a restored
/// backup may have crafted: nothing outside the receipts folder is ever
/// treated as a photo.
String? resolveReceiptPhoto(String path, Directory receiptsDir) {
  if (!p.isAbsolute(path)) return null;
  if (p.split(path).contains('..')) return null;
  var candidate = path;
  try {
    if (FileSystemEntity.typeSync(path, followLinks: false) ==
        FileSystemEntityType.notFound) {
      final name = path.split(RegExp(r'[/\\]')).last;
      if (name.isEmpty || name == '.' || name == '..') return null;
      candidate = p.join(receiptsDir.path, name);
    }
    if (FileSystemEntity.typeSync(candidate) != FileSystemEntityType.file) {
      return null;
    }
    final real = File(candidate).resolveSymbolicLinksSync();
    final dir = receiptsDir.resolveSymbolicLinksSync();
    return p.equals(p.dirname(real), dir) ? candidate : null;
  } on FileSystemException {
    return null;
  }
}

/// Whether [path] is a receipt photo on this device ([resolveReceiptPhoto]).
bool isReceiptPhotoFile(String path, Directory receiptsDir) =>
    resolveReceiptPhoto(path, receiptsDir) != null;

/// Deletes the receipt photo [path] stands for ([resolveReceiptPhoto]);
/// anything else is left alone. Returns whether a file was deleted. Never
/// throws.
Future<bool> deleteReceiptPhoto(String? path, Directory receiptsDir) async {
  final photo = path == null ? null : resolveReceiptPhoto(path, receiptsDir);
  if (photo == null) return false;
  try {
    await File(photo).delete();
    return true;
  } on FileSystemException {
    return false;
  }
}

/// Copies a photo the picker returned into [receiptsDir] under [name] and
/// returns the copy's path. The picker's own file is deleted afterwards when
/// it is a temporary copy inside [tempDir] (camera shots and gallery picks
/// on phones); a file anywhere else — the original photo a desktop picker
/// hands back — is never touched.
Future<String> importPickedPhoto(String pickedPath, Directory receiptsDir,
    {required Directory tempDir, required String name}) async {
  if (!await receiptsDir.exists()) await receiptsDir.create(recursive: true);
  final dest = p.join(receiptsDir.path, name);
  await File(pickedPath).copy(dest);
  if (_isInside(pickedPath, tempDir)) {
    try {
      await File(pickedPath).delete();
    } on FileSystemException {/* the OS clears its cache later */}
  }
  return dest;
}

bool _isInside(String path, Directory dir) {
  if (!p.isAbsolute(path) || p.split(path).contains('..')) return false;
  try {
    final real = File(path).resolveSymbolicLinksSync();
    return p.isWithin(dir.resolveSymbolicLinksSync(), real);
  } on FileSystemException {
    return false;
  }
}

/// The receipt photo of an expense while its form is open. The saved photo
/// is only deleted once the change is written ([committed]); a photo picked
/// in the form and not kept is deleted when it is replaced or removed, or
/// when the form is left without saving ([discard]).
class ReceiptPhotoDraft {
  ReceiptPhotoDraft({required this.saved, required this.receiptsDir})
      : current = saved;

  /// The photo the expense has in the database.
  final String? saved;
  final Directory receiptsDir;

  /// The photo the form shows (and would save).
  String? current;

  /// Photos copied into receipts/ by this form, not yet saved.
  final Set<String> _picked = {};
  bool _done = false;
  bool _saving = false;

  /// The expense is being written with [current]: until [committed] or
  /// [saveFailed], leaving the form ([discard]) deletes nothing — the row
  /// may be about to point at the picked photo.
  void beginSave() => _saving = true;

  /// The write failed: the form may be left (or saved again) as before.
  void saveFailed() => _saving = false;

  /// A new photo [path] (already in receipts/) replaces the current one.
  Future<void> pick(String path) async {
    final previous = current;
    _picked.add(path);
    current = path;
    // An unsaved pick that is replaced is never needed again.
    if (previous != null && _picked.remove(previous)) {
      await deleteReceiptPhoto(previous, receiptsDir);
    }
  }

  /// The photo is removed from the form (the saved one stays until saved).
  Future<void> remove() async {
    final previous = current;
    current = null;
    if (previous != null && _picked.remove(previous)) {
      await deleteReceiptPhoto(previous, receiptsDir);
    }
  }

  /// The expense was written with [current]: the saved photo it replaced
  /// is deleted.
  Future<void> committed() async {
    _done = true;
    _saving = false;
    _picked.clear();
    if (saved != null && saved != current) {
      await deleteReceiptPhoto(saved, receiptsDir);
    }
  }

  /// The expense was deleted: its saved photo and any picked one go.
  Future<void> expenseDeleted() async {
    _done = true;
    final all = {
      if (saved != null) saved!,
      if (current != null) current!,
      ..._picked,
    };
    _picked.clear();
    for (final path in all) {
      await deleteReceiptPhoto(path, receiptsDir);
    }
  }

  /// The form was left without saving: photos picked in it are deleted,
  /// the saved photo is kept.
  Future<void> discard() async {
    if (_done || _saving) return;
    _done = true;
    final picked = [..._picked];
    _picked.clear();
    for (final path in picked) {
      if (path != saved) await deleteReceiptPhoto(path, receiptsDir);
    }
  }
}

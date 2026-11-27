import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:pos_app/features/expenses/data/receipt_photos.dart';

/// The expense form's photo: the saved file survives until the change is
/// written, and photos picked but not kept are cleaned up.
void main() {
  late Directory tmp;
  late Directory receipts;
  late Directory pickerTemp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pos_photo_draft_');
    receipts = await Directory(p.join(tmp.path, 'receipts')).create();
    pickerTemp = await Directory(p.join(tmp.path, 'cache')).create();
  });

  tearDown(() => tmp.delete(recursive: true));

  File file(Directory dir, String name) =>
      File(p.join(dir.path, name))..writeAsStringSync(name);

  test('replacing the photo, then cancelling, keeps the saved photo and '
      'deletes the new one', () async {
    final saved = file(receipts, 'saved.jpg');
    final d = ReceiptPhotoDraft(saved: saved.path, receiptsDir: receipts);
    final picked = file(receipts, 'new.jpg');
    await d.pick(picked.path);
    expect(saved.existsSync(), isTrue, reason: 'not saved yet');
    await d.discard();
    expect(saved.existsSync(), isTrue);
    expect(picked.existsSync(), isFalse);
  });

  test('removing the photo, then cancelling, keeps the saved photo', () async {
    final saved = file(receipts, 'saved.jpg');
    final d = ReceiptPhotoDraft(saved: saved.path, receiptsDir: receipts);
    await d.remove();
    expect(d.current, isNull);
    await d.discard();
    expect(saved.existsSync(), isTrue);
  });

  test('replacing the photo and saving deletes the old one only then',
      () async {
    final saved = file(receipts, 'saved.jpg');
    final d = ReceiptPhotoDraft(saved: saved.path, receiptsDir: receipts);
    final first = file(receipts, 'first.jpg');
    final second = file(receipts, 'second.jpg');
    await d.pick(first.path);
    await d.pick(second.path);
    expect(first.existsSync(), isFalse, reason: 'an unsaved pick replaced');
    expect(saved.existsSync(), isTrue);
    await d.committed();
    expect(saved.existsSync(), isFalse);
    expect(second.existsSync(), isTrue);
    await d.discard(); // the form closes after saving
    expect(second.existsSync(), isTrue);
  });

  test('removing the photo and saving deletes the saved one', () async {
    final saved = file(receipts, 'saved.jpg');
    final d = ReceiptPhotoDraft(saved: saved.path, receiptsDir: receipts);
    await d.remove();
    await d.committed();
    expect(saved.existsSync(), isFalse);
  });

  test('a new expense: a picked photo is deleted on cancel, kept on save',
      () async {
    final a = file(receipts, 'a.jpg');
    final cancelled = ReceiptPhotoDraft(saved: null, receiptsDir: receipts);
    await cancelled.pick(a.path);
    await cancelled.discard();
    expect(a.existsSync(), isFalse);

    final b = file(receipts, 'b.jpg');
    final kept = ReceiptPhotoDraft(saved: null, receiptsDir: receipts);
    await kept.pick(b.path);
    await kept.committed();
    await kept.discard();
    expect(b.existsSync(), isTrue);
  });

  test('deleting the expense deletes its saved and picked photos', () async {
    final saved = file(receipts, 'saved.jpg');
    final picked = file(receipts, 'new.jpg');
    final d = ReceiptPhotoDraft(saved: saved.path, receiptsDir: receipts);
    await d.pick(picked.path);
    await d.expenseDeleted();
    expect(saved.existsSync(), isFalse);
    expect(picked.existsSync(), isFalse);
  });

  group('importPickedPhoto', () {
    test("copies into receipts/ and deletes the picker's temp file",
        () async {
      final shot = file(pickerTemp, 'image_picker_123.jpg');
      final dest = await importPickedPhoto(shot.path, receipts,
          tempDir: pickerTemp, name: 'x.jpg');
      expect(dest, p.join(receipts.path, 'x.jpg'));
      expect(File(dest).readAsStringSync(), 'image_picker_123.jpg');
      expect(shot.existsSync(), isFalse);
    });

    test('never deletes an original outside the temp folder', () async {
      final original =
          file(await Directory(p.join(tmp.path, 'Pictures')).create(), 'o.jpg');
      await importPickedPhoto(original.path, receipts,
          tempDir: pickerTemp, name: 'y.jpg');
      expect(original.existsSync(), isTrue);
      expect(File(p.join(receipts.path, 'y.jpg')).existsSync(), isTrue);
    });
  });
}

import 'dart:ui' show Rect;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Hands files to the OS share sheet.
///
/// [sharePositionOrigin] is required on purpose: on iPad share_plus fails
/// the share when it is missing or empty, so no caller may leave it out.
/// The presentation layer works it out from the tapped widget
/// (`shareOriginFor`) and passes it down as a plain [Rect].
typedef ShareFiles = Future<void> Function(
  List<XFile> files, {
  String? subject,
  String? text,
  required Rect sharePositionOrigin,
});

Future<void> shareFilesWithOs(
  List<XFile> files, {
  String? subject,
  String? text,
  required Rect sharePositionOrigin,
}) =>
    Share.shareXFiles(
      files,
      subject: subject,
      text: text,
      sharePositionOrigin: sharePositionOrigin,
    );

/// Overridden in tests to capture what would have been shared.
final shareFilesProvider = Provider<ShareFiles>((ref) => shareFilesWithOs);

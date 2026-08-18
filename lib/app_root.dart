import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/app.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/connection/native.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/features/backup/data/snapshot_providers.dart';
import 'package:pos_app/features/backup/data/snapshot_service.dart';

/// Owns the Riverpod container so the whole app can be hot-restarted —
/// needed to restore a backup: close DB + Hive, swap files on disk, then
/// bring everything back up on the restored data.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  static AppRootState of(BuildContext context) =>
      context.findAncestorStateOfType<AppRootState>()!;

  @override
  State<AppRoot> createState() => AppRootState();
}

class AppRootState extends State<AppRoot> {
  ProviderContainer _container = ProviderContainer();
  bool _restoring = false;
  String? _notice; // one-shot toast shown after a restart

  @override
  void initState() {
    super.initState();
    // Daily local snapshot — off the first frame so launch isn't delayed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
          _container.read(snapshotCoordinatorProvider).runAutoBackupIfDue());
    });
  }

  @override
  void dispose() {
    _container.dispose();
    super.dispose();
  }

  /// Restores [zip] and restarts the app on the restored data.
  /// Throws [SnapshotFormatException] (or IO errors) if the file is rejected;
  /// in that case the app comes back up on its previous data.
  Future<void> restoreFrom(File zip) async {
    if (_restoring) return;
    // Resolve paths while Hive is still open (box.path needs an open box).
    final dbFile = await databaseFile();
    final hiveFiles = snapshotHiveBoxFiles();

    // 1. Unmount the app tree so no widget can issue queries mid-swap.
    setState(() => _restoring = true);
    await WidgetsBinding.instance.endOfFrame;

    Object? error;
    try {
      // 2. Release both stores.
      await _container.read(databaseProvider).close();
      _container.dispose();
      await Hive.close();

      // 3. Swap files (atomic per file).
      await const SnapshotService().restore(
        zip: zip,
        dbFile: dbFile,
        hiveBoxFiles: hiveFiles,
        currentSchemaVersion: AppDatabase.currentSchemaVersion,
      );
    } catch (e) {
      error = e;
    } finally {
      // 4. Bring everything back — on the restored data, or the old data if
      //    the restore was rejected before it touched anything.
      for (final name in kSnapshotHiveBoxes) {
        await Hive.openBox<dynamic>(name);
      }
      _container = ProviderContainer();
      if (mounted) {
        setState(() {
          _restoring = false;
          _notice = error == null
              ? 'Backup restored'
              : 'Restore failed: $error';
        });
      }
    }
    if (error != null) throw error;
  }

  @override
  Widget build(BuildContext context) {
    if (_restoring) return const _RestoringSplash();
    return UncontrolledProviderScope(
      // New key per container → subtree is rebuilt from scratch on restart.
      key: ObjectKey(_container),
      container: _container,
      child: _notice == null
          ? const POSApp()
          : _NoticeOverlay(
              message: _notice!,
              onDone: () => setState(() => _notice = null),
              child: const POSApp(),
            ),
    );
  }
}

class _RestoringSplash extends StatelessWidget {
  const _RestoringSplash();

  @override
  Widget build(BuildContext context) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Restoring backup…'),
              ],
            ),
          ),
        ),
      );
}

/// Bottom toast rendered *above* the MaterialApp (which is being recreated,
/// so a ScaffoldMessenger from before the restart no longer exists).
class _NoticeOverlay extends StatefulWidget {
  const _NoticeOverlay({
    required this.message,
    required this.onDone,
    required this.child,
  });
  final String message;
  final VoidCallback onDone;
  final Widget child;

  @override
  State<_NoticeOverlay> createState() => _NoticeOverlayState();
}

class _NoticeOverlayState extends State<_NoticeOverlay> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 4), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            widget.child,
            Positioned(
              left: 16,
              right: 16,
              bottom: 32,
              child: SafeArea(
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF1F2933),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Text(
                      widget.message,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

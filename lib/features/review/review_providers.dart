import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/app_version.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/review/application/review_controller.dart';
import 'package:pos_app/features/review/data/noop_review_prompter.dart';
import 'package:pos_app/features/review/data/review_state_store.dart';
import 'package:pos_app/features/review/data/store_review_prompter.dart';
import 'package:pos_app/features/review/domain/review_policy.dart';
import 'package:pos_app/features/review/domain/review_prompter.dart';

/// True on iOS and Android, where a store listing exists. The "Rate Open POS"
/// row and the automatic request are hidden/no-ops everywhere else.
bool get storeReviewSupported =>
    !kIsWeb && (Platform.isIOS || Platform.isAndroid);

final reviewPrompterProvider = Provider<ReviewPrompter>((ref) =>
    storeReviewSupported ? StoreReviewPrompter() : const NoopReviewPrompter());

final reviewControllerProvider = Provider<ReviewController>((ref) =>
    ReviewController(
      store: ReviewStateStore(ref.watch(settingsBoxProvider)),
      prompter: ref.watch(reviewPrompterProvider),
      // Read lazily, per check, so the controller never opens the database
      // by itself being created.
      completedSales: () => ref
          .read(databaseProvider)
          .ordersDao
          .completedOrderCount(upTo: kReviewMinCompletedSales),
      appVersion: kAppVersionFull,
    ));

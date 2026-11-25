import 'package:pos_app/features/review/domain/review_prompter.dart';

/// Used on macOS, Windows, Linux and in tests: never asks, opens nothing.
class NoopReviewPrompter implements ReviewPrompter {
  const NoopReviewPrompter();

  @override
  Future<bool> maybeRequestReview() async => false;

  @override
  Future<void> openStoreListing({required String appStoreId}) async {}
}

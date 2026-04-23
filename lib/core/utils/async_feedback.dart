import 'package:flutter/material.dart';

/// Runs [operation] and surfaces failures as a SnackBar instead of letting
/// them disappear into the void.
///
/// - On success: returns the operation's result (or the result of the future).
///   If [successMessage] is provided, shows it.
/// - On failure: catches the exception, shows an error SnackBar, returns null.
///
/// Intended for user-initiated write operations (form saves, inventory
/// adjustments, refunds) where silent failure = lost work or confused operator.
///
/// Captures `ScaffoldMessenger.of(context)` before the await so a post-await
/// rebuild can't make the context stale.
Future<T?> withErrorSnackbar<T>(
  BuildContext context,
  Future<T> Function() operation, {
  String? successMessage,
  String failurePrefix = 'Failed',
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final cs = Theme.of(context).colorScheme;
  try {
    final result = await operation();
    if (successMessage != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    }
    return result;
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('$failurePrefix: $e'),
        backgroundColor: cs.errorContainer,
      ),
    );
    return null;
  }
}

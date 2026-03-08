import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emits the latest list of connectivity results whenever the network changes.
/// connectivity_plus 6.x returns List<ConnectivityResult>.
final connectivityStreamProvider =
    StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// True if at least one active network interface is available.
/// Defaults to true (optimistic) while the first stream event is pending.
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityStreamProvider).maybeWhen(
        data: (results) =>
            results.any((r) => r != ConnectivityResult.none),
        orElse: () => true,
      );
});

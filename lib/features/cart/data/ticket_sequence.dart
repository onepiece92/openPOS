import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/features/cart/domain/held_order.dart';

/// The `held_orders` box stores one JSON-encoded `HeldOrder` per ticket id,
/// plus a single reserved key holding the monotonic ticket counter.
final heldOrdersBoxProvider = Provider<Box<dynamic>>((ref) {
  return Hive.box<dynamic>('held_orders');
});

/// Reserved key inside the `held_orders` box — skipped when loading tickets.
const kTicketSeqKey = '__ticket_seq';

/// Renders a raw sequence value the way tickets are displayed: `#0042`.
String formatTicketNumber(int seq) => '#${seq.toString().padLeft(4, '0')}';

/// Hands out ticket numbers that only ever climb — a number is never reused,
/// so two tickets can never share one and editing a ticket never renumbers it.
///
/// The counter lives in the same Hive box as the tickets themselves. Both are
/// in [kSnapshotHiveBoxes], so a backup restore always carries the counter and
/// the tickets it belongs to together — restoring can't resurrect a spent
/// number.
class TicketSequence {
  TicketSequence(this._box);

  final Box<dynamic> _box;

  /// Highest number handed out so far. Boxes written by builds that predate
  /// the counter have no key, so the existing tickets are scanned once to
  /// find the high-water mark rather than restarting from zero.
  int get _highWaterMark {
    final raw = _box.get(kTicketSeqKey);
    if (raw is int) return raw;
    var max = 0;
    for (final entry in _box.toMap().entries) {
      if (entry.key == kTicketSeqKey) continue;
      final value = entry.value;
      if (value is! String) continue;
      try {
        // Decoded through HeldOrder so pre-counter rows go through the same
        // legacy-number rule the rest of the app sees.
        final ticket =
            HeldOrder.fromJson(jsonDecode(value) as Map<String, dynamic>);
        final parsed = int.tryParse(
            ticket.ticketNumber.replaceAll(RegExp(r'[^0-9]'), ''));
        if (parsed != null && parsed > max) max = parsed;
      } catch (_) {
        // Unparseable rows are ignored — the counter only needs the maximum.
      }
    }
    return max;
  }

  /// Consumes and returns the next number.
  String next() {
    final seq = _highWaterMark + 1;
    _box.put(kTicketSeqKey, seq);
    return formatTicketNumber(seq);
  }
}

final ticketSequenceProvider = Provider<TicketSequence>(
  (ref) => TicketSequence(ref.watch(heldOrdersBoxProvider)),
);

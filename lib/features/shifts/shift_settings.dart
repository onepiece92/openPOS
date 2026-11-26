import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/providers/hive_provider.dart';

/// The ONE gate for the end-of-day close: the drawer item, the
/// `/close-day` routes (redirected to /pos when off) and every screen read
/// this and nothing else. It is the effective [Feature.endOfDay] switch
/// (Features screen), default off, and rebuilds whenever the switches
/// change.
final endOfDayEnabledProvider =
    Provider<bool>((ref) => ref.watch(featureFlagsProvider).endOfDay);

/// The route prefix every close-day screen lives under.
const kCloseDayRoute = '/close-day';
const kCloseDayHistoryRoute = '/close-day/history';

import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:go_router/go_router.dart';

import 'package:pos_app/features/usage/data/usage_counter.dart';

/// The route template (e.g. `/orders/:id`) and location of the screen on
/// top. `RouteMatchList.fullPath` leaves out routes opened with `push`
/// (they are [ImperativeRouteMatch]es), so the LAST match is used: for a
/// pushed route, the template of the match list it was pushed with.
({String? template, String? location}) topRouteOf(RouteMatchList config) {
  final last = config.lastOrNull;
  if (last == null) return (template: null, location: null);
  if (last is ImperativeRouteMatch) {
    return (template: last.matches.fullPath, location: last.matchedLocation);
  }
  return (template: config.fullPath, location: last.matchedLocation);
}

/// Counts a screen opening on every navigation of [router] (go, push and
/// pop alike): one synchronous map update. Returns the detach callback.
VoidCallback attachUsageRouteCounter(GoRouter router, UsageCounter usage) {
  void onNavigate() {
    final top = topRouteOf(router.routerDelegate.currentConfiguration);
    usage.recordRoute(top.template, location: top.location);
  }

  router.routerDelegate.addListener(onNavigate);
  return () => router.routerDelegate.removeListener(onNavigate);
}

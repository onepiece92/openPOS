import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/features/help/presentation/support_screen.dart';
import 'package:pos_app/features/review/review_providers.dart';
import 'package:pos_app/features/usage/usage_constants.dart';

void main() {
  testWidgets(
      'rows: WhatsApp, Email, feedback, Rate, licences; RebuzzPOS card; '
      'the old bug / feature / docs / ordering rows are gone', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: SupportScreen()),
    ));

    final expected = [
      'WhatsApp Chat',
      'Email Support',
      kFeedbackSupportRowTitle,
      if (storeReviewSupported) 'Rate Open POS',
      'Open-source licences',
    ];
    final titles = [
      for (final t in tester.widgetList<ListTile>(find.byType(ListTile)))
        (t.title! as Text).data!,
    ];
    expect(titles, expected);
    expect(find.text('RebuzzPOS'), findsOneWidget);
    expect(find.text('Documentation'), findsNothing);
    expect(find.text('Ordering App'), findsNothing);
    expect(find.text('Report a Bug'), findsNothing);
    expect(find.text('Request a Feature'), findsNothing);
    // The email address is unchanged.
    expect(find.text('support@rebuzzpos.com'), findsOneWidget);
  });
}

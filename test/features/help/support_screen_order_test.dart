import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/features/help/presentation/support_screen.dart';
import 'package:pos_app/features/review/review_providers.dart';
import 'package:pos_app/features/usage/usage_constants.dart';

void main() {
  testWidgets(
      'Contact and Resources rows: WhatsApp, Email, feedback, Rate, '
      'Documentation; the old bug / feature rows are gone', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: SupportScreen()),
    ));

    final expected = [
      'WhatsApp Chat',
      'Email Support',
      kFeedbackSupportRowTitle,
      if (storeReviewSupported) 'Rate Open POS',
      'Documentation',
    ];
    final titles = [
      for (final t in tester.widgetList<ListTile>(find.byType(ListTile)))
        (t.title! as Text).data!,
    ];
    expect(titles.take(expected.length).toList(), expected);
    expect(find.text('Report a Bug'), findsNothing);
    expect(find.text('Request a Feature'), findsNothing);
    // The email address is unchanged.
    expect(find.text('support@rebuzzpos.com'), findsOneWidget);
  });
}

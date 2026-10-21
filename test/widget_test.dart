import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moodiary/main.dart';

void main() {
  testWidgets('logs a mood and shows it in the timeline',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoodiaryApp()));
    await tester.pumpAndSettle();

    expect(find.text('How are you feeling?'), findsOneWidget);
    expect(find.text('No moods yet — tap a face above to log one.'),
        findsOneWidget);

    // Tap Happy face to open note dialog
    await tester.tap(find.text('Happy'));
    await tester.pump();

    // Dismiss the dialog by tapping Log (empty note)
    await tester.tap(find.text('Log'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('logs a mood with a note and displays it in timeline',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoodiaryApp()));
    await tester.pumpAndSettle();

    // Tap Happy face to open note dialog
    await tester.tap(find.text('Happy'));
    await tester.pump();

    // Enter a note in the text field
    await tester.enterText(find.byType(TextField), 'Had a great day!');
    await tester.pump();

    // Tap Log button to confirm
    await tester.tap(find.text('Log'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify the note is displayed in the timeline card
    expect(find.text('Had a great day!'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });
}

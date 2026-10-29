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

    // Tap Happy face to open prompt selector dialog
    await tester.tap(find.text('Happy'));
    await tester.pump();

    // Pick the first prompt
    await tester.tap(find.text('What made today a great day?'));
    await tester.pump();

    // Skip triggers
    await tester.tap(find.text('Skip'));
    await tester.pump();

    // Log with empty note and response
    await tester.tap(find.text('Log'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('logs a mood with a note and displays it in timeline',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoodiaryApp()));
    await tester.pumpAndSettle();

    // Tap Happy face to open prompt selector dialog
    await tester.tap(find.text('Happy'));
    await tester.pump();

    // Pick the first prompt
    await tester.tap(find.text('What made today a great day?'));
    await tester.pump();

    // Skip triggers
    await tester.tap(find.text('Skip'));
    await tester.pump();

    // Enter a note in the note field (the second TextField)
    await tester.enterText(
      find.byType(TextField).at(1),
      'Had a great day!',
    );
    await tester.pump();

    // Tap Log button to confirm
    await tester.tap(find.text('Log'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify the note is displayed in the timeline card
    expect(find.text('Had a great day!'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('logs a mood with triggers and shows them in timeline',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoodiaryApp()));
    await tester.pumpAndSettle();

    // Tap Happy face to open prompt selector dialog
    await tester.tap(find.text('Happy'));
    await tester.pump();

    // Pick the first prompt
    await tester.tap(find.text('What made today a great day?'));
    await tester.pump();

    // Select a trigger: Sleep
    await tester.tap(find.text('Sleep'));
    await tester.pump();

    // Continue with triggers
    await tester.tap(find.text('Continue (1)'));
    await tester.pump();

    // Log with empty note and response
    await tester.tap(find.text('Log'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify the trigger is displayed in the timeline card
    expect(find.text('Sleep'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });
}

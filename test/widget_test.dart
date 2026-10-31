import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moodiary/main.dart';

Future<void> _logMood(WidgetTester tester,
    {String note = '', bool withTrigger = false}) async {
  // Tap Happy face to open prompt selector dialog
  await tester.tap(find.text('Happy'));
  await tester.pump();

  // Pick the first prompt
  await tester.tap(find.text('What made today a great day?'));
  await tester.pump();

  // Handle triggers
  if (withTrigger) {
    await tester.tap(find.text('Sleep'));
    await tester.pump();
    await tester.tap(find.text('Continue (1)'));
    await tester.pump();
  } else {
    await tester.tap(find.text('Skip'));
    await tester.pump();
  }

  // Fill the note field (second TextField) if provided
  if (note.isNotEmpty) {
    await tester.enterText(find.byType(TextField).at(1), note);
    await tester.pump();
  }

  // Tap Log button to confirm
  await tester.tap(find.text('Log'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('logs a mood and shows it in the timeline',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoodiaryApp()));
    await tester.pumpAndSettle();

    expect(find.text('How are you feeling?'), findsOneWidget);
    expect(find.text('No moods yet — tap a face above to log one.'),
        findsOneWidget);

    await _logMood(tester);

    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('logs a mood with a note and displays it in timeline',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoodiaryApp()));
    await tester.pumpAndSettle();

    await _logMood(tester, note: 'Had a great day!');

    // Verify the note is displayed in the timeline card
    expect(find.text('Had a great day!'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('logs a mood with triggers and shows them in timeline',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoodiaryApp()));
    await tester.pumpAndSettle();

    await _logMood(tester, withTrigger: true);

    // Verify the trigger is displayed in the timeline card
    expect(find.text('Sleep'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('edits a logged entry via the timeline',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoodiaryApp()));
    await tester.pumpAndSettle();

    await _logMood(tester, note: 'Original note');

    // Open the edit dialog from the timeline card
    await tester.tap(find.byTooltip('Edit entry'));
    await tester.pump();

    // Change the note
    await tester.enterText(find.byType(TextField), 'Edited note');
    await tester.pump();

    // Save
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Edited note'), findsOneWidget);
    expect(find.text('Original note'), findsNothing);
  });

  testWidgets('deletes a logged entry via the timeline',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoodiaryApp()));
    await tester.pumpAndSettle();

    await _logMood(tester, note: 'To be deleted');
    expect(find.text('To be deleted'), findsOneWidget);

    // Trigger the delete confirmation
    await tester.tap(find.byTooltip('Delete entry'));
    await tester.pump();

    // Confirm deletion
    await tester.tap(find.text('Delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('To be deleted'), findsNothing);
  });
}

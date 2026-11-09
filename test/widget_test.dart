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

  testWidgets('shows goal progress and nudge banner on the log tab',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoodiaryApp()));
    await tester.pumpAndSettle();

    // Before logging: the nudge banner is visible, goal is at 0 of 1.
    expect(find.text('Thinking of you'), findsOneWidget);
    expect(find.text('Daily goal'), findsOneWidget);

    // Log a mood — the nudge should disappear and the goal should be met.
    await _logMood(tester);
    expect(find.text('Thinking of you'), findsNothing);
    expect(find.text('Goal reached!'), findsOneWidget);
  });

  testWidgets('shows mood forecast on the log tab',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoodiaryApp()));
    await tester.pumpAndSettle();

    // Log a mood so the forecast has data to work with.
    await _logMood(tester, note: 'Forecast test');

    // The forecast card should now show a concrete label.
    expect(find.text('Today\'s forecast'), findsOneWidget);
    expect(find.text('Trending up'), findsOneWidget);
  });

  testWidgets('shows forecast accuracy card on the log tab',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoodiaryApp()));
    await tester.pumpAndSettle();

    // Log a mood so the forecast (and accuracy tracker) have data.
    await _logMood(tester, note: 'Accuracy test');

    // The accuracy card should render with its heading.
    expect(find.text('Forecast accuracy'), findsOneWidget);
    // The calibration strip label should also be present.
    expect(find.textContaining('forecast'), findsWidgets);
  });

  testWidgets('shows highlights card in the journal tab',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoodiaryApp()));
    await tester.pumpAndSettle();

    // Log a mood so highlights have data.
    await _logMood(tester, note: 'Highlight test', withTrigger: true);

    // Switch to the Journal tab.
    await tester.tap(find.text('Journal'));
    await tester.pumpAndSettle();

    // The highlights card should appear with its heading.
    expect(find.text('Your Highlights'), findsOneWidget);
    expect(find.textContaining('-day streak'), findsOneWidget);
  });

  testWidgets('filters journal entries by mood',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoodiaryApp()));
    await tester.pumpAndSettle();

    // Log one Happy with a note, one Sad with a different note.
    await _logMood(tester, note: 'Happy note', withTrigger: true);
    await _logMood(tester, note: 'Sad note', withTrigger: true);

    // Switch to the Journal tab.
    await tester.tap(find.text('Journal'));
    await tester.pumpAndSettle();

    // Both notes visible initially.
    expect(find.text('Happy note'), findsOneWidget);
    expect(find.text('Sad note'), findsOneWidget);

    // Tap the "Sad" mood chip to filter.
    await tester.tap(find.text('Sad'));
    await tester.pumpAndSettle();

    // Only the Sad entry should remain.
    expect(find.text('Happy note'), findsNothing);
    expect(find.text('Sad note'), findsOneWidget);

    // Clear all.
    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();

    expect(find.text('Happy note'), findsOneWidget);
    expect(find.text('Sad note'), findsOneWidget);
  });

  testWidgets('shows mood recovery patterns in the journal tab',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoodiaryApp()));
    await tester.pumpAndSettle();

    // Log 5 moods with a trigger so transitions are computable.
    for (int i = 0; i < 5; i++) {
      await _logMood(tester, note: 'Recov $i', withTrigger: true);
    }

    // Switch to the Journal tab.
    await tester.tap(find.text('Journal'));
    await tester.pumpAndSettle();

    // The recovery card should appear with its heading.
    expect(find.text('Mood Recovery Patterns'), findsOneWidget);
  });

  testWidgets('shows trigger insights in the journal tab',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoodiaryApp()));
    await tester.pumpAndSettle();

    // Log 5 Happy moods with the Sleep trigger so the pattern is detectable.
    for (int i = 0; i < 5; i++) {
      await _logMood(tester, note: 'Recap $i', withTrigger: true);
    }

    // Switch to the Journal tab.
    await tester.tap(find.text('Journal'));
    await tester.pumpAndSettle();

    // The insights card should surface the Sleep pattern.
    expect(find.text('Your Patterns'), findsOneWidget);
    expect(find.textContaining('Days with Sleep lift your mood'),
        findsOneWidget);
  });

  testWidgets('shows weekly recap in the journal tab',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoodiaryApp()));
    await tester.pumpAndSettle();

    // Log a mood with a trigger so the recap has data to show.
    await _logMood(tester, note: 'Recap test', withTrigger: true);

    // Switch to the Journal tab.
    await tester.tap(find.text('Journal'));
    await tester.pumpAndSettle();

    // The recap card should appear with the week summary.
    expect(find.text('Your Week at a Glance'), findsOneWidget);
    expect(find.textContaining('moods logged'), findsOneWidget);
    // The trigger we tagged should surface in the recap.
    expect(find.text('Most logged trigger: Sleep'), findsOneWidget);
  });
}

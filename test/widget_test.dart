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

    await tester.tap(find.text('Happy'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Today'), findsOneWidget);
  });
}

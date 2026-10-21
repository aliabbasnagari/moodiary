# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Moodiary** is a Flutter mood-tracking app with custom-drawn expressive faces (no image assets). Built with Material 3, Riverpod for state management, and `CustomPainter` for all graphics.

## Architecture

**State Management**: Riverpod's `StateNotifierProvider` (`MoodEntriesNotifier`) manages the list of mood entries in-memory. Use `ref.read(moodEntriesProvider.notifier).log(mood)` to add entries.

**Widget Structure**:
- `main.dart`: App entry point with `ProviderScope`, custom `AppScrollBehavior`, and warm Material 3 theme
- `models/mood.dart`: `Mood` enum (5 values with colors) and `MoodEntry` model
- `state/mood_entries_provider.dart`: Riverpod provider for entries, `recentMoodEntriesProvider` for latest 7
- `screens/mood_home_screen.dart`: Main screen with picker and timeline
- `widgets/mood_picker.dart`: Row of tappable faces
- `widgets/mood_timeline.dart`: Horizontal scroll list with animated cards
- `widgets/mood_face.dart`: Wrapper around painter
- `widgets/mood_face_painter.dart`: `CustomPainter` that draws each face with eyes, brows, and mouth based on mood

## Common Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run on default device
flutter run -d chrome    # Web
flutter run -d windows   # Windows desktop
flutter analyze          # Static analysis
flutter test             # Run tests
flutter pub run flutter_launcher_icons  # Regenerate launcher icons
```

## Tech Stack

- Flutter SDK ^3.11.5
- flutter_riverpod ^2.5.1 (state management)
- intl ^0.19.0 (date formatting)
- flutter_lints ^6.0.0

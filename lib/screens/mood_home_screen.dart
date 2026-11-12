import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/mood.dart';
import '../widgets/forecast_accuracy_card.dart';
import '../widgets/goal_progress_card.dart';
import '../widgets/mood_forecast_card.dart';
import '../widgets/mood_nudge_banner.dart';
import '../widgets/mood_picker.dart';
import '../widgets/mood_timeline.dart';
import 'mood_journal_screen.dart';

class MoodHomeScreen extends StatefulWidget {
  const MoodHomeScreen({super.key});

  @override
  State<MoodHomeScreen> createState() => _MoodHomeScreenState();
}

class _MoodHomeScreenState extends State<MoodHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F2),
      appBar: AppBar(
        title: const Text(
          'Moodiary',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.black38,
          indicatorColor: const Color(0xFFE6A817),
          indicatorWeight: 3,
          indicatorSize: TabIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Log'),
            Tab(text: 'Timeline'),
            Tab(text: 'Journal'),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLogTab(),
                  _buildTimelineTab(),
                  const MoodJournalScreen(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// "Good morning" / "Good afternoon" / "Good evening" with the date.
  String get _greeting {
    final now = DateTime.now();
    final hour = now.hour;
    final word = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    return '$word · ${DateFormat('EEE, MMM d').format(now)}';
  }

  Widget _buildLogTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            _greeting,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.black54, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          const MoodNudgeBanner(),
          Text(
            'How are you feeling?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap a face to log it.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                ),
          ),
          const SizedBox(height: 24),
          const MoodPicker(),
          const SizedBox(height: 24),
          const GoalProgressCard(),
          const MoodForecastCard(),
          const ForecastAccuracyCard(),
          const SizedBox(height: 16),
          Text(
            'Recent moods',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          const MoodTimeline(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: const MoodTimeline(),
      ),
    );
  }
}

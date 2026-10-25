import 'package:flutter/material.dart';

import '../models/mood.dart';
import '../widgets/mood_picker.dart';
import '../widgets/mood_timeline.dart';
import '../widgets/mood_trends_chart.dart';
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
        title: const Text('Moodiary'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        bottom: TabBar(
          controller: _tabController,
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
                  const MoodTimeline(),
                  const MoodJournalScreen(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
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
        const SizedBox(height: 40),
        Text(
          'Recent moods',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        const MoodTimeline(),
      ],
    );
  }
}

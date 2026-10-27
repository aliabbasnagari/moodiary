import 'package:flutter_riverpod/flutter_riverpod.dart';

class MoodPrompt {
  final String question;
  final String category;

  const MoodPrompt({
    required this.question,
    required this.category,
  });
}

final promptsByMood = <MoodCategory, List<MoodPrompt>>{
  MoodCategory.happy: [
    MoodPrompt(
      question: 'What made today a great day?',
      category: 'happy',
    ),
    MoodPrompt(
      question: 'What are you most grateful for today?',
      category: 'happy',
    ),
    MoodPrompt(
      question: 'What small joy did you notice today?',
      category: 'happy',
    ),
  ],
  MoodCategory.good: [
    MoodPrompt(
      question: 'What was the highlight of your day?',
      category: 'good',
    ),
    MoodPrompt(
      question: 'What went better than expected?',
      category: 'good',
    ),
    MoodPrompt(
      question: 'Who made your day better?',
      category: 'good',
    ),
  ],
  MoodCategory.neutral: [
    MoodPrompt(
      question: 'How would you describe your day in one word?',
      category: 'neutral',
    ),
    MoodPrompt(
      question: 'What was your energy level today?',
      category: 'neutral',
    ),
    MoodPrompt(
      question: 'Is there anything you want to change tomorrow?',
      category: 'neutral',
    ),
  ],
  MoodCategory.sad: [
    MoodPrompt(
      question: 'What\'s weighing on your mind?',
      category: 'sad',
    ),
    MoodPrompt(
      question: 'Is there something you need to let go of?',
      category: 'sad',
    ),
    MoodPrompt(
      question: 'What would comfort you right now?',
      category: 'sad',
    ),
  ],
  MoodCategory.awful: [
    MoodPrompt(
      question: 'What was the hardest part of your day?',
      category: 'awful',
    ),
    MoodPrompt(
      question: 'What small thing helped you get through it?',
      category: 'awful',
    ),
    MoodPrompt(
      question: 'What will you do differently tomorrow?',
      category: 'awful',
    ),
  ],
};

enum MoodCategory { happy, good, neutral, sad, awful }

final moodPromptProvider = StateProvider<MoodPrompt?>((ref) => null);

final weeklySummaryPromptProvider = Provider<MoodPrompt?>((ref) {
  final prompts = promptsByMood.values.expand((e) => e).toList();
  if (prompts.isEmpty) return null;
  return prompts.first;
});

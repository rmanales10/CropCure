import 'dart:developer';
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cropcure/config/gemini_config.dart';

class DailyReminderController extends GetxController {
  // Removed FirebaseFirestore - no longer needed for general reminders

  var reminder = 'Loading your daily reminder...'.obs;
  var isLoadingReminder = false.obs;
  String? _cachedReminder;
  DateTime? _cachedDate;
  GenerativeModel? _reminderModel;

  @override
  void onInit() {
    super.onInit();
    generateDailyReminder();
  }

  Future<void> generateDailyReminder() async {
    // Check if we have a cached reminder for today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_cachedReminder != null &&
        _cachedDate != null &&
        _cachedDate!.isAtSameMomentAs(today)) {
      reminder.value = _cachedReminder!;
      return;
    }

    isLoadingReminder.value = true;

    try {
      // Initialize model if needed
      if (_reminderModel == null) {
        final apiKey = await GeminiConfig.getApiKey();
        _reminderModel = GenerativeModel(
          model: GeminiConfig.textModel,
          apiKey: apiKey,
        );
      }

      // Create general plant care reminder prompt (no scan history)
      final prompt =
          '''Generate a friendly, encouraging daily general plant care reminder. 

Requirements:
- Keep it short and simple (1 sentence, maximum 15-20 words)
- Be general and not specific to any particular plant
- Be actionable (water, check, inspect, care for, etc.)
- Make it warm and encouraging
- Don't use markdown formatting (no **, *, #, etc.)
- Don't use quotes or special characters unnecessarily
- Don't reference specific plant names or scan history

Examples of good general reminders:
- "Water your plants today if they need it."
- "Take a moment to check on your plants today."
- "Give your plants some care and attention today."
- "Remember to check your plants for proper watering today."
- "Spend a few minutes caring for your plants today."

Generate ONE unique, fresh general reminder that's different from the examples:''';

      final response = await _reminderModel!.generateContent([
        Content.text(prompt),
      ]);

      String generatedReminder =
          response.text?.trim() ?? 'Water your plants today if they need it.';

      // Clean up any markdown or unwanted characters
      generatedReminder = _cleanReminder(generatedReminder);

      // Cache the reminder for today
      _cachedReminder = generatedReminder;
      _cachedDate = today;
      reminder.value = generatedReminder;
    } catch (e) {
      log('Error generating reminder: $e');
      // Fallback general reminders if AI fails
      final fallbackReminders = [
        'Water your plants today if they need it.',
        'Take a moment to check on your plants today.',
        'Give your plants some care and attention today.',
        'Remember to check your plants for proper watering today.',
        'Spend a few minutes caring for your plants today.',
        'Check if your plants need water or sunlight today.',
        'Your plants could use some attention today.',
        'Make time to care for your plants today.',
      ];
      final randomIndex = DateTime.now().day % fallbackReminders.length;
      _cachedReminder = fallbackReminders[randomIndex];
      _cachedDate = today;
      reminder.value = _cachedReminder!;
    } finally {
      isLoadingReminder.value = false;
    }
  }

  // Removed _fetchRecentScans() - no longer needed for general reminders

  String _cleanReminder(String text) {
    // Remove markdown formatting
    text = text.replaceAllMapped(
      RegExp(r'\*\*([^*]+?)\*\*'),
      (match) => match.group(1) ?? '',
    );
    text = text.replaceAllMapped(
      RegExp(r'(?<!\*)\*([^*]+?)\*(?!\*)'),
      (match) => match.group(1) ?? '',
    );
    text = text.replaceAll('*', '');
    text = text.replaceAll('_', '');
    text = text.replaceAll('#', '');
    text = text.replaceAll('`', '');
    // Remove quotes if the entire reminder is wrapped in them
    text = text.replaceAll(RegExp(r'^["]|["]$'), '');
    text = text.replaceAll(RegExp(r"^[']|[']$"), '');
    // Remove any dollar signs or $1
    text = text.replaceAll(RegExp(r'\$1'), '');
    // Trim and clean
    return text.trim();
  }

  // Force refresh reminder (for testing or manual refresh)
  Future<void> refreshReminder() async {
    _cachedReminder = null;
    _cachedDate = null;
    await generateDailyReminder();
  }
}

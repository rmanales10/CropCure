import 'dart:developer';
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cropcure/config/gemini_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DailyReminderController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? get currentUser => _auth.currentUser;

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
      // Fetch recent scan history for personalized reminders
      final recentScans = await _fetchRecentScans();

      // Initialize model if needed
      if (_reminderModel == null) {
        final apiKey = await GeminiConfig.getApiKey();
        _reminderModel = GenerativeModel(
          model: GeminiConfig.textModel,
          apiKey: apiKey,
        );
      }

      // Create prompt for generating reminder
      String scanContext = '';
      if (recentScans.isNotEmpty) {
        scanContext = 'The user recently scanned these plants: ';
        final plantNames = recentScans
            .take(3)
            .map((scan) => scan['name'] ?? 'a plant')
            .toList()
            .join(', ');
        scanContext += '$plantNames.';
      }

      final prompt =
          '''Generate a friendly, encouraging daily plant care reminder. 

Requirements:
- Keep it short (1 sentence, maximum 15-20 words)
- Be specific and actionable (water, check, prune, fertilize, etc.)
- Make it warm and encouraging
- Don't use markdown formatting (no **, *, #, etc.)
- Don't use quotes or special characters unnecessarily
${scanContext.isNotEmpty ? '- You can reference their plants: $scanContext' : ''}

Examples of good reminders:
- "Remember to check your plants for any signs of pests or diseases today."
- "Give your plants some attention today - check if they need watering."
- "Take a moment to inspect your plant leaves for any discoloration."

Generate ONE unique, fresh reminder that's different from the examples:''';

      final response = await _reminderModel!.generateContent([
        Content.text(prompt),
      ]);

      String generatedReminder =
          response.text?.trim() ??
          'Take a moment to check on your plants today and give them the care they need.';

      // Clean up any markdown or unwanted characters
      generatedReminder = _cleanReminder(generatedReminder);

      // Cache the reminder for today
      _cachedReminder = generatedReminder;
      _cachedDate = today;
      reminder.value = generatedReminder;
    } catch (e) {
      log('Error generating reminder: $e');
      // Fallback reminders if AI fails
      final fallbackReminders = [
        'Take a moment to check on your plants today and give them the care they need.',
        'Remember to water your plants if the soil feels dry to the touch.',
        'Check your plants for any signs of pests, diseases, or nutrient deficiencies.',
        'Give your plants some attention today - they\'ll thank you for it!',
        'Make sure your plants are getting adequate sunlight and proper watering.',
      ];
      final randomIndex = DateTime.now().day % fallbackReminders.length;
      _cachedReminder = fallbackReminders[randomIndex];
      _cachedDate = today;
      reminder.value = _cachedReminder!;
    } finally {
      isLoadingReminder.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRecentScans() async {
    if (currentUser == null) return [];

    try {
      final querySnapshot =
          await _firestore
              .collection('plants')
              .where('userId', isEqualTo: currentUser!.uid)
              .orderBy('timestamp', descending: true)
              .limit(5)
              .get();

      return querySnapshot.docs.map((doc) {
        return Map<String, dynamic>.from(doc.data());
      }).toList();
    } catch (e) {
      log('Error fetching recent scans: $e');
      return [];
    }
  }

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

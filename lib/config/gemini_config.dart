import 'package:cloud_firestore/cloud_firestore.dart';

class GeminiConfig {
  // ============================================================================
  // API CONFIGURATION
  // ============================================================================

  // Fallback API Key (used if Firestore fetch fails)
  // Get your API key from: https://ai.google.dev/gemini-api/docs/api-key
  static const String _fallbackApiKey =
      'AIzaSyDIcyFPmR_mSY14aKV24UrPuOKpAtQdvKQ';

  // Cached API key from Firestore
  static String? _cachedApiKey;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheDuration = Duration(hours: 1); // Cache for 1 hour

  /// Fetches API key from Firestore (collection: 'ai', document: 'ai', field: 'apiKey')
  /// Uses caching to avoid repeated Firestore calls
  static Future<String> getApiKey() async {
    // Return cached key if still valid
    if (_cachedApiKey != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
      return _cachedApiKey!;
    }

    try {
      final doc =
          await FirebaseFirestore.instance.collection('ai').doc('ai').get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        final apiKey = data['apiKey'] as String?;

        if (apiKey != null && apiKey.isNotEmpty) {
          _cachedApiKey = apiKey;
          _cacheTimestamp = DateTime.now();
          return apiKey;
        }
      }
    } catch (e) {
      print('Error fetching API key from Firestore: $e');
    }

    // Fallback to hardcoded key if Firestore fetch fails
    print('Using fallback API key');
    return _fallbackApiKey;
  }

  /// Clears the cached API key (useful for forcing refresh)
  static void clearCache() {
    _cachedApiKey = null;
    _cacheTimestamp = null;
  }

  // ============================================================================
  // MODEL CONFIGURATIONS
  // ============================================================================

  // Model for image analysis and plant recognition
  static const String imageModel = 'gemini-2.5-flash-lite';

  // Model for text processing and treatment recommendations
  static const String textModel = 'gemini-2.5-flash-lite';

  // Model for general AI tasks and complex analysis
  static const String generalModel = 'gemini-2.5-flash';

  // ============================================================================
  // RATE LIMITING CONFIGURATIONS (Free Tier)
  // ============================================================================

  // Cooldown periods between requests (in seconds)
  static const int imageRequestCooldown = 1; // 6 seconds between image requests
  static const int textRequestCooldown = 2; // 4 seconds between text requests
  static const int generalRequestCooldown =
      2; // 6 seconds between general requests

  // ============================================================================
  // FREE TIER LIMITS (for reference and validation)
  // ============================================================================

  // Requests per minute limits
  static const int maxImageRequestsPerMinute = 15; // Gemini 2.5 Flash-Lite
  static const int maxTextRequestsPerMinute = 15; // Gemini 2.5 Flash-Lite
  static const int maxGeneralRequestsPerMinute = 10; // Gemini 2.5 Flash

  // Requests per day limits
  static const int maxImageRequestsPerDay = 1000; // Gemini 2.5 Flash-Lite
  static const int maxTextRequestsPerDay = 1000; // Gemini 2.5 Flash-Lite
  static const int maxGeneralRequestsPerDay = 250; // Gemini 2.5 Flash

  // Token limits per minute
  static const int maxTokensPerMinute = 250000; // Both models

  // ============================================================================
  // MODEL CAPABILITIES
  // ============================================================================

  static const bool supportsImageAnalysis = true;
  static const bool supportsTextGeneration = true;
  static const bool supportsMultiModal = true;
  static const bool supportsFunctionCalling = true;
  static const bool supportsStreaming = true;

  // ============================================================================
  // DEBUGGING AND MONITORING
  // ============================================================================

  static const bool enableDebugLogging = true;
  static const bool enableRateLimitLogging = true;
  static const bool enableApiResponseLogging =
      false; // Set to true for detailed API responses

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get the appropriate model for the given task type
  static String getModelForTask(String taskType) {
    switch (taskType.toLowerCase()) {
      case 'image':
      case 'plant_recognition':
      case 'disease_detection':
        return imageModel;
      case 'text':
      case 'treatment':
      case 'care_tips':
        return textModel;
      case 'general':
      case 'analysis':
      default:
        return generalModel;
    }
  }

  /// Get the cooldown period for the given task type
  static int getCooldownForTask(String taskType) {
    switch (taskType.toLowerCase()) {
      case 'image':
      case 'plant_recognition':
      case 'disease_detection':
        return imageRequestCooldown;
      case 'text':
      case 'treatment':
      case 'care_tips':
        return textRequestCooldown;
      case 'general':
      case 'analysis':
      default:
        return generalRequestCooldown;
    }
  }

  /// Check if the current configuration is valid
  static Future<bool> isValid() async {
    final apiKey = await getApiKey();
    return apiKey.isNotEmpty &&
        apiKey != 'YOUR_API_KEY_HERE' &&
        imageModel.isNotEmpty &&
        textModel.isNotEmpty &&
        generalModel.isNotEmpty;
  }
}

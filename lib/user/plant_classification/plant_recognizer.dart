import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cropcure/config/gemini_config.dart';

class PlantRecognizer extends GetxController {
  // Using Gemini 2.5 Flash-Lite for image recognition (Free tier: 15 RPM, 250,000 TPM, 1,000 RPD)
  final imageModel = GenerativeModel(
    model: GeminiConfig.imageModel,
    apiKey: GeminiConfig.apiKey,
  );

  // Using Gemini 2.5 Flash-Lite for text processing (Free tier: 15 RPM, 250,000 TPM, 1,000 RPD)
  final textModel = GenerativeModel(
    model: GeminiConfig.textModel,
    apiKey: GeminiConfig.apiKey,
  );

  // Rate limiting variables
  DateTime? _lastImageRequest;
  DateTime? _lastTextRequest;
  static const int _imageRequestCooldown = GeminiConfig.imageRequestCooldown;
  static const int _textRequestCooldown = GeminiConfig.textRequestCooldown;

  RxString plantName = ''.obs;
  RxBool hasPlantDetected = false.obs;
  RxString diseaseName = ''.obs;
  RxBool hasDiseaseDetected = false.obs;
  RxString treatmentRecommendation = ''.obs;
  RxBool hasTreatmentGenerated = false.obs;

  // Rate limiting helper methods
  bool _canMakeImageRequest() {
    if (_lastImageRequest == null) return true;
    final now = DateTime.now();
    final timeSinceLastRequest = now.difference(_lastImageRequest!).inSeconds;
    return timeSinceLastRequest >= _imageRequestCooldown;
  }

  bool _canMakeTextRequest() {
    if (_lastTextRequest == null) return true;
    final now = DateTime.now();
    final timeSinceLastRequest = now.difference(_lastTextRequest!).inSeconds;
    return timeSinceLastRequest >= _textRequestCooldown;
  }

  void _updateImageRequestTime() {
    _lastImageRequest = DateTime.now();
  }

  void _updateTextRequestTime() {
    _lastTextRequest = DateTime.now();
  }

  Future<void> recognizePlant(String base64Image) async {
    try {
      // Check rate limiting
      if (!_canMakeImageRequest()) {
        log('Rate limit: Please wait before making another image request');
        hasPlantDetected.value = false;
        return;
      }

      final content = [
        Content.text(
          'Analyze this plant image and identify the plant species. Focus on leaves, flowers, fruits, and overall plant structure. Respond with only the most likely plant name (common name preferred). If you cannot clearly identify a plant, respond with "Unknown plant".',
        ),
        Content.multi([
          TextPart('What plant species is shown in this image?'),
          DataPart('image/jpeg', base64Decode(base64Image)),
        ]),
      ];

      _updateImageRequestTime(); // Update request time before making the call
      final response = await imageModel.generateContent(content);
      final detectedName = response.text?.trim() ?? '';
      plantName.value = detectedName;

      hasPlantDetected.value =
          detectedName.isNotEmpty &&
          detectedName.toLowerCase() != 'unknown plant' &&
          detectedName.toLowerCase() != 'no plant detected';

      log('Plant name: $plantName');
      log('Plant detected: $hasPlantDetected');
    } catch (e) {
      hasPlantDetected.value = false;
      log('Exception occurred: $e');
    }
  }

  Future<void> classifyPlantDisease(String base64Image) async {
    try {
      // Check rate limiting
      if (!_canMakeImageRequest()) {
        log('Rate limit: Please wait before making another image request');
        hasDiseaseDetected.value = false;
        return;
      }

      final content = [
        Content.text(
          'Examine this $plantName plant image for signs of disease, pests, or health issues. Look for spots, discoloration, wilting, unusual growth patterns, or damage. Respond with only the disease/issue name if detected, or "Healthy plant" if no issues are visible. If uncertain, respond with "Possible [issue name]".',
        ),
        Content.multi([
          TextPart(
            'What disease or health issue is affecting this $plantName?',
          ),
          DataPart('image/jpeg', base64Decode(base64Image)),
        ]),
      ];

      _updateImageRequestTime(); // Update request time before making the call
      final response = await imageModel.generateContent(content);
      final detectedDisease = response.text?.trim() ?? '';
      diseaseName.value = detectedDisease;

      hasDiseaseDetected.value =
          detectedDisease.isNotEmpty &&
          detectedDisease.toLowerCase() != 'healthy plant' &&
          detectedDisease.toLowerCase() != 'no disease detected';

      log('Disease name: $diseaseName');
      log('Disease detected: $hasDiseaseDetected');
    } catch (e) {
      hasDiseaseDetected.value = false;
      log('Exception occurred: $e');
    }
  }

  Future<void> getPlantTreatment(String plantName, String disease) async {
    try {
      // Check rate limiting
      if (!_canMakeTextRequest()) {
        log('Rate limit: Please wait before making another text request');
        hasTreatmentGenerated.value = false;
        return;
      }

      log('Plant name: $plantName');
      log('Disease name: $disease');

      String prompt;
      if (disease.toLowerCase().contains('healthy') || disease.isEmpty) {
        prompt =
            'Provide 3 essential care tips for maintaining healthy $plantName plants. Include watering, sunlight, and general care advice. Keep response under 100 words.';
      } else {
        prompt =
            'Provide a practical treatment plan for $disease affecting $plantName. Include immediate actions, preventive measures, and monitoring steps. Keep response under 120 words.';
      }

      _updateTextRequestTime(); // Update request time before making the call
      final response = await textModel.generateContent([Content.text(prompt)]);
      final treatment = response.text?.trim() ?? '';

      // Clean up the treatment recommendation
      treatmentRecommendation.value = treatment
          .replaceAll('*', '')
          .replaceAll('**', '')
          .replaceAll('###', '')
          .replaceAll('##', '')
          .replaceAll('#', '');
      hasTreatmentGenerated.value = true;

      log('Treatment recommendation: $treatmentRecommendation');
    } catch (e) {
      hasTreatmentGenerated.value = false;
      log('Exception occurred: $e');
    }
  }
}

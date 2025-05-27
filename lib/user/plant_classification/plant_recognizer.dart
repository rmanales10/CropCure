import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class PlantRecognizer extends GetxController {
  final model = GenerativeModel(
    model: 'gemma-3-27b-it',
    apiKey: 'AIzaSyDDr5UCuvHkMpA6oX-0VAAAS6vSA8k-RK4',
  );

  final textModel = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: 'AIzaSyDDr5UCuvHkMpA6oX-0VAAAS6vSA8k-RK4',
  );

  RxString plantName = ''.obs;
  RxBool hasPlantDetected = false.obs;
  RxString diseaseName = ''.obs;
  RxBool hasDiseaseDetected = false.obs;
  RxString treatmentRecommendation = ''.obs;
  RxBool hasTreatmentGenerated = false.obs;

  Future<void> recognizePlant(String base64Image) async {
    try {
      final content = [
        Content.text(
          'What is the name of the plant in this image? Respond with only the plant name, nothing else. If you cannot identify the plant, respond with "No plant detected".',
        ),
        Content.multi([
          TextPart('What is the name of the plant in this image?'),
          DataPart('image/jpeg', base64Decode(base64Image)),
        ]),
      ];

      final response = await model.generateContent(content);
      final detectedName = response.text?.trim() ?? '';
      plantName.value = detectedName;

      hasPlantDetected.value =
          detectedName.isNotEmpty &&
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
      final content = [
        Content.text(
          'What disease is affecting this $plantName? Respond with only the disease name, nothing else. If you cannot identify any disease or the plant appears healthy, respond with "No disease detected".',
        ),
        Content.multi([
          TextPart('What disease is affecting this $plantName?'),
          DataPart('image/jpeg', base64Decode(base64Image)),
        ]),
      ];

      final response = await model.generateContent(content);
      final detectedDisease = response.text?.trim() ?? '';
      diseaseName.value = detectedDisease;

      hasDiseaseDetected.value =
          detectedDisease.isNotEmpty &&
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
      log('Plant name: $plantName');
      log('Disease name: $disease');

      final prompt =
          'Provide a brief treatment plan for $disease on $plantName in 2-3 short steps. If no disease is specified, give 2-3 quick care tips for $plantName. Keep response under 100 words.';

      final response = await textModel.generateContent([Content.text(prompt)]);
      final treatment = response.text?.trim() ?? '';

      // Remove asterisks from the treatment recommendation
      treatmentRecommendation.value = treatment.replaceAll('*', '');
      hasTreatmentGenerated.value = true;

      log('Treatment recommendation: $treatmentRecommendation');
    } catch (e) {
      hasTreatmentGenerated.value = false;
      log('Exception occurred: $e');
    }
  }
}

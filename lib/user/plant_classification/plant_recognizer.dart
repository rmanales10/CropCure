import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:get/get.dart';

class PlantRecognizer extends GetxController {
  final connect = GetConnect();
  RxString plantName = ''.obs;
  RxBool hasPlantDetected = false.obs;
  RxString diseaseName = ''.obs;
  RxBool hasDiseaseDetected = false.obs;

  Future<void> recognizePlant(String base64Image) async {
    // API endpoint
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemma-3-27b-it:generateContent';

    // Your API key
    final apiKey = 'AIzaSyDDr5UCuvHkMpA6oX-0VAAAS6vSA8k-RK4';

    // Query parameters
    final params = {'key': apiKey};

    // Request body
    final data = {
      'contents': [
        {
          'parts': [
            {
              'text':
                  'What is the name of the plant in this image? Respond with only the plant name, nothing else. If you cannot identify the plant, respond with "No plant detected".',
            },
            {
              'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image},
            },
          ],
        },
      ],
    };

    try {
      // Make the POST request
      final response = await connect.post(
        url,
        data,
        query: params,
        headers: {'Content-Type': 'application/json'},
      );

      // Check if the request was successful
      if (response.status.isOk) {
        // Parse the JSON response
        final result = response.body;

        // Extract the plant name from the response
        final detectedName =
            result['candidates'][0]['content']['parts'][0]['text'].trim();
        plantName.value = detectedName;

        // Set hasPlantDetected based on whether we got a valid plant name
        hasPlantDetected.value =
            detectedName.isNotEmpty &&
            detectedName.toLowerCase() != 'no plant detected';

        log('Plant name: $plantName');
        log('Plant detected: $hasPlantDetected');
      } else {
        hasPlantDetected.value = false;
        log('Error: ${response.statusCode}');
        log(response.body);
      }
    } catch (e) {
      hasPlantDetected.value = false;
      log('Exception occurred: $e');
    }
  }

  Future<void> classifyPlantDisease(String base64Image) async {
    // API endpoint
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemma-3-27b-it:generateContent';

    // Your API key
    final apiKey = 'AIzaSyDDr5UCuvHkMpA6oX-0VAAAS6vSA8k-RK4';

    // Query parameters
    final params = {'key': apiKey};

    // Request body
    final data = {
      'contents': [
        {
          'parts': [
            {
              'text':
                  'What disease is affecting this plant? Respond with only the disease name, nothing else. If you cannot identify any disease or the plant appears healthy, respond with "No disease detected".',
            },
            {
              'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image},
            },
          ],
        },
      ],
    };

    try {
      // Make the POST request
      final response = await connect.post(
        url,
        data,
        query: params,
        headers: {'Content-Type': 'application/json'},
      );

      // Check if the request was successful
      if (response.status.isOk) {
        // Parse the JSON response
        final result = response.body;

        // Extract the disease name from the response
        final detectedDisease =
            result['candidates'][0]['content']['parts'][0]['text'].trim();
        diseaseName.value = detectedDisease;

        // Set hasDiseaseDetected based on whether we got a valid disease name
        hasDiseaseDetected.value =
            detectedDisease.isNotEmpty &&
            detectedDisease.toLowerCase() != 'no disease detected';

        log('Disease name: $diseaseName');
        log('Disease detected: $hasDiseaseDetected');
      } else {
        hasDiseaseDetected.value = false;
        log('Error: ${response.statusCode}');
        log(response.body);
      }
    } catch (e) {
      hasDiseaseDetected.value = false;
      log('Exception occurred: $e');
    }
  }
}

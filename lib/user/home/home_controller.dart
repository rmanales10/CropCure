import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HomeController extends GetxController {
  final history = RxList<Map<String, dynamic>>([]);
  var isLoading = false.obs;

  Future<void> fetchPlants() async {
    try {
      isLoading.value = true;
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('plants')
              .where('userId', isEqualTo: userId)
              .orderBy('timestamp', descending: true)
              .get();

      final List<Map<String, dynamic>> plantData =
          querySnapshot.docs.map((doc) {
            final data = doc.data();
            print(
              'Disease value from Firebase: ${data['disease']}',
            ); // Debug print
            // Ensure timestamp is properly handled
            if (data['timestamp'] is Timestamp) {
              data['timestamp'] = data['timestamp'];
            }
            // Include document ID for deletion
            data['documentId'] = doc.id;
            return data;
          }).toList();

      history.assignAll(plantData);
    } catch (e) {
      print('Error fetching plants: $e');
      Get.snackbar('Error', 'Failed to load plant history');
    } finally {
      isLoading.value = false;
    }
  }

  int get totalDiseases =>
      history
          .where((plant) => plant['disease'] != 'No disease detected')
          .length;

  // Returns a map: day string (e.g. '26') -> count of diseases for specified month
  // If month and year are not provided, uses current month
  Map<String, int> getDiseaseScansPerDay({int? month, int? year}) {
    final Map<String, int> result = {};
    final dateFormat = DateFormat('dd');
    final now = DateTime.now();
    final targetMonth = month ?? now.month;
    final targetYear = year ?? now.year;

    for (var plant in history) {
      if (plant['disease'] != 'No disease detected' &&
          plant['timestamp'] != null) {
        DateTime date;
        if (plant['timestamp'] is Timestamp) {
          date = (plant['timestamp'] as Timestamp).toDate();
        } else if (plant['timestamp'] is String) {
          date = DateTime.parse(plant['timestamp']);
        } else {
          continue;
        }

        // Filter to only include scans from the specified month and year
        if (date.month == targetMonth && date.year == targetYear) {
          final dayStr = dateFormat.format(date);
          result[dayStr] = (result[dayStr] ?? 0) + 1;
        }
      }
    }
    return result;
  }

  // Legacy getter for backward compatibility (uses current month)
  Map<String, int> get diseaseScansPerDay => getDiseaseScansPerDay();

  // Returns a map: disease name -> count for specified month
  // Diseases are sorted by count in descending order
  // Includes all diseases including "Healthy plant"
  Map<String, int> getTopDiseasesForMonth({
    required int month,
    required int year,
  }) {
    final Map<String, int> diseaseCounts = {};

    for (var plant in history) {
      if (plant['disease'] != null &&
          plant['disease'] != 'No disease detected' &&
          plant['timestamp'] != null) {
        DateTime date;
        if (plant['timestamp'] is Timestamp) {
          date = (plant['timestamp'] as Timestamp).toDate();
        } else if (plant['timestamp'] is String) {
          date = DateTime.parse(plant['timestamp']);
        } else {
          continue;
        }

        // Filter to only include scans from the specified month and year
        if (date.month == month && date.year == year) {
          final diseaseName = plant['disease'] as String;
          diseaseCounts[diseaseName] = (diseaseCounts[diseaseName] ?? 0) + 1;
        }
      }
    }

    // Sort diseases by count in descending order
    final sortedEntries =
        diseaseCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Return as a map (maintaining order)
    return Map.fromEntries(sortedEntries);
  }

  // Get total scan count for a specific month
  int getTotalScansForMonth({required int month, required int year}) {
    int count = 0;
    for (var plant in history) {
      if (plant['timestamp'] != null) {
        DateTime date;
        if (plant['timestamp'] is Timestamp) {
          date = (plant['timestamp'] as Timestamp).toDate();
        } else if (plant['timestamp'] is String) {
          date = DateTime.parse(plant['timestamp']);
        } else {
          continue;
        }

        if (date.month == month && date.year == year) {
          count++;
        }
      }
    }
    return count;
  }

  Future<void> deletePlant(String documentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('plants')
          .doc(documentId)
          .delete();

      // Remove from local history
      history.removeWhere((plant) => plant['documentId'] == documentId);

      Get.snackbar(
        'Success',
        'Plant record deleted successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error deleting plant: $e');
      Get.snackbar(
        'Error',
        'Failed to delete plant record',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}

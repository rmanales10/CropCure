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

  // Returns a map: day string (e.g. '2024-05-24') -> count of diseases
  Map<String, int> get diseaseScansPerDay {
    final Map<String, int> result = {};
    final dateFormat = DateFormat('dd');

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
        final dayStr = dateFormat.format(date);
        result[dayStr] = (result[dayStr] ?? 0) + 1;
      }
    }
    return result;
  }
}

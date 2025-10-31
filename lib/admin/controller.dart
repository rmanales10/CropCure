import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Controller extends GetxController {
  final history = RxList<Map<String, dynamic>>([]);
  var isLoading = false.obs;

  Future<void> fetchPlants() async {
    try {
      isLoading.value = true;
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('plants')
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

  // Get current month's data
  List<Map<String, dynamic>> get thisMonthData {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    return history.where((plant) {
      if (plant['timestamp'] == null) return false;
      DateTime date;
      if (plant['timestamp'] is Timestamp) {
        date = (plant['timestamp'] as Timestamp).toDate();
      } else if (plant['timestamp'] is String) {
        date = DateTime.parse(plant['timestamp']);
      } else {
        return false;
      }
      return date.isAfter(firstDayOfMonth.subtract(const Duration(days: 1))) &&
          date.isBefore(lastDayOfMonth.add(const Duration(days: 1)));
    }).toList();
  }

  // This month's statistics
  int get thisMonthTotalScans => thisMonthData.length;
  int get thisMonthDiseases =>
      thisMonthData
          .where(
            (plant) =>
                plant['disease']?.toString().trim().toLowerCase() !=
                'no disease detected',
          )
          .length;
  int get thisMonthHealthy => thisMonthTotalScans - thisMonthDiseases;

  // Disease distribution this month
  Map<String, int> get thisMonthDiseaseDistribution {
    final Map<String, int> result = {};
    for (var plant in thisMonthData) {
      final disease = plant['disease']?.toString() ?? 'Unknown';
      if (disease.trim().toLowerCase() != 'no disease detected') {
        result[disease] = (result[disease] ?? 0) + 1;
      }
    }
    return result;
  }

  // Daily trend for this month
  Map<String, int> get thisMonthDailyTrend {
    final Map<String, int> result = {};
    final dateFormat = DateFormat('MMM dd');

    for (var plant in thisMonthData) {
      if (plant['timestamp'] != null) {
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

  // Weekly comparison (current week vs previous week)
  Map<String, dynamic> get weeklyComparison {
    final now = DateTime.now();
    final startOfCurrentWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfPreviousWeek = startOfCurrentWeek.subtract(
      const Duration(days: 7),
    );
    final endOfPreviousWeek = startOfCurrentWeek.subtract(
      const Duration(days: 1),
    );

    int currentWeek = 0;
    int previousWeek = 0;

    for (var plant in history) {
      if (plant['timestamp'] == null) continue;
      DateTime date;
      if (plant['timestamp'] is Timestamp) {
        date = (plant['timestamp'] as Timestamp).toDate();
      } else if (plant['timestamp'] is String) {
        date = DateTime.parse(plant['timestamp']);
      } else {
        continue;
      }

      if (date.isAfter(startOfCurrentWeek.subtract(const Duration(days: 1))) &&
          date.isBefore(startOfCurrentWeek.add(const Duration(days: 7)))) {
        currentWeek++;
      } else if (date.isAfter(
            startOfPreviousWeek.subtract(const Duration(days: 1)),
          ) &&
          date.isBefore(endOfPreviousWeek.add(const Duration(days: 1)))) {
        previousWeek++;
      }
    }

    final change =
        previousWeek > 0
            ? ((currentWeek - previousWeek) / previousWeek * 100)
            : (currentWeek > 0 ? 100.0 : 0.0);

    return {'current': currentWeek, 'previous': previousWeek, 'change': change};
  }
}

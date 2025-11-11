import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Controller extends GetxController {
  final history = RxList<Map<String, dynamic>>([]);
  final users = RxList<Map<String, dynamic>>([]);
  final selectedUserHistory = RxList<Map<String, dynamic>>([]);
  var isLoading = false.obs;
  var isLoadingUsers = false.obs;
  var selectedUserId = RxString('');

  // Cache for user disease distributions
  final Map<String, Map<String, int>> _userDiseaseCache = {};

  Future<void> fetchPlants() async {
    try {
      isLoading.value = true;
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('plants')
              .orderBy('timestamp', descending: true)
              .get();

      final List<Map<String, dynamic>> plantData = [];

      for (var doc in querySnapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        print('Disease value from Firebase: ${data['disease']}'); // Debug print
        // Ensure timestamp is properly handled
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] = data['timestamp'];
        }
        plantData.add(data);
      }

      history.assignAll(plantData);
      _clearDiseaseCache(); // Clear cache when history updates
    } catch (e) {
      print('Error fetching plants: $e');
      Get.snackbar('Error', 'Failed to load plant history');
    } finally {
      isLoading.value = false;
    }
  }

  // Helper function to check if a plant is healthy (public for use in views)
  bool isPlantHealthy(String? disease) {
    if (disease == null) return false;
    final diseaseLower = disease.toString().trim().toLowerCase();
    return diseaseLower == 'no disease detected' ||
        diseaseLower == 'healthy plant' ||
        diseaseLower == 'healthy' ||
        diseaseLower.contains('healthy') ||
        diseaseLower.contains('no disease');
  }

  int get totalDiseases =>
      history
          .where((plant) => !isPlantHealthy(plant['disease']?.toString()))
          .length;

  // Returns a map: day string (e.g. '24') -> count of diseases
  // Only includes current month's data for chart consistency
  Map<String, int> get diseaseScansPerDay {
    final Map<String, int> result = {};
    final dateFormat = DateFormat('dd');
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    for (var plant in history) {
      // Only count non-healthy plants as diseases
      if (!isPlantHealthy(plant['disease']?.toString()) &&
          plant['timestamp'] != null) {
        DateTime date;
        if (plant['timestamp'] is Timestamp) {
          date = (plant['timestamp'] as Timestamp).toDate();
        } else if (plant['timestamp'] is String) {
          date = DateTime.parse(plant['timestamp']);
        } else {
          continue;
        }

        // Only include current month's scans
        if (date.month == currentMonth && date.year == currentYear) {
          final dayStr = dateFormat.format(date);
          result[dayStr] = (result[dayStr] ?? 0) + 1;
        }
      }
    }
    return result;
  }

  // Returns a map: day string -> count of ALL scans (including healthy plants)
  // Only includes current month's data for chart consistency
  Map<String, int> get allScansPerDay {
    final Map<String, int> result = {};
    final dateFormat = DateFormat('dd');
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

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

        // Only include current month's scans
        if (date.month == currentMonth && date.year == currentYear) {
          final dayStr = dateFormat.format(date);
          result[dayStr] = (result[dayStr] ?? 0) + 1;
        }
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
          .where((plant) => !isPlantHealthy(plant['disease']?.toString()))
          .length;
  int get thisMonthHealthy => thisMonthTotalScans - thisMonthDiseases;

  // Disease distribution this month
  Map<String, int> get thisMonthDiseaseDistribution {
    final Map<String, int> result = {};
    for (var plant in thisMonthData) {
      final disease = plant['disease']?.toString() ?? 'Unknown';
      if (!isPlantHealthy(disease)) {
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

  // Fetch all users with their scan statistics
  Future<void> fetchUsers() async {
    try {
      isLoadingUsers.value = true;

      // Fetch all users
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      final List<Map<String, dynamic>> usersList = [];

      for (var userDoc in usersSnapshot.docs) {
        final userData = Map<String, dynamic>.from(userDoc.data());
        final userId = userDoc.id;

        // Count scans for this user
        final userScans =
            history.where((plant) {
              // Check if plant has userId field or user_id field
              final plantUserId = plant['userId'] ?? plant['user_id'];
              return plantUserId?.toString() == userId;
            }).toList();

        usersList.add({
          'uid': userId,
          'email': userData['email'] ?? 'N/A',
          'fullname': userData['fullname'] ?? 'Unknown User',
          'phone_number': userData['phone_number'] ?? 'N/A',
          'created_at': userData['created_at'],
          'status': userData['status'] ?? 'offline',
          'base64image': userData['base64image'], // Include profile image
          'totalScans': userScans.length,
          'diseaseDetected':
              userScans
                  .where((p) => !isPlantHealthy(p['disease']?.toString()))
                  .length,
          'healthyScans':
              userScans
                  .where((p) => isPlantHealthy(p['disease']?.toString()))
                  .length,
        });
      }

      // Sort by total scans (descending)
      usersList.sort(
        (a, b) => (b['totalScans'] as int).compareTo(a['totalScans'] as int),
      );

      users.assignAll(usersList);
    } catch (e) {
      print('Error fetching users: $e');
      Get.snackbar('Error', 'Failed to load users');
    } finally {
      isLoadingUsers.value = false;
    }
  }

  // Fetch scan history for a specific user
  Future<void> fetchUserHistory(String userId) async {
    try {
      selectedUserId.value = userId;
      final userScans =
          history.where((plant) {
            final plantUserId = plant['userId'] ?? plant['user_id'];
            return plantUserId?.toString() == userId;
          }).toList();

      // Sort by timestamp descending
      userScans.sort((a, b) {
        DateTime? dateA, dateB;
        if (a['timestamp'] is Timestamp) {
          dateA = (a['timestamp'] as Timestamp).toDate();
        }
        if (b['timestamp'] is Timestamp) {
          dateB = (b['timestamp'] as Timestamp).toDate();
        }
        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA);
      });

      selectedUserHistory.assignAll(userScans);
    } catch (e) {
      print('Error fetching user history: $e');
    }
  }

  // Get user's disease distribution (with caching)
  Map<String, int> getUserDiseaseDistribution(String userId) {
    // Return cached result if available
    if (_userDiseaseCache.containsKey(userId)) {
      return _userDiseaseCache[userId]!;
    }

    final Map<String, int> result = {};
    final userScans =
        history.where((plant) {
          final plantUserId = plant['userId'] ?? plant['user_id'];
          return plantUserId?.toString() == userId;
        }).toList();

    for (var plant in userScans) {
      final disease = plant['disease']?.toString() ?? 'Unknown';
      if (!isPlantHealthy(disease)) {
        result[disease] = (result[disease] ?? 0) + 1;
      }
    }

    // Cache the result
    _userDiseaseCache[userId] = result;
    return result;
  }

  // Clear cache when history changes
  void _clearDiseaseCache() {
    _userDiseaseCache.clear();
  }

  // Get selected user info
  Map<String, dynamic>? get selectedUserInfo {
    if (selectedUserId.value.isEmpty) return null;
    return users.firstWhereOrNull(
      (user) => user['uid'] == selectedUserId.value,
    );
  }
}

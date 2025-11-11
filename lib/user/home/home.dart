import 'dart:convert';
import 'dart:typed_data';
import 'package:cropcure/user/home/home_controller.dart';
import 'package:cropcure/user/home/daily_reminder_controller.dart';
import 'package:cropcure/user/profile/profile_controller.dart';
import 'package:cropcure/user/chatbot/chatbot_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _profileController = Get.put(ProfileController());
  final _homeController = Get.put(HomeController());
  final _reminderController = Get.put(DailyReminderController());
  final history = RxList<Map<String, dynamic>>([]);
  int _currentPage = 0;
  static const int _itemsPerPage = 5;
  DateTime? _startDate;
  DateTime? _endDate;

  // Helper function to check if a plant is healthy
  bool _isPlantHealthy(String? disease) {
    if (disease == null) return false;
    final diseaseLower = disease.toString().trim().toLowerCase();
    return diseaseLower == 'no disease detected' ||
        diseaseLower == 'healthy plant' ||
        diseaseLower == 'healthy' ||
        diseaseLower.contains('healthy') ||
        diseaseLower.contains('no disease');
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    await _homeController.fetchPlants();
    await _profileController
        .fetchUserInfo(); // Fetch user info once during init
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.green.shade50],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    _buildGreetingSection(),
                    _buildDailyReminderCard(),
                    _buildScanHistoryCard(),
                    _buildAIChatbotCard(),
                    _buildFAQsCard(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingSection() {
    return Container(
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Obx(() {
            final data = _profileController.userInfo;
            try {
              if (data['base64image'] != null &&
                  data['base64image'].isNotEmpty) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.memory(
                      base64Decode(data['base64image']),
                      height: 70,
                      width: 70,
                      gaplessPlayback: true,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }
            } catch (e) {
              // Handle error or missing image
            }
            // Return default avatar
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/2.jpg',
                  height: 70,
                  width: 70,
                  gaplessPlayback: true,
                  fit: BoxFit.cover,
                ),
              ),
            );
          }),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Obx(
                      () => Text(
                        _profileController.userInfo['fullname'] ?? 'Not set',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const Text("👋", style: TextStyle(fontSize: 22)),
                  ],
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Welcome to CropCure",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyReminderCard() {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green.shade50, Colors.green.shade100],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade400,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Obx(() {
                    if (_reminderController.isLoadingReminder.value) {
                      return SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      );
                    }
                    return const Icon(
                      Icons.water_drop_rounded,
                      color: Colors.white,
                      size: 28,
                    );
                  }),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Reminder',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Obx(() {
                        return Text(
                          _reminderController.reminder.value,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAIChatbotCard() {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: () {
            Get.to(() => const ChatbotScreen());
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Chatbot',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ask about treatments and tutorials',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAQsCard() {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: () {
            _showFAQsDialog();
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.help_outline_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FAQs',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Frequently Asked Questions',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanHistoryCard() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: 16.0,
      ),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Table
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Scan History",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      color: Colors.green.shade700,
                    ),
                  ),
                  // Date Filter Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showDateRangePicker(),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.filter_list_rounded,
                              color: Colors.green.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Filter',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Date Range Display
              if (_startDate != null || _endDate != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200, width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _startDate != null && _endDate != null
                                    ? '${DateFormat('MMM dd, yyyy').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}'
                                    : _startDate != null
                                    ? 'From ${DateFormat('MMM dd, yyyy').format(_startDate!)}'
                                    : 'Until ${DateFormat('MMM dd, yyyy').format(_endDate!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _startDate = null;
                              _endDate = null;
                              _currentPage = 0;
                            });
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Obx(() {
                if (_homeController.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  );
                }

                final filteredHistory = _getFilteredHistory();

                if (filteredHistory.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.filter_alt_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _startDate != null || _endDate != null
                                ? 'No scans found in the selected date range'
                                : 'No scan history available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor:
                          MaterialStateProperty.resolveWith<Color?>(
                            (states) => Colors.green.shade100,
                          ),
                      dataRowColor: MaterialStateProperty.resolveWith<Color?>((
                        states,
                      ) {
                        if (states.contains(MaterialState.selected)) {
                          return Colors.green.shade50;
                        }
                        return Colors.white;
                      }),
                      columnSpacing: 32,
                      horizontalMargin: 24,
                      dividerThickness: 0.8,
                      columns: const [
                        DataColumn(
                          label: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Date',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Plant Name',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Condition',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Treatment',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Actions',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                      rows:
                          _getPaginatedRows().asMap().entries.map((entry) {
                            final idx = entry.key;
                            final row = entry.value;
                            return DataRow(
                              color: MaterialStateProperty.resolveWith<Color?>((
                                states,
                              ) {
                                if (idx % 2 == 0) {
                                  return Colors.green.withOpacity(0.04);
                                }
                                return Colors.white;
                              }),
                              cells: [
                                DataCell(
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                      horizontal: 4.0,
                                    ),
                                    child: Text(
                                      row['timestamp'] is Timestamp
                                          ? DateFormat('MMM dd, yyyy').format(
                                            (row['timestamp'] as Timestamp)
                                                .toDate(),
                                          )
                                          : row['timestamp']?.toString() ??
                                              'N/A',
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                      horizontal: 4.0,
                                    ),
                                    child: Text(
                                      row['name']?.toString() ?? 'N/A',
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                      horizontal: 4.0,
                                    ),
                                    child: Builder(
                                      builder: (context) {
                                        final isHealthy = _isPlantHealthy(
                                          row['disease']?.toString(),
                                        );
                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Icon for healthy plants
                                            isHealthy
                                                ? Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .check_circle_rounded,
                                                      size: 18,
                                                      color:
                                                          Colors.green.shade700,
                                                    ),
                                                    const SizedBox(width: 8),
                                                  ],
                                                )
                                                : Row(
                                                  children: [
                                                    Icon(
                                                      Icons.warning,
                                                      size: 18,
                                                      color:
                                                          Colors.red.shade700,
                                                    ),
                                                    const SizedBox(width: 8),
                                                  ],
                                                ),
                                            Flexible(
                                              child: Text(
                                                row['disease']?.toString() ??
                                                    'N/A',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color:
                                                      isHealthy
                                                          ? Colors
                                                              .green
                                                              .shade700
                                                          : Colors.red.shade700,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                      horizontal: 4.0,
                                    ),
                                    child:
                                        _isPlantHealthy(
                                              row['disease']?.toString(),
                                            )
                                            ? const Text(
                                              'No treatment needed',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            )
                                            : TextButton(
                                              onPressed:
                                                  () => _showPlantDetailsDialog(
                                                    context,
                                                    row,
                                                  ),
                                              style: TextButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                backgroundColor: Colors.green
                                                    .withOpacity(0.1),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text(
                                                'View Treatment',
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                  ),
                                ),
                                DataCell(
                                  Center(
                                    child: IconButton(
                                      onPressed:
                                          () => _showDeleteConfirmation(
                                            context,
                                            row,
                                          ),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 22,
                                      ),
                                      tooltip: 'Delete',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              // Pagination Controls
              Obx(() {
                if (_homeController.history.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _buildPaginationControls();
              }),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredHistory() {
    final allHistory = _homeController.history;

    if (_startDate == null && _endDate == null) {
      return allHistory;
    }

    return allHistory.where((item) {
      if (item['timestamp'] == null) return false;

      DateTime itemDate;
      if (item['timestamp'] is Timestamp) {
        itemDate = (item['timestamp'] as Timestamp).toDate();
      } else if (item['timestamp'] is String) {
        itemDate = DateTime.parse(item['timestamp']);
      } else {
        return false;
      }

      // Normalize dates to just the date part (remove time)
      itemDate = DateTime(itemDate.year, itemDate.month, itemDate.day);

      bool matches = true;
      if (_startDate != null) {
        final start = DateTime(
          _startDate!.year,
          _startDate!.month,
          _startDate!.day,
        );
        matches =
            matches &&
            (itemDate.isAfter(start) || itemDate.isAtSameMomentAs(start));
      }
      if (_endDate != null) {
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
        matches =
            matches &&
            (itemDate.isBefore(end) || itemDate.isAtSameMomentAs(end));
      }

      return matches;
    }).toList();
  }

  List<Map<String, dynamic>> _getPaginatedRows() {
    final filteredHistory = _getFilteredHistory();
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(
      0,
      filteredHistory.length,
    );
    return filteredHistory.sublist(
      startIndex.clamp(0, filteredHistory.length),
      endIndex,
    );
  }

  int _getTotalPages() {
    final totalItems = _getFilteredHistory().length;
    if (totalItems == 0) return 1;
    return (totalItems / _itemsPerPage).ceil();
  }

  Future<void> _showDateRangePicker() async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = now.subtract(const Duration(days: 365));
    final DateTime lastDate = now.add(const Duration(days: 1));

    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;

    final result = await showDialog<DateTimeRange?>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.filter_list_rounded,
                                color: Colors.green.shade700,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Filter by Date Range',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.grey.shade600),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Start Date
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tempStartDate ?? now,
                          firstDate: firstDate,
                          lastDate: lastDate,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Colors.green.shade700,
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Colors.black87,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setModalState(() {
                            tempStartDate = picked;
                            if (tempEndDate != null &&
                                tempEndDate!.isBefore(picked)) {
                              tempEndDate = null;
                            }
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              color: Colors.green.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Start Date',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    tempStartDate != null
                                        ? DateFormat(
                                          'MMM dd, yyyy',
                                        ).format(tempStartDate!)
                                        : 'Select start date',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          tempStartDate != null
                                              ? Colors.black87
                                              : Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // End Date
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tempEndDate ?? (tempStartDate ?? now),
                          firstDate: tempStartDate ?? firstDate,
                          lastDate: lastDate,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Colors.green.shade700,
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Colors.black87,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setModalState(() {
                            tempEndDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              color: Colors.green.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'End Date',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    tempEndDate != null
                                        ? DateFormat(
                                          'MMM dd, yyyy',
                                        ).format(tempEndDate!)
                                        : 'Select end date',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          tempEndDate != null
                                              ? Colors.black87
                                              : Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempStartDate = null;
                                tempEndDate = null;
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Text(
                              'Clear',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop(
                                tempStartDate != null && tempEndDate != null
                                    ? DateTimeRange(
                                      start: tempStartDate!,
                                      end: tempEndDate!,
                                    )
                                    : null,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Apply Filter',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _startDate = result.start;
        _endDate = result.end;
        _currentPage = 0; // Reset to first page when filter changes
      });
    }
  }

  Widget _buildPaginationControls() {
    final totalPages = _getTotalPages();
    final totalItems = _getFilteredHistory().length;
    final startItem = totalItems == 0 ? 0 : (_currentPage * _itemsPerPage) + 1;
    final endItem = ((_currentPage + 1) * _itemsPerPage).clamp(0, totalItems);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Items info
          Flexible(
            child: Text(
              totalItems == 0
                  ? 'No items'
                  : 'Showing ${startItem}-${endItem} of $totalItems',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Pagination buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Previous button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap:
                      _currentPage > 0
                          ? () {
                            setState(() {
                              _currentPage--;
                            });
                          }
                          : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _currentPage > 0
                              ? Colors.green.shade600
                              : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow:
                          _currentPage > 0
                              ? [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                              : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chevron_left_rounded,
                          color:
                              _currentPage > 0
                                  ? Colors.white
                                  : Colors.grey.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Prev',
                          style: TextStyle(
                            color:
                                _currentPage > 0
                                    ? Colors.white
                                    : Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Page indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300, width: 1),
                ),
                child: Text(
                  'Page ${_currentPage + 1} of ${totalPages}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Next button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap:
                      _currentPage < totalPages - 1
                          ? () {
                            setState(() {
                              _currentPage++;
                            });
                          }
                          : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _currentPage < totalPages - 1
                              ? Colors.green.shade600
                              : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow:
                          _currentPage < totalPages - 1
                              ? [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                              : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Next',
                          style: TextStyle(
                            color:
                                _currentPage < totalPages - 1
                                    ? Colors.white
                                    : Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          color:
                              _currentPage < totalPages - 1
                                  ? Colors.white
                                  : Colors.grey.shade600,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPlantDetailsDialog(
    BuildContext context,
    Map<String, dynamic> plant,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.eco,
                            color: Colors.green,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          plant['name']?.toString() ?? 'N/A',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Plant Image
                    if (plant['base64Image'] != null &&
                        plant['base64Image'].toString().trim().isNotEmpty)
                      _buildPlantImage(plant['base64Image']),
                    if (plant['base64Image'] != null &&
                        plant['base64Image'].toString().trim().isNotEmpty)
                      // const SizedBox(height: 20),
                      // _buildDetailRow(
                      //   icon: Icons.calendar_today,
                      //   title: 'Date & Time',
                      //   value:
                      //       plant['timestamp'] is Timestamp
                      //           ? DateFormat('MMM dd, yyyy HH:mm').format(
                      //             (plant['timestamp'] as Timestamp).toDate(),
                      //           )
                      //           : plant['timestamp']?.toString() ?? 'N/A',
                      // ),
                      // const SizedBox(height: 16),
                      // _buildDetailRow(
                      //   icon: Icons.local_florist,
                      //   title: 'Plant Name',
                      //   value: plant['name']?.toString() ?? 'N/A',
                      // ),
                      const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.bug_report,
                      title: 'Disease',
                      value: plant['disease']?.toString() ?? 'N/A',
                      isDisease: true,
                    ),
                    if (plant['disease'] != null &&
                        !_isPlantHealthy(plant['disease']?.toString())) ...[
                      const SizedBox(height: 16),
                      _buildTreatmentSection(
                        plant['treatment']?.toString() ??
                            'No treatment available',
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Close Button
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        backgroundColor: Colors.green.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Map<String, dynamic> plant, {
    bool closeDetailsDialog = false,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text(
                'Delete Plant Record',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete this plant record?\n\n'
            'Plant: ${plant['name'] ?? 'N/A'}\n'
            'Disease: ${plant['disease'] ?? 'N/A'}\n\n'
            'This action cannot be undone.',
            style: const TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Close confirmation dialog
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }

                // Close plant details dialog if it was opened from there
                if (closeDetailsDialog && Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }

                // Delete the plant
                String? documentId = plant['documentId']?.toString();

                // Debug: Print plant data to see what we have
                print('Plant data keys: ${plant.keys}');
                print('Document ID: $documentId');

                // If documentId is missing, try to find it by matching plant data
                if (documentId == null || documentId.isEmpty) {
                  // Find the document by matching userId and name (simpler query)
                  try {
                    final userId = FirebaseAuth.instance.currentUser?.uid;
                    if (userId != null) {
                      // First try with userId and name
                      var querySnapshot =
                          await FirebaseFirestore.instance
                              .collection('plants')
                              .where('userId', isEqualTo: userId)
                              .where(
                                'name',
                                isEqualTo: plant['name']?.toString(),
                              )
                              .orderBy('timestamp', descending: true)
                              .limit(10)
                              .get();

                      // Filter results in memory to match disease and timestamp if available
                      if (querySnapshot.docs.isNotEmpty) {
                        for (var doc in querySnapshot.docs) {
                          final data = doc.data();
                          bool matches = true;

                          // Match disease
                          if (plant['disease'] != null &&
                              data['disease']?.toString() !=
                                  plant['disease']?.toString()) {
                            matches = false;
                          }

                          // Match timestamp if available (within 5 seconds tolerance)
                          if (matches &&
                              plant['timestamp'] != null &&
                              data['timestamp'] != null) {
                            Timestamp? plantTimestamp;
                            Timestamp? dataTimestamp;

                            if (plant['timestamp'] is Timestamp) {
                              plantTimestamp = plant['timestamp'] as Timestamp;
                            }
                            if (data['timestamp'] is Timestamp) {
                              dataTimestamp = data['timestamp'] as Timestamp;
                            }

                            if (plantTimestamp != null &&
                                dataTimestamp != null) {
                              final diff =
                                  (plantTimestamp.millisecondsSinceEpoch -
                                          dataTimestamp.millisecondsSinceEpoch)
                                      .abs();
                              if (diff > 5000) {
                                // 5 seconds tolerance
                                matches = false;
                              }
                            }
                          }

                          if (matches) {
                            documentId = doc.id;
                            print('Found document ID: $documentId');
                            break;
                          }
                        }
                      }

                      if (documentId == null || documentId.isEmpty) {
                        print('No matching document found');
                      }
                    }
                  } catch (e) {
                    print('Error finding document ID: $e');
                  }
                }

                if (documentId != null && documentId.isNotEmpty) {
                  await _homeController.deletePlant(documentId);
                  // Refresh the list
                  if (mounted) {
                    await _homeController.fetchPlants();
                  }
                } else {
                  Get.snackbar(
                    'Error',
                    'Unable to delete: Plant ID not found. Please try refreshing the page.',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 3),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    bool isDisease = false,
    bool isTreatment = false,
  }) {
    // Check if plant is healthy
    final isHealthy = isDisease && _isPlantHealthy(value);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isDisease || isTreatment
                ? (isHealthy
                    ? Colors.green.withOpacity(0.1)
                    : isDisease
                    ? Colors.red.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1))
                : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  isDisease || isTreatment
                      ? (isHealthy
                          ? Colors.green.withOpacity(0.2)
                          : isDisease
                          ? Colors.red.withOpacity(0.2)
                          : Colors.green.withOpacity(0.2))
                      : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isHealthy ? Icons.check_circle_rounded : icon,
              color:
                  isDisease || isTreatment
                      ? (isHealthy
                          ? Colors.green.shade700
                          : isDisease
                          ? Colors.red
                          : Colors.green)
                      : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        isDisease || isTreatment
                            ? (isHealthy
                                ? Colors.green.shade700
                                : isDisease
                                ? Colors.red
                                : Colors.green)
                            : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentSection(String treatmentText) {
    // Parse the treatment text to identify sections and bullet points
    final sections = <Map<String, dynamic>>[];
    final lines = treatmentText.split('\n');

    String? currentSection;
    List<String> currentItems = [];

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Check if it's a section header (ends with colon and contains keywords)
      final isSectionHeader =
          line.endsWith(':') &&
          (line.toLowerCase().contains('actions') ||
              line.toLowerCase().contains('measures') ||
              line.toLowerCase().contains('monitoring') ||
              line.toLowerCase().contains('preventive') ||
              line.toLowerCase().contains('immediate'));

      if (isSectionHeader) {
        // Save previous section if exists
        if (currentSection != null && currentItems.isNotEmpty) {
          sections.add({
            'title': currentSection,
            'items': List<String>.from(currentItems),
          });
        }
        currentSection = line.replaceAll(':', '').trim();
        currentItems = [];
      } else {
        // Check if it's a bullet point (starts with bullet, dash, or asterisk)
        final isBullet =
            line.startsWith('•') ||
            line.startsWith('-') ||
            line.startsWith('*') ||
            (line.length > 0 && RegExp(r'^\s*[•\-\*]').hasMatch(line));

        if (isBullet) {
          // It's a bullet point - clean it up
          String item = line.replaceFirst(RegExp(r'^\s*[•\-\*]\s*'), '').trim();
          if (item.isNotEmpty) {
            // If no current section, create a default one
            if (currentSection == null) {
              currentSection = 'Treatment';
            }
            currentItems.add(item);
          }
        } else if (currentSection != null) {
          // Regular text line in a section
          currentItems.add(line);
        } else {
          // If no section yet, treat as general text
          if (currentSection == null) {
            currentSection = 'Treatment';
          }
          currentItems.add(line);
        }
      }
    }

    // Add the last section
    if (currentSection != null && currentItems.isNotEmpty) {
      sections.add({
        'title': currentSection,
        'items': List<String>.from(currentItems),
      });
    }

    // If no sections found, treat entire text as single section
    if (sections.isEmpty) {
      sections.add({
        'title': 'Treatment',
        'items': [treatmentText],
      });
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Treatment Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.medical_services,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Treatment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          // Treatment Content (Scrollable)
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...sections.asMap().entries.map((entry) {
                    final index = entry.key;
                    final section = entry.value;
                    final sectionTitle = section['title'] as String;
                    final items = section['items'] as List<String>;

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < sections.length - 1 ? 16 : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section Title
                          if (sectionTitle != 'Treatment')
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                sectionTitle,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          // Section Items
                          ...items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                bottom: 8,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 7, right: 10),
                                    child: Icon(
                                      Icons.circle,
                                      size: 6,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.green,
                                        height: 1.6,
                                        letterSpacing: 0.2,
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantImage(dynamic base64Image) {
    try {
      if (base64Image != null && base64Image.toString().trim().isNotEmpty) {
        String imageString = base64Image.toString().trim();

        // Remove data URL prefix if present (e.g., "data:image/png;base64,")
        if (imageString.contains(',')) {
          imageString = imageString.split(',').last;
        }

        Uint8List imageBytes = base64Decode(imageString);
        return Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              imageBytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) {
                // If image fails to load, show placeholder
                return Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported_rounded,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Image not available',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      // If decoding fails, show placeholder
      debugPrint('Error decoding plant image: $e');
    }

    // Default placeholder if no image
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_florist_rounded,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'No image available',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showFAQsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.help_outline_rounded,
                        color: Colors.orange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Frequently Asked Questions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFAQItem(
                          question: 'How do I scan my plant for diseases?',
                          answer:
                              'Tap the camera button at the bottom of the screen, take a photo of your plant\'s leaves or affected area, and wait for the AI to analyze it. The results will show any detected diseases and treatment recommendations.',
                        ),
                        const SizedBox(height: 16),
                        _buildFAQItem(
                          question:
                              'What should I do if a disease is detected?',
                          answer:
                              'The app will provide specific treatment recommendations based on the detected disease. Follow the treatment plan provided, which may include organic remedies, pruning instructions, or when to consult a professional.',
                        ),
                        const SizedBox(height: 16),
                        _buildFAQItem(
                          question: 'How accurate is the disease detection?',
                          answer:
                              'Our AI model has been trained on thousands of plant disease images. While it\'s highly accurate, always consider consulting a professional for critical cases or when symptoms persist.',
                        ),
                        const SizedBox(height: 16),
                        _buildFAQItem(
                          question: 'Can I track my plant\'s health over time?',
                          answer:
                              'Yes! Your scan history is automatically saved. You can view past scans, track disease progression, and monitor treatment effectiveness through the Scan History section.',
                        ),
                        const SizedBox(height: 16),
                        _buildFAQItem(
                          question:
                              'What if my plant shows "No disease detected"?',
                          answer:
                              'Great news! Your plant appears healthy. Continue with regular care: proper watering, adequate sunlight, and periodic checks. Use the daily reminder feature to maintain your plant care routine.',
                        ),
                        const SizedBox(height: 16),
                        _buildFAQItem(
                          question: 'How can I use the AI Chatbot?',
                          answer:
                              'Tap on the AI Chatbot card to access our AI assistant. You can ask questions about plant care, treatment methods, disease prevention, and get tutorials on various plant care topics.',
                        ),
                        const SizedBox(height: 16),
                        _buildFAQItem(
                          question: 'Is my plant data secure?',
                          answer:
                              'Yes, all your plant scan data is securely stored and associated only with your account. We respect your privacy and use your data solely to improve your plant care experience.',
                        ),
                        const SizedBox(height: 16),
                        _buildFAQItem(
                          question: 'What plants are supported?',
                          answer:
                              'CropCure supports a wide variety of common garden plants, vegetables, fruits, and houseplants. The AI is continuously learning to recognize more plant species and diseases.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        backgroundColor: Colors.orange.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, size: 18, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

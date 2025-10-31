import 'dart:convert';
import 'package:cropcure/user/home/home_controller.dart';
import 'package:cropcure/user/profile/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _profileController = Get.put(ProfileController());
  final _homeController = Get.put(HomeController());
  final history = RxList<Map<String, dynamic>>([]);
  int _currentPage = 0;
  static const int _itemsPerPage = 5;
  DateTime? _startDate;
  DateTime? _endDate;

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
                    diseaseScanAndHistoryCard(),
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

  Widget diseaseScanAndHistoryCard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.analytics, color: Colors.green, size: 28),
                  SizedBox(width: 10),
                  Text(
                    "Disease Scans & History",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Chart
              Obx(() {
                if (_homeController.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  );
                }

                if (_homeController.history.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No scan history yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final scansMap = _homeController.diseaseScansPerDay;
                final days = scansMap.keys.toList()..sort();
                final diseaseScans = days.map((d) => scansMap[d]!).toList();

                return SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        getDrawingHorizontalLine:
                            (value) => FlLine(
                              color: Colors.green.shade50,
                              strokeWidth: 1,
                            ),
                        getDrawingVerticalLine:
                            (value) => FlLine(
                              color: Colors.green.shade50,
                              strokeWidth: 1,
                            ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget:
                                (value, meta) => Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              int idx = value.toInt();
                              if (idx >= 0 && idx < days.length) {
                                return Text(
                                  days[idx],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                            interval: 1,
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      minX: 0,
                      maxX: (days.length - 1).toDouble(),
                      minY: 0,
                      maxY:
                          (diseaseScans.isEmpty
                                  ? 1
                                  : diseaseScans.reduce(
                                        (a, b) => a > b ? a : b,
                                      ) +
                                      2)
                              .toDouble(),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            diseaseScans.length,
                            (i) => FlSpot(
                              i.toDouble(),
                              diseaseScans[i].toDouble(),
                            ),
                          ),
                          isCurved: true,
                          color: Colors.green,
                          barWidth: 4,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter:
                                (spot, percent, bar, index) =>
                                    FlDotCirclePainter(
                                      radius: 6,
                                      color: Colors.white,
                                      strokeWidth: 3,
                                      strokeColor: Colors.green,
                                    ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.withOpacity(0.3),
                                Colors.green.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                '${spot.y.toInt()}',
                                const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
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
                              'Disease',
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
                                    child: Text(
                                      row['disease']?.toString() ?? 'N/A',
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
                                    child:
                                        row['disease']
                                                    ?.toString()
                                                    .trim()
                                                    .toLowerCase() ==
                                                'no disease detected'
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
                        const Text(
                          'Plant Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildDetailRow(
                      icon: Icons.calendar_today,
                      title: 'Date & Time',
                      value:
                          plant['timestamp'] is Timestamp
                              ? DateFormat('MMM dd, yyyy HH:mm').format(
                                (plant['timestamp'] as Timestamp).toDate(),
                              )
                              : plant['timestamp']?.toString() ?? 'N/A',
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.local_florist,
                      title: 'Plant Name',
                      value: plant['name']?.toString() ?? 'N/A',
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.bug_report,
                      title: 'Disease',
                      value: plant['disease']?.toString() ?? 'N/A',
                      isDisease: true,
                    ),
                    if (plant['disease'] != null &&
                        plant['disease'].toString().trim().toLowerCase() !=
                            'no disease detected') ...[
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        icon: Icons.medical_services,
                        title: 'Treatment',
                        value:
                            plant['treatment']?.toString() ??
                            'No treatment available',
                        isTreatment: true,
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
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
                  ],
                ),
              ),
            ),
          ),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isDisease || isTreatment
                ? (isDisease
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
                      ? (isDisease
                          ? Colors.red.withOpacity(0.2)
                          : Colors.green.withOpacity(0.2))
                      : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color:
                  isDisease || isTreatment
                      ? (isDisease ? Colors.red : Colors.green)
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
                            ? (isDisease ? Colors.red : Colors.green)
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
}

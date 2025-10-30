import 'package:cropcure/admin/controller.dart';
import 'package:cropcure/admin/login.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ActivityLogScreenState createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  String searchQuery = "";
  String filterType = "All"; // Filter types: All, Online, Offline
  final Controller controller = Get.put(Controller());

  // Function to show logout confirmation dialog
  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: Colors.red.shade700,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Confirm Logout',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Are you sure you want to logout?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red.shade500, Colors.red.shade700],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _logout();
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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
  }

  // Logout action
  void _logout() {
    Get.offAll(() => MyLogin());
    Get.snackbar('Success', 'Logged Out Success!');
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    await controller.fetchPlants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        toolbarHeight: 80,
        title: Padding(
          padding: const EdgeInsets.only(top: 20, left: 30),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics Dashboard',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Monitor disease scans and trends',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 40, top: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200, width: 1),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.logout_rounded,
                  color: Colors.red.shade700,
                  size: 22,
                ),
                onPressed: _showLogoutDialog,
                tooltip: 'Logout',
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsCards(),
              const SizedBox(height: 30),
              diseaseScanAndHistoryCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Obx(() {
      final totalScans = controller.history.length;
      final diseaseDetected = controller.totalDiseases;
      final healthyScans = totalScans - diseaseDetected;

      return LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 900;

          return Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _buildStatCard(
                title: 'Total Scans',
                value: totalScans.toString(),
                icon: Icons.camera_alt_rounded,
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                width:
                    isSmallScreen
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 40) / 3,
              ),
              _buildStatCard(
                title: 'Diseases Detected',
                value: diseaseDetected.toString(),
                icon: Icons.warning_amber_rounded,
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.orange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                width:
                    isSmallScreen
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 40) / 3,
              ),
              _buildStatCard(
                title: 'Healthy Plants',
                value: healthyScans.toString(),
                icon: Icons.eco_rounded,
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                width:
                    isSmallScreen
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 40) / 3,
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive dimensions
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 800;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 20.0 : 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade600,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.trending_up_rounded,
                        color: Colors.white,
                        size: isSmallScreen ? 20 : 24,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Disease Scans & History",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 20 : 24,
                            color: const Color(0xFF1A1A1A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Track and analyze disease detection trends",
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 13,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 24 : 30),
                // Chart
                Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    );
                  }

                  if (controller.history.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: isSmallScreen ? 36 : 48,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          Text(
                            'No scan history yet',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final scansMap = controller.diseaseScansPerDay;
                  final days = scansMap.keys.toList()..sort();
                  final diseaseScans = days.map((d) => scansMap[d]!).toList();

                  return Container(
                    padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                    ),
                    child: SizedBox(
                      height: isSmallScreen ? 180 : 240,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            getDrawingHorizontalLine:
                                (value) => FlLine(
                                  color: Colors.grey.shade300,
                                  strokeWidth: 1,
                                  dashArray: [5, 5],
                                ),
                            getDrawingVerticalLine:
                                (value) => FlLine(
                                  color: Colors.grey.shade300,
                                  strokeWidth: 1,
                                  dashArray: [5, 5],
                                ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: isSmallScreen ? 24 : 32,
                                getTitlesWidget:
                                    (value, meta) => Text(
                                      value.toInt().toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF6B7280),
                                        fontSize: isSmallScreen ? 11 : 13,
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
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF6B7280),
                                        fontSize: isSmallScreen ? 11 : 13,
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                                interval: isSmallScreen ? 2 : 1,
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
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 2,
                            ),
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
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade400,
                                  Colors.green.shade600,
                                ],
                              ),
                              barWidth: isSmallScreen ? 3 : 4,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter:
                                    (spot, percent, bar, index) =>
                                        FlDotCirclePainter(
                                          radius: isSmallScreen ? 5 : 7,
                                          color: Colors.white,
                                          strokeWidth: isSmallScreen ? 2.5 : 3,
                                          strokeColor: Colors.green.shade600,
                                        ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.shade400.withOpacity(0.25),
                                    Colors.green.shade400.withOpacity(0.05),
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
                              tooltipPadding: const EdgeInsets.all(10),
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  return LineTooltipItem(
                                    'Scans: ${spot.y.toInt()}',
                                    TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSmallScreen ? 13 : 15,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                SizedBox(height: isSmallScreen ? 24 : 32),
                // Table
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        color: Colors.green.shade700,
                        size: isSmallScreen ? 18 : 20,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Text(
                      "Scan History",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 18 : 20,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),
                Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    );
                  }

                  if (controller.history.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                        child: Text(
                          'No scan history available',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth:
                                isSmallScreen
                                    ? screenWidth - 40
                                    : screenWidth - 100,
                          ),
                          child: DataTable(
                            headingRowHeight: isSmallScreen ? 50 : 56,
                            dataRowMinHeight: isSmallScreen ? 50 : 56,
                            dataRowMaxHeight: isSmallScreen ? 60 : 68,
                            headingRowColor:
                                WidgetStateProperty.resolveWith<Color?>(
                                  (states) => const Color(0xFFF9FAFB),
                                ),
                            dataRowColor:
                                WidgetStateProperty.resolveWith<Color?>((
                                  states,
                                ) {
                                  if (states.contains(WidgetState.selected)) {
                                    return Colors.green.shade50;
                                  }
                                  return Colors.white;
                                }),
                            columnSpacing: isSmallScreen ? 20 : 40,
                            horizontalMargin: isSmallScreen ? 20 : 28,
                            dividerThickness: 1,
                            columns: [
                              DataColumn(
                                label: Text(
                                  'Timestamp',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF374151),
                                    fontSize: isSmallScreen ? 13 : 14,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Plant Name',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF374151),
                                    fontSize: isSmallScreen ? 13 : 14,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Disease',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF374151),
                                    fontSize: isSmallScreen ? 13 : 14,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Treatment',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF374151),
                                    fontSize: isSmallScreen ? 13 : 14,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                            rows:
                                controller.history.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final row = entry.value;
                                  return DataRow(
                                    color:
                                        WidgetStateProperty.resolveWith<Color?>(
                                          (states) {
                                            if (idx % 2 == 0) {
                                              return const Color(0xFFFAFAFA);
                                            }
                                            return Colors.white;
                                          },
                                        ),
                                    cells: [
                                      DataCell(
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time_rounded,
                                              size: isSmallScreen ? 14 : 16,
                                              color: Colors.grey.shade500,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              row['timestamp'] is Timestamp
                                                  ? DateFormat(
                                                    'MMM dd, yyyy HH:mm',
                                                  ).format(
                                                    (row['timestamp']
                                                            as Timestamp)
                                                        .toDate(),
                                                  )
                                                  : row['timestamp']
                                                          ?.toString() ??
                                                      'N/A',
                                              style: TextStyle(
                                                fontSize:
                                                    isSmallScreen ? 13 : 14,
                                                color: const Color(0xFF4B5563),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.local_florist_rounded,
                                              size: isSmallScreen ? 14 : 16,
                                              color: Colors.green.shade400,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              row['name']?.toString() ?? 'N/A',
                                              style: TextStyle(
                                                fontSize:
                                                    isSmallScreen ? 13 : 14,
                                                color: const Color(0xFF1F2937),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isSmallScreen ? 8 : 12,
                                            vertical: isSmallScreen ? 4 : 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                row['disease']
                                                            ?.toString()
                                                            .trim()
                                                            .toLowerCase() ==
                                                        'no disease detected'
                                                    ? Colors.green.shade50
                                                    : Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                row['disease']
                                                            ?.toString()
                                                            .trim()
                                                            .toLowerCase() ==
                                                        'no disease detected'
                                                    ? Icons.check_circle_rounded
                                                    : Icons.warning_rounded,
                                                size: isSmallScreen ? 14 : 16,
                                                color:
                                                    row['disease']
                                                                ?.toString()
                                                                .trim()
                                                                .toLowerCase() ==
                                                            'no disease detected'
                                                        ? Colors.green.shade700
                                                        : Colors.red.shade700,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                row['disease']?.toString() ??
                                                    'N/A',
                                                style: TextStyle(
                                                  fontSize:
                                                      isSmallScreen ? 12 : 13,
                                                  color:
                                                      row['disease']
                                                                  ?.toString()
                                                                  .trim()
                                                                  .toLowerCase() ==
                                                              'no disease detected'
                                                          ? Colors
                                                              .green
                                                              .shade700
                                                          : Colors.red.shade700,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        row['disease']
                                                    ?.toString()
                                                    .trim()
                                                    .toLowerCase() ==
                                                'no disease detected'
                                            ? Row(
                                              children: [
                                                Icon(
                                                  Icons
                                                      .health_and_safety_rounded,
                                                  size: isSmallScreen ? 14 : 16,
                                                  color: Colors.grey.shade400,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'No treatment needed',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize:
                                                        isSmallScreen ? 12 : 13,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ],
                                            )
                                            : Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.green.shade400,
                                                    Colors.green.shade600,
                                                  ],
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.green
                                                        .withOpacity(0.3),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: TextButton.icon(
                                                onPressed:
                                                    () =>
                                                        _showPlantDetailsDialog(
                                                          context,
                                                          row,
                                                        ),
                                                style: TextButton.styleFrom(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal:
                                                        isSmallScreen ? 12 : 16,
                                                    vertical:
                                                        isSmallScreen ? 6 : 8,
                                                  ),
                                                ),
                                                icon: Icon(
                                                  Icons.visibility_rounded,
                                                  color: Colors.white,
                                                  size: isSmallScreen ? 14 : 16,
                                                ),
                                                label: Text(
                                                  'View Treatment',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        isSmallScreen ? 12 : 13,
                                                    fontWeight: FontWeight.w600,
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
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
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
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: 500,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade400,
                                Colors.green.shade600,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Plant Details',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Scan information',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(
                      icon: Icons.access_time_rounded,
                      title: 'Date & Time',
                      value:
                          plant['timestamp'] is Timestamp
                              ? DateFormat('MMM dd, yyyy HH:mm').format(
                                (plant['timestamp'] as Timestamp).toDate(),
                              )
                              : plant['timestamp']?.toString() ?? 'N/A',
                    ),
                    const SizedBox(height: 14),
                    _buildDetailRow(
                      icon: Icons.local_florist_rounded,
                      title: 'Plant Name',
                      value: plant['name']?.toString() ?? 'N/A',
                    ),
                    const SizedBox(height: 14),
                    _buildDetailRow(
                      icon: Icons.warning_rounded,
                      title: 'Disease',
                      value: plant['disease']?.toString() ?? 'N/A',
                      isDisease: true,
                    ),
                    if (plant['disease'] != null &&
                        plant['disease'].toString().trim().toLowerCase() !=
                            'no disease detected') ...[
                      const SizedBox(height: 14),
                      _buildDetailRow(
                        icon: Icons.medical_services_rounded,
                        title: 'Treatment',
                        value:
                            plant['treatment']?.toString() ??
                            'No treatment available',
                        isTreatment: true,
                      ),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade400,
                              Colors.green.shade600,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    bool isDisease = false,
    bool isTreatment = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDisease || isTreatment
                  ? (isDisease ? Colors.red.shade200 : Colors.green.shade200)
                  : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient:
                  isDisease || isTreatment
                      ? (isDisease
                          ? LinearGradient(
                            colors: [Colors.red.shade400, Colors.red.shade600],
                          )
                          : LinearGradient(
                            colors: [
                              Colors.green.shade400,
                              Colors.green.shade600,
                            ],
                          ))
                      : LinearGradient(
                        colors: [Colors.grey.shade400, Colors.grey.shade500],
                      ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: (isDisease || isTreatment
                          ? (isDisease ? Colors.red : Colors.green)
                          : Colors.grey)
                      .withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color:
                        isDisease || isTreatment
                            ? (isDisease
                                ? Colors.red.shade700
                                : Colors.green.shade700)
                            : const Color(0xFF1F2937),
                    fontWeight: FontWeight.w600,
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

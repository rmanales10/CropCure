import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cropcure/admin/controller.dart';
import 'package:fl_chart/fl_chart.dart';

class UserDetailView extends StatefulWidget {
  final Controller controller;

  const UserDetailView({super.key, required this.controller});

  @override
  State<UserDetailView> createState() => _UserDetailViewState();
}

class _UserDetailViewState extends State<UserDetailView> {
  int _currentPage = 0;
  static const int _itemsPerPage = 10;
  String? _lastSelectedUserId;

  @override
  void initState() {
    super.initState();
    _lastSelectedUserId = widget.controller.selectedUserId.value;
  }

  @override
  Widget build(BuildContext context) {
    // Reset page when user changes
    final currentUserId = widget.controller.selectedUserId.value;
    if (_lastSelectedUserId != currentUserId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _currentPage = 0;
          _lastSelectedUserId = currentUserId;
        });
      });
    }
    return Obx(() {
      final userInfo = widget.controller.selectedUserInfo;
      if (userInfo == null) {
        return const Center(child: Text('User not found'));
      }

      final diseaseDistribution = widget.controller.getUserDiseaseDistribution(
        userInfo['uid'],
      );

      final isMobile = MediaQuery.of(context).size.width < 768;

      return SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button & Header
            Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      widget.controller.selectedUserId.value = '';
                      setState(() {
                        _currentPage = 0;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: EdgeInsets.all(isMobile ? 8 : 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.grey.shade700,
                        size: isMobile ? 18 : 20,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 16),
                _buildProfileImage(userInfo, isMobile: isMobile),
                SizedBox(width: isMobile ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userInfo['fullname'] ?? 'Unknown User',
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      SizedBox(height: isMobile ? 2 : 4),
                      Text(
                        userInfo['email'] ?? 'N/A',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 20 : 30),
            // User Stats Cards
            isMobile
                ? Column(
                  children: [
                    _buildUserDetailStatCard(
                      'Total Scans',
                      userInfo['totalScans']?.toString() ?? '0',
                      Icons.camera_alt_rounded,
                      Colors.blue,
                      isMobile: isMobile,
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    _buildUserDetailStatCard(
                      'Diseases Detected',
                      userInfo['diseaseDetected']?.toString() ?? '0',
                      Icons.warning_amber_rounded,
                      Colors.red,
                      isMobile: isMobile,
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    _buildUserDetailStatCard(
                      'Healthy Plants',
                      userInfo['healthyScans']?.toString() ?? '0',
                      Icons.eco_rounded,
                      Colors.green,
                      isMobile: isMobile,
                    ),
                  ],
                )
                : Row(
                  children: [
                    Expanded(
                      child: _buildUserDetailStatCard(
                        'Total Scans',
                        userInfo['totalScans']?.toString() ?? '0',
                        Icons.camera_alt_rounded,
                        Colors.blue,
                        isMobile: isMobile,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildUserDetailStatCard(
                        'Diseases Detected',
                        userInfo['diseaseDetected']?.toString() ?? '0',
                        Icons.warning_amber_rounded,
                        Colors.red,
                        isMobile: isMobile,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildUserDetailStatCard(
                        'Healthy Plants',
                        userInfo['healthyScans']?.toString() ?? '0',
                        Icons.eco_rounded,
                        Colors.green,
                        isMobile: isMobile,
                      ),
                    ),
                  ],
                ),
            SizedBox(height: isMobile ? 20 : 30),
            // Disease Distribution Chart
            if (diseaseDistribution.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.bar_chart_rounded,
                            color: Colors.red.shade700,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Disease Distribution',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 16 : 20),
                    ...(() {
                      // Sort diseases by count (descending) and take top ones
                      final sortedDiseases =
                          diseaseDistribution.entries.toList()
                            ..sort((a, b) => b.value.compareTo(a.value));

                      // Take top 10 diseases for better visualization
                      final topDiseases = sortedDiseases.take(10).toList();

                      if (topDiseases.isEmpty) {
                        return [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: Text(
                                'No diseases detected yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ];
                      }

                      final diseaseNames =
                          topDiseases.map((e) => e.key).toList();
                      final diseaseCounts =
                          topDiseases.map((e) => e.value).toList();
                      final maxCount =
                          diseaseCounts.isNotEmpty
                              ? diseaseCounts.reduce((a, b) => a > b ? a : b)
                              : 1;

                      return [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isSmallScreen = constraints.maxWidth < 900;
                            final screenWidth = constraints.maxWidth;

                            return Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth:
                                      isSmallScreen
                                          ? screenWidth - 48
                                          : screenWidth - 100,
                                ),
                                child: SizedBox(
                                  height: isSmallScreen ? 280 : 350,
                                  child: BarChart(
                                    BarChartData(
                                      gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: false,
                                        horizontalInterval:
                                            maxCount > 10
                                                ? (maxCount / 10)
                                                    .ceil()
                                                    .toDouble()
                                                : 1,
                                        getDrawingHorizontalLine:
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
                                            reservedSize:
                                                isSmallScreen ? 30 : 40,
                                            getTitlesWidget:
                                                (value, meta) => Text(
                                                  value.toInt().toString(),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(
                                                      0xFF6B7280,
                                                    ),
                                                    fontSize:
                                                        isSmallScreen ? 10 : 12,
                                                  ),
                                                ),
                                          ),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize:
                                                isSmallScreen ? 60 : 80,
                                            getTitlesWidget: (value, meta) {
                                              int idx = value.toInt();
                                              if (idx >= 0 &&
                                                  idx < diseaseNames.length) {
                                                // Truncate long disease names for better display
                                                final name = diseaseNames[idx];
                                                // Truncate to 15 characters and add ellipsis
                                                final displayName =
                                                    name.length > 15
                                                        ? '${name.substring(0, 15)}...'
                                                        : name;
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 8.0,
                                                      ),
                                                  child: Tooltip(
                                                    message:
                                                        name, // Show full name on hover
                                                    child: Text(
                                                      displayName,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: const Color(
                                                          0xFF6B7280,
                                                        ),
                                                        fontSize:
                                                            isSmallScreen
                                                                ? 9
                                                                : 11,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                );
                                              }
                                              return const SizedBox.shrink();
                                            },
                                            interval: 1,
                                          ),
                                        ),
                                        topTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                        rightTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                      ),
                                      borderData: FlBorderData(
                                        show: true,
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 2,
                                        ),
                                      ),
                                      barGroups: List.generate(
                                        diseaseCounts.length,
                                        (index) => BarChartGroupData(
                                          x: index,
                                          barRods: [
                                            BarChartRodData(
                                              toY:
                                                  diseaseCounts[index]
                                                      .toDouble(),
                                              color: Colors.red,
                                              width: isSmallScreen ? 20 : 28,
                                              borderRadius:
                                                  const BorderRadius.only(
                                                    topLeft: Radius.circular(4),
                                                    topRight: Radius.circular(
                                                      4,
                                                    ),
                                                  ),
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.red.shade600,
                                                  Colors.red.shade400,
                                                ],
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      maxY: (maxCount + 1).toDouble(),
                                      barTouchData: BarTouchData(
                                        enabled: true,
                                        touchTooltipData: BarTouchTooltipData(
                                          getTooltipItem: (
                                            group,
                                            groupIndex,
                                            rod,
                                            rodIndex,
                                          ) {
                                            final diseaseIndex =
                                                group.x.toInt();
                                            if (diseaseIndex >= 0 &&
                                                diseaseIndex <
                                                    diseaseNames.length) {
                                              final diseaseName =
                                                  diseaseNames[diseaseIndex];
                                              final count = rod.toY.toInt();

                                              return BarTooltipItem(
                                                '$diseaseName\nTotal: $count',
                                                TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize:
                                                      isSmallScreen ? 12 : 14,
                                                ),
                                              );
                                            }
                                            return BarTooltipItem(
                                              'Count: ${rod.toY.toInt()}',
                                              TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize:
                                                    isSmallScreen ? 13 : 15,
                                              ),
                                            );
                                          },
                                          tooltipMargin: 8,
                                          tooltipPadding: const EdgeInsets.all(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ];
                    })(),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 20 : 30),
            ],
            // Scan History Table
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isMobile ? 6 : 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.history_rounded,
                          color: Colors.blue.shade700,
                          size: isMobile ? 18 : 20,
                        ),
                      ),
                      SizedBox(width: isMobile ? 10 : 12),
                      Text(
                        'Scan History',
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 16 : 20),
                  if (widget.controller.selectedUserHistory.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.history_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No scan history for this user',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmallScreen = constraints.maxWidth < 900;
                        final screenWidth = constraints.maxWidth;
                        final isMobileScreen =
                            MediaQuery.of(context).size.width < 768;

                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
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
                                          ? screenWidth - 48
                                          : screenWidth - 100,
                                ),
                                child: DataTable(
                                  headingRowHeight:
                                      isMobileScreen
                                          ? 45
                                          : (isSmallScreen ? 50 : 56),
                                  dataRowMinHeight:
                                      isMobileScreen
                                          ? 45
                                          : (isSmallScreen ? 50 : 56),
                                  dataRowMaxHeight:
                                      isMobileScreen
                                          ? 55
                                          : (isSmallScreen ? 60 : 68),
                                  headingRowColor:
                                      WidgetStateProperty.resolveWith<Color?>(
                                        (states) => const Color(0xFFF9FAFB),
                                      ),
                                  columnSpacing:
                                      isMobileScreen
                                          ? 12
                                          : (isSmallScreen ? 20 : 60),
                                  horizontalMargin:
                                      isMobileScreen
                                          ? 12
                                          : (isSmallScreen ? 20 : 40),
                                  dividerThickness: 1,
                                  columns: [
                                    DataColumn(
                                      label: Text(
                                        'Timestamp',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF374151),
                                          fontSize:
                                              isMobileScreen
                                                  ? 12
                                                  : (isSmallScreen ? 13 : 14),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Plant Name',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF374151),
                                          fontSize:
                                              isMobileScreen
                                                  ? 12
                                                  : (isSmallScreen ? 13 : 14),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Condition',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF374151),
                                          fontSize:
                                              isMobileScreen
                                                  ? 12
                                                  : (isSmallScreen ? 13 : 14),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Treatment',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF374151),
                                          fontSize:
                                              isMobileScreen
                                                  ? 12
                                                  : (isSmallScreen ? 13 : 14),
                                        ),
                                      ),
                                    ),
                                  ],
                                  rows:
                                      _getPaginatedRows().asMap().entries.map((
                                        entry,
                                      ) {
                                        final idx = entry.key;
                                        final row = entry.value;
                                        // Use controller's isPlantHealthy method to properly detect healthy plants
                                        final isHealthy = widget.controller
                                            .isPlantHealthy(
                                              row['disease']?.toString(),
                                            );

                                        return DataRow(
                                          color:
                                              WidgetStateProperty.resolveWith<
                                                Color?
                                              >((states) {
                                                if (idx % 2 == 0) {
                                                  return const Color(
                                                    0xFFFAFAFA,
                                                  );
                                                }
                                                return Colors.white;
                                              }),
                                          cells: [
                                            DataCell(
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.access_time_rounded,
                                                    size: 16,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    row['timestamp']
                                                            is Timestamp
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
                                                          isMobileScreen
                                                              ? 12
                                                              : 14,
                                                      color: const Color(
                                                        0xFF4B5563,
                                                      ),
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
                                                    size:
                                                        isMobileScreen
                                                            ? 14
                                                            : 16,
                                                    color:
                                                        Colors.green.shade400,
                                                  ),
                                                  SizedBox(
                                                    width:
                                                        isMobileScreen ? 6 : 8,
                                                  ),
                                                  Text(
                                                    row['name']?.toString() ??
                                                        'N/A',
                                                    style: TextStyle(
                                                      fontSize:
                                                          isMobileScreen
                                                              ? 12
                                                              : 14,
                                                      color: const Color(
                                                        0xFF1F2937,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            DataCell(
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                    ),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        isHealthy
                                                            ? Colors
                                                                .green
                                                                .shade50
                                                            : Colors
                                                                .red
                                                                .shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        isHealthy
                                                            ? Icons
                                                                .check_circle_rounded
                                                            : Icons
                                                                .warning_rounded,
                                                        size:
                                                            isMobileScreen
                                                                ? 14
                                                                : 16,
                                                        color:
                                                            isHealthy
                                                                ? Colors
                                                                    .green
                                                                    .shade700
                                                                : Colors
                                                                    .red
                                                                    .shade700,
                                                      ),
                                                      SizedBox(
                                                        width:
                                                            isMobileScreen
                                                                ? 4
                                                                : 6,
                                                      ),
                                                      Flexible(
                                                        child: Text(
                                                          row['disease']
                                                                  ?.toString() ??
                                                              'N/A',
                                                          style: TextStyle(
                                                            fontSize:
                                                                isMobileScreen
                                                                    ? 11
                                                                    : 13,
                                                            color:
                                                                isHealthy
                                                                    ? Colors
                                                                        .green
                                                                        .shade700
                                                                    : Colors
                                                                        .red
                                                                        .shade700,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                          maxLines: 2,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                    ),
                                                child:
                                                    isHealthy
                                                        ? Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .health_and_safety_rounded,
                                                              size:
                                                                  isMobileScreen
                                                                      ? 14
                                                                      : 16,
                                                              color:
                                                                  Colors
                                                                      .grey
                                                                      .shade400,
                                                            ),
                                                            SizedBox(
                                                              width:
                                                                  isMobileScreen
                                                                      ? 4
                                                                      : 6,
                                                            ),
                                                            Flexible(
                                                              child: Text(
                                                                'No treatment needed',
                                                                style: TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .grey
                                                                          .shade600,
                                                                  fontSize:
                                                                      isMobileScreen
                                                                          ? 11
                                                                          : 13,
                                                                  fontStyle:
                                                                      FontStyle
                                                                          .italic,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        )
                                                        : Material(
                                                          color:
                                                              Colors
                                                                  .transparent,
                                                          child: InkWell(
                                                            onTap:
                                                                () =>
                                                                    _showPlantDetailsDialog(
                                                                      context,
                                                                      row,
                                                                    ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        12,
                                                                    vertical: 8,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                gradient: LinearGradient(
                                                                  colors: [
                                                                    Colors
                                                                        .green
                                                                        .shade400,
                                                                    Colors
                                                                        .green
                                                                        .shade600,
                                                                  ],
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8,
                                                                    ),
                                                              ),
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .visibility_rounded,
                                                                    color:
                                                                        Colors
                                                                            .white,
                                                                    size:
                                                                        isMobileScreen
                                                                            ? 14
                                                                            : 16,
                                                                  ),
                                                                  SizedBox(
                                                                    width:
                                                                        isMobileScreen
                                                                            ? 4
                                                                            : 6,
                                                                  ),
                                                                  Text(
                                                                    'View Treatment',
                                                                    style: TextStyle(
                                                                      color:
                                                                          Colors
                                                                              .white,
                                                                      fontSize:
                                                                          isMobileScreen
                                                                              ? 11.0
                                                                              : 13.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
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
                      },
                    ),
                  const SizedBox(height: 16),
                  // Pagination Controls
                  _buildPaginationControls(),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  List<Map<String, dynamic>> _getPaginatedRows() {
    final allHistory = widget.controller.selectedUserHistory;
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, allHistory.length);
    return allHistory.sublist(startIndex.clamp(0, allHistory.length), endIndex);
  }

  int _getTotalPages() {
    final totalItems = widget.controller.selectedUserHistory.length;
    if (totalItems == 0) return 1;
    return (totalItems / _itemsPerPage).ceil();
  }

  Widget _buildPaginationControls() {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final totalPages = _getTotalPages();
    final totalItems = widget.controller.selectedUserHistory.length;
    final startItem = totalItems == 0 ? 0 : (_currentPage * _itemsPerPage) + 1;
    final endItem = ((_currentPage + 1) * _itemsPerPage).clamp(0, totalItems);

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 12 : 16,
        horizontal: isMobile ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Items info
          Text(
            totalItems == 0
                ? 'No items'
                : 'Showing ${startItem}-${endItem} of $totalItems',
            style: TextStyle(
              fontSize: isMobile ? 11 : 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          // Pagination buttons
          isMobile
              ? Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                                      ? Colors.blue.shade600
                                      : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow:
                                  _currentPage > 0
                                      ? [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.2),
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
                                  size: isMobile ? 18 : 20,
                                ),
                                SizedBox(width: isMobile ? 2 : 4),
                                Text(
                                  'Prev',
                                  style: TextStyle(
                                    color:
                                        _currentPage > 0
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                    fontSize: isMobile ? 11 : 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isMobile ? 8 : 12),
                      // Page indicator
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16,
                          vertical: isMobile ? 8 : 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Page ${_currentPage + 1} of ${totalPages}',
                          style: TextStyle(
                            fontSize: isMobile ? 11 : 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      SizedBox(width: isMobile ? 8 : 12),
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
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 12 : 16,
                              vertical: isMobile ? 8 : 10,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _currentPage < totalPages - 1
                                      ? Colors.blue.shade600
                                      : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow:
                                  _currentPage < totalPages - 1
                                      ? [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.2),
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
                                    fontSize: isMobile ? 11 : 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: isMobile ? 2 : 4),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color:
                                      _currentPage < totalPages - 1
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                  size: isMobile ? 18 : 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 8 : 0),
                ],
              )
              : Row(
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
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _currentPage > 0
                                  ? Colors.blue.shade600
                                  : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow:
                              _currentPage > 0
                                  ? [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.2),
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
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Prev',
                              style: TextStyle(
                                color:
                                    _currentPage > 0
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Page indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: Text(
                      'Page ${_currentPage + 1} of ${totalPages}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _currentPage < totalPages - 1
                                  ? Colors.blue.shade600
                                  : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow:
                              _currentPage < totalPages - 1
                                  ? [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.2),
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
                                fontSize: 13,
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
                              size: 20,
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

  Widget _buildUserDetailStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isMobile = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color == Colors.blue
                      ? Colors.blue.shade400
                      : color == Colors.red
                      ? Colors.orange.shade400
                      : Colors.green.shade400,
                  color == Colors.blue
                      ? Colors.blue.shade600
                      : color == Colors.red
                      ? Colors.orange.shade600
                      : Colors.green.shade600,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: isMobile ? 24 : 32),
          ),
          SizedBox(width: isMobile ? 12 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: isMobile ? 4 : 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
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
                      const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.bug_report,
                      title: 'Disease',
                      value: plant['disease']?.toString() ?? 'N/A',
                      isDisease: true,
                    ),
                    if (plant['disease'] != null &&
                        !widget.controller.isPlantHealthy(
                          plant['disease']?.toString(),
                        )) ...[
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
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color:
                        isDisease || isTreatment
                            ? (isDisease
                                ? Colors.red.shade700
                                : Colors.green.shade700)
                            : const Color(0xFF1A1A1A),
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(
    Map<String, dynamic> userInfo, {
    bool isMobile = false,
  }) {
    final size = isMobile ? 40.0 : 48.0;
    final iconSize = isMobile ? 20.0 : 24.0;

    try {
      final base64Image = userInfo['base64image'];
      if (base64Image != null && base64Image.toString().trim().isNotEmpty) {
        String imageString = base64Image.toString().trim();

        // Remove data URL prefix if present (e.g., "data:image/png;base64,")
        if (imageString.contains(',')) {
          imageString = imageString.split(',').last;
        }

        Uint8List imageBytes = base64Decode(imageString);
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.green.shade400],
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              imageBytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) {
                // If image fails to load, show default icon
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: iconSize,
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      // If decoding fails, show default icon
      debugPrint('Error decoding profile image: $e');
    }

    // Default icon fallback
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.person_rounded, color: Colors.white, size: iconSize),
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
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cropcure/admin/controller.dart';

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

      return SingleChildScrollView(
        padding: const EdgeInsets.all(30),
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.grey.shade700,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userInfo['fullname'] ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userInfo['email'] ?? 'N/A',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // User Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildUserDetailStatCard(
                    'Total Scans',
                    userInfo['totalScans']?.toString() ?? '0',
                    Icons.camera_alt_rounded,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildUserDetailStatCard(
                    'Diseases Detected',
                    userInfo['diseaseDetected']?.toString() ?? '0',
                    Icons.warning_amber_rounded,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildUserDetailStatCard(
                    'Healthy Plants',
                    userInfo['healthyScans']?.toString() ?? '0',
                    Icons.eco_rounded,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Disease Distribution
            if (diseaseDistribution.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(24),
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
                            Icons.pie_chart_rounded,
                            color: Colors.red.shade700,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Disease Distribution',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ...(() {
                      final sorted =
                          diseaseDistribution.entries.toList()
                            ..sort((a, b) => b.value.compareTo(a.value));
                      return sorted.take(10).map((entry) {
                        final percentage =
                            (userInfo['diseaseDetected'] as int) > 0
                                ? (entry.value /
                                    (userInfo['diseaseDetected'] as int) *
                                    100)
                                : 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value:
                                      (userInfo['diseaseDetected'] as int) > 0
                                          ? entry.value /
                                              (userInfo['diseaseDetected']
                                                  as int)
                                          : 0,
                                  backgroundColor: Colors.red.shade100,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.red.shade400,
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList();
                    })(),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
            // Scan History Table
            Container(
              padding: const EdgeInsets.all(24),
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
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.history_rounded,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Scan History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
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
                    Container(
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
                          child: DataTable(
                            headingRowHeight: 56,
                            dataRowMinHeight: 48,
                            headingRowColor:
                                WidgetStateProperty.resolveWith<Color?>(
                                  (states) => const Color(0xFFF9FAFB),
                                ),
                            columnSpacing: 40,
                            horizontalMargin: 28,
                            dividerThickness: 1,
                            columns: const [
                              DataColumn(
                                label: Text(
                                  'Timestamp',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF374151),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Plant Name',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF374151),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Disease',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF374151),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Treatment',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF374151),
                                    fontSize: 14,
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
                                  final isHealthy =
                                      row['disease']
                                          ?.toString()
                                          .trim()
                                          .toLowerCase() ==
                                      'no disease detected';

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
                                              size: 16,
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
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF4B5563),
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
                                              size: 16,
                                              color: Colors.green.shade400,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              row['name']?.toString() ?? 'N/A',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF1F2937),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  isHealthy
                                                      ? Colors.green.shade50
                                                      : Colors.red.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isHealthy
                                                      ? Icons
                                                          .check_circle_rounded
                                                      : Icons.warning_rounded,
                                                  size: 16,
                                                  color:
                                                      isHealthy
                                                          ? Colors
                                                              .green
                                                              .shade700
                                                          : Colors.red.shade700,
                                                ),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(
                                                    row['disease']
                                                            ?.toString() ??
                                                        'N/A',
                                                    style: TextStyle(
                                                      fontSize: 13,
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
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
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
                                                        size: 16,
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade400,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Flexible(
                                                        child: Text(
                                                          'No treatment needed',
                                                          style: TextStyle(
                                                            color:
                                                                Colors
                                                                    .grey
                                                                    .shade600,
                                                            fontSize: 13,
                                                            fontStyle:
                                                                FontStyle
                                                                    .italic,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                  : Material(
                                                    color: Colors.transparent,
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
                                                              horizontal: 12,
                                                              vertical: 8,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          gradient:
                                                              LinearGradient(
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
                                                        child: const Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .visibility_rounded,
                                                              color:
                                                                  Colors.white,
                                                              size: 16,
                                                            ),
                                                            SizedBox(width: 6),
                                                            Text(
                                                              'View Treatment',
                                                              style: TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontSize: 13,
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
    final totalPages = _getTotalPages();
    final totalItems = widget.controller.selectedUserHistory.length;
    final startItem = totalItems == 0 ? 0 : (_currentPage * _itemsPerPage) + 1;
    final endItem = ((_currentPage + 1) * _itemsPerPage).clamp(0, totalItems);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          // Pagination buttons
          Row(
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
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color == Colors.blue
                      ? Colors.blue.shade400
                      : color == Colors.orange
                      ? Colors.orange.shade400
                      : Colors.green.shade400,
                  color == Colors.blue
                      ? Colors.blue.shade600
                      : color == Colors.orange
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
}

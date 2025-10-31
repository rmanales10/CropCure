import 'package:cropcure/admin/controller.dart';
import 'package:cropcure/admin/pdf_service.dart';
import 'package:cropcure/admin/views/user_history_view.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String searchQuery = "";
  String filterType = "All"; // Filter types: All, Online, Offline
  final Controller controller = Get.put(Controller());
  int _selectedSidebarTab = 0; // 0 = Insights, 1 = Trends
  int _selectedNavItem =
      0; // 0 = Dashboard, 1 = Insights, 2 = Trends, 3 = User History
  bool _isSidebarCollapsed = false;

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
    Get.offAllNamed('/MyLogin');
    Get.snackbar('Success', 'Logged Out Success!');
  }

  // Generate PDF Report
  Future<void> _generatePdfReport() async {
    try {
      final totalScans = controller.history.length;
      final diseaseDetected = controller.totalDiseases;
      final healthyScans = totalScans - diseaseDetected;

      await PdfService.generateAnalyticsReport(
        historyData: controller.history,
        totalScans: totalScans,
        diseaseDetected: diseaseDetected,
        healthyScans: healthyScans,
        diseaseScansPerDay: controller.diseaseScansPerDay,
      );

      Get.snackbar(
        'Success',
        'PDF Report Generated Successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to generate PDF: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    await controller.fetchPlants();
    await controller.fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Row(
        children: [
          // Left Sidebar
          _buildLeftSidebar(),
          // Main Content
          Expanded(
            child: Column(
              children: [
                // AppBar
                _buildAppBar(),
                // Body Content
                Expanded(child: _buildMainContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isSidebarCollapsed ? 80 : 280,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Sidebar Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child:
                _isSidebarCollapsed
                    ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _isSidebarCollapsed = false;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 24,
                                height: 24,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.chevron_right,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    : Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text(
                                'Dashboard',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  height: 1.0,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isSidebarCollapsed = true;
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.chevron_left,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
          ),
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildNavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isSelected: _selectedNavItem == 0,
                  onTap: () => setState(() => _selectedNavItem = 0),
                ),
                _buildNavItem(
                  icon: Icons.lightbulb_outline_rounded,
                  label: 'Insights',
                  isSelected: _selectedNavItem == 1,
                  onTap: () => setState(() => _selectedNavItem = 1),
                ),
                _buildNavItem(
                  icon: Icons.show_chart_rounded,
                  label: 'Trends',
                  isSelected: _selectedNavItem == 2,
                  onTap: () => setState(() => _selectedNavItem = 2),
                ),
                _buildNavItem(
                  icon: Icons.people_rounded,
                  label: 'User History',
                  isSelected: _selectedNavItem == 3,
                  onTap: () => setState(() => _selectedNavItem = 3),
                ),
                const Divider(height: 32),
                _buildNavItem(
                  icon: Icons.picture_as_pdf_rounded,
                  label: 'Export PDF',
                  isSelected: false,
                  onTap: _generatePdfReport,
                ),
              ],
            ),
          ),
          // Logout Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: _buildNavItem(
              icon: Icons.logout_rounded,
              label: 'Logout',
              isSelected: false,
              onTap: _showLogoutDialog,
              isLogout: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? Colors.green.shade50
                    : (isLogout ? Colors.red.shade50 : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border:
                isSelected
                    ? Border.all(color: Colors.green.shade300, width: 1.5)
                    : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color:
                    isSelected
                        ? Colors.green.shade700
                        : (isLogout
                            ? Colors.red.shade700
                            : Colors.grey.shade600),
              ),
              if (!_isSidebarCollapsed) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color:
                          isSelected
                              ? Colors.green.shade700
                              : (isLogout
                                  ? Colors.red.shade700
                                  : Colors.grey.shade700),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Analytics Dashboard',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                const Text(
                  'Monitor disease scans and trends',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF6B7280),
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Spacer(),
          // PDF Export Button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade500, Colors.green.shade700],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _generatePdfReport,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Export PDF',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildMainContent() {
    if (_selectedNavItem == 0) {
      // Dashboard View
      return _buildDashboardView();
    } else if (_selectedNavItem == 1) {
      // Insights View
      return _buildInsightsView();
    } else if (_selectedNavItem == 2) {
      // Trends View
      return _buildTrendsView();
    } else {
      // User History View
      return _buildUserHistoryView();
    }
  }

  Widget _buildDashboardView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCards(),
          const SizedBox(height: 30),
          diseaseScanAndHistoryCard(),
        ],
      ),
    );
  }

  Widget _buildInsightsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: _buildInsightsTab(),
    );
  }

  Widget _buildTrendsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: _buildTrendsTab(),
    );
  }

  Widget _buildUserHistoryView() {
    return UserHistoryView(controller: controller);
  }

  Widget _buildUserDetailView() {
    return Obx(() {
      final userInfo = controller.selectedUserInfo;
      if (userInfo == null) {
        return const Center(child: Text('User not found'));
      }

      final diseaseDistribution = controller.getUserDiseaseDistribution(
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
                      controller.selectedUserId.value = '';
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
                  if (controller.selectedUserHistory.isEmpty)
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
                            columns: [
                              const DataColumn(
                                label: Text(
                                  'Timestamp',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF374151),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const DataColumn(
                                label: Text(
                                  'Plant Name',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF374151),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const DataColumn(
                                label: Text(
                                  'Disease',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF374151),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const DataColumn(
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
                                controller.selectedUserHistory.asMap().entries.map((
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
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            const Icon(
                                                              Icons
                                                                  .visibility_rounded,
                                                              color:
                                                                  Colors.white,
                                                              size: 16,
                                                            ),
                                                            const SizedBox(
                                                              width: 6,
                                                            ),
                                                            const Text(
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
                ],
              ),
            ),
          ],
        ),
      );
    });
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

  Widget _buildSidebar() {
    final monthName = DateFormat('MMMM yyyy').format(DateTime.now());

    return Drawer(
      width: 420,
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.trending_up_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Insights & Trends',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'This Month Analysis',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        monthName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    label: 'Insights',
                    icon: Icons.lightbulb_outline_rounded,
                    isSelected: _selectedSidebarTab == 0,
                    onTap: () => setState(() => _selectedSidebarTab = 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton(
                    label: 'Trends',
                    icon: Icons.show_chart_rounded,
                    isSelected: _selectedSidebarTab == 1,
                    onTap: () => setState(() => _selectedSidebarTab = 1),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child:
                  _selectedSidebarTab == 0
                      ? _buildInsightsTab()
                      : _buildTrendsTab(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green.shade50 : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.green.shade300 : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color:
                    isSelected ? Colors.green.shade700 : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color:
                      isSelected ? Colors.green.shade700 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightsTab() {
    return Obx(() {
      final monthTotal = controller.thisMonthTotalScans;
      final monthDiseases = controller.thisMonthDiseases;
      final monthHealthy = controller.thisMonthHealthy;
      final weekly = controller.weeklyComparison;
      final diseaseDistribution = controller.thisMonthDiseaseDistribution;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // This Month Summary
          _buildInsightCard(
            icon: Icons.calendar_month_rounded,
            title: 'This Month Overview',
            color: Colors.blue,
            child: Column(
              children: [
                _buildStatRow(
                  'Total Scans',
                  monthTotal.toString(),
                  Colors.blue,
                ),
                const SizedBox(height: 12),
                _buildStatRow(
                  'Diseases Detected',
                  monthDiseases.toString(),
                  Colors.orange,
                ),
                const SizedBox(height: 12),
                _buildStatRow(
                  'Healthy Plants',
                  monthHealthy.toString(),
                  Colors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Weekly Comparison
          _buildInsightCard(
            icon: Icons.compare_arrows_rounded,
            title: 'Weekly Comparison',
            color: Colors.purple,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This Week',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          weekly['current'].toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last Week',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          weekly['previous'].toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        (weekly['change'] as double) >= 0
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        (weekly['change'] as double) >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color:
                            (weekly['change'] as double) >= 0
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(weekly['change'] as double).toStringAsFixed(1)}% ${(weekly['change'] as double) >= 0 ? 'increase' : 'decrease'}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              (weekly['change'] as double) >= 0
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Disease Distribution
          if (diseaseDistribution.isNotEmpty)
            _buildInsightCard(
              icon: Icons.pie_chart_rounded,
              title: 'Top Diseases This Month',
              color: Colors.red,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    (() {
                      final sorted =
                          diseaseDistribution.entries.toList()
                            ..sort((a, b) => b.value.compareTo(a.value));
                      return sorted.take(5).map((entry) {
                        final percentage =
                            monthDiseases > 0
                                ? (entry.value / monthDiseases * 100)
                                : 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
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
                                        fontSize: 13,
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
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value:
                                      monthDiseases > 0
                                          ? entry.value / monthDiseases
                                          : 0,
                                  backgroundColor: Colors.red.shade100,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.red.shade400,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList();
                    })(),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildTrendsTab() {
    return Obx(() {
      final dailyTrend = controller.thisMonthDailyTrend;
      final sortedDays =
          dailyTrend.keys.toList()..sort((a, b) {
            final dateA = DateFormat('MMM dd').parse(a);
            final dateB = DateFormat('MMM dd').parse(b);
            return dateA.compareTo(dateB);
          });
      final maxValue =
          dailyTrend.values.isEmpty
              ? 1
              : dailyTrend.values.reduce((a, b) => a > b ? a : b);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daily Trend Card
          _buildInsightCard(
            icon: Icons.timeline_rounded,
            title: 'Daily Scan Trend',
            color: Colors.green,
            child:
                sortedDays.isEmpty
                    ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No data available for this month',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    )
                    : Column(
                      children:
                          sortedDays.map((day) {
                            final value = dailyTrend[day] ?? 0;
                            final percentage =
                                maxValue > 0 ? value / maxValue : 0.0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        day,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                      ),
                                      Text(
                                        value.toString(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: percentage,
                                      backgroundColor: Colors.green.shade100,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.green.shade400,
                                      ),
                                      minHeight: 8,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
          ),
          const SizedBox(height: 16),
          // Insights Summary
          _buildInsightCard(
            icon: Icons.insights_rounded,
            title: 'Key Insights',
            color: Colors.indigo,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInsightItem(
                  Icons.calendar_today,
                  'This month\'s scans: ${controller.thisMonthTotalScans}',
                  Colors.blue,
                ),
                const SizedBox(height: 12),
                _buildInsightItem(
                  Icons.warning_amber_rounded,
                  'Disease detection rate: ${controller.thisMonthTotalScans > 0 ? (controller.thisMonthDiseases / controller.thisMonthTotalScans * 100).toStringAsFixed(1) : 0}%',
                  Colors.orange,
                ),
                const SizedBox(height: 12),
                _buildInsightItem(
                  Icons.eco_rounded,
                  'Healthy plant rate: ${controller.thisMonthTotalScans > 0 ? (controller.thisMonthHealthy / controller.thisMonthTotalScans * 100).toStringAsFixed(1) : 0}%',
                  Colors.green,
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
          ),
        ),
      ],
    );
  }
}

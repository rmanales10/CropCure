import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';

enum ReportType { summary, detailed, userSpecific, monthly }

class PdfService {
  // Cache for logo images
  static Uint8List? _logoImageBytes;
  static Uint8List? _printLogoImageBytes;

  // Load logo image from assets
  static Future<Uint8List?> _loadLogoImage() async {
    if (_logoImageBytes != null) return _logoImageBytes;
    try {
      final ByteData logoData = await rootBundle.load('assets/print/logo.png');
      _logoImageBytes = logoData.buffer.asUint8List();
      return _logoImageBytes;
    } catch (e) {
      print('Error loading logo.png: $e');
      return null;
    }
  }

  // Load print logo image from assets
  static Future<Uint8List?> _loadPrintLogoImage() async {
    if (_printLogoImageBytes != null) return _printLogoImageBytes;
    try {
      final ByteData logoData = await rootBundle.load(
        'assets/print/print_logo.jpg',
      );
      _printLogoImageBytes = logoData.buffer.asUint8List();
      return _printLogoImageBytes;
    } catch (e) {
      print('Error loading print_logo.jpg: $e');
      return null;
    }
  }

  // Helper function to check if a plant is healthy (matches controller logic)
  static bool _isPlantHealthy(String? disease) {
    if (disease == null) return false;
    final diseaseLower = disease.toString().trim().toLowerCase();
    return diseaseLower == 'no disease detected' ||
        diseaseLower == 'healthy plant' ||
        diseaseLower == 'healthy' ||
        diseaseLower.contains('healthy') ||
        diseaseLower.contains('no disease');
  }

  // Enhanced report generation with admin information
  static Future<void> generateAnalyticsReport({
    required List<Map<String, dynamic>> historyData,
    required int totalScans,
    required int diseaseDetected,
    required int healthyScans,
    required Map<String, int> diseaseScansPerDay,
    Map<String, dynamic>? adminInfo,
    ReportType reportType = ReportType.summary,
    String? userId,
    List<Map<String, dynamic>>? usersList,
    Map<String, int>? diseaseDistribution,
    Map<String, dynamic>? weeklyComparison,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Get admin information if not provided
    if (adminInfo == null) {
      adminInfo = await _getCurrentAdminInfo();
    }

    final pdf = pw.Document();
    // Get current date and time (local timezone)
    final now = DateTime.now();
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final reportTitle = _getReportTitle(reportType, now, startDate, endDate);

    // Load logo images
    final logoImage = await _loadLogoImage();
    final printLogoImage = await _loadPrintLogoImage();

    // Generate report based on type
    switch (reportType) {
      case ReportType.summary:
        // First page: Overview with statistics and disease distribution
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
            build: (pw.Context context) {
              return [
                _buildEnhancedHeader(
                  dateFormat.format(now),
                  timeFormat.format(now),
                  adminInfo,
                  reportTitle,
                  logoImage: logoImage,
                  printLogoImage: printLogoImage,
                ),
                pw.SizedBox(height: 30),
                _buildStatisticsSection(
                  totalScans,
                  diseaseDetected,
                  healthyScans,
                ),
                pw.SizedBox(height: 30),
                if (diseaseDistribution != null &&
                    diseaseDistribution.isNotEmpty)
                  _buildDiseaseDistributionSection(
                    diseaseDistribution,
                    diseaseDetected,
                  ),
              ];
            },
            footer: (pw.Context context) {
              return _buildEnhancedFooter(context, adminInfo);
            },
          ),
        );

        // Additional pages: Scan history table
        if (historyData.isNotEmpty) {
          _addHistoryTablePages(
            pdf,
            historyData,
            adminInfo,
            reportTitle,
            showUserColumn: false,
          );
        }
        break;

      case ReportType.detailed:
        // First page: Overview with statistics and charts
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
            build: (pw.Context context) {
              return [
                _buildEnhancedHeader(
                  dateFormat.format(now),
                  timeFormat.format(now),
                  adminInfo,
                  reportTitle,
                  logoImage: logoImage,
                  printLogoImage: printLogoImage,
                ),
                pw.SizedBox(height: 25),
                _buildStatisticsSection(
                  totalScans,
                  diseaseDetected,
                  healthyScans,
                ),
                pw.SizedBox(height: 25),
                if (weeklyComparison != null)
                  _buildWeeklyComparisonSection(weeklyComparison),
                pw.SizedBox(height: 25),
                _buildChartSection(diseaseScansPerDay),
                pw.SizedBox(height: 20),
                if (diseaseDistribution != null &&
                    diseaseDistribution.isNotEmpty)
                  _buildDiseaseDistributionSection(
                    diseaseDistribution,
                    diseaseDetected,
                  ),
              ];
            },
            footer: (pw.Context context) {
              return _buildEnhancedFooter(context, adminInfo);
            },
          ),
        );

        // Additional pages: History table split into manageable chunks
        _addHistoryTablePages(
          pdf,
          historyData,
          adminInfo,
          reportTitle,
          usersList: usersList,
        );
        break;

      case ReportType.userSpecific:
        // Date Range Report - show filtered data
        // First page: Date range info and statistics
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
            build: (pw.Context context) {
              return [
                _buildEnhancedHeader(
                  dateFormat.format(now),
                  timeFormat.format(now),
                  adminInfo,
                  reportTitle,
                  logoImage: logoImage,
                  printLogoImage: printLogoImage,
                ),
                pw.SizedBox(height: 25),
                if (startDate != null && endDate != null)
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Report Period',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'From: ${dateFormat.format(startDate)}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'To: ${dateFormat.format(endDate)}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                pw.SizedBox(height: 25),
                _buildStatisticsSection(
                  totalScans,
                  diseaseDetected,
                  healthyScans,
                ),
                pw.SizedBox(height: 25),
                if (diseaseDistribution != null &&
                    diseaseDistribution.isNotEmpty)
                  _buildDiseaseDistributionSection(
                    diseaseDistribution,
                    diseaseDetected,
                  ),
              ];
            },
            footer: (pw.Context context) {
              return _buildEnhancedFooter(context, adminInfo);
            },
          ),
        );

        // Additional pages: Filtered scan history
        if (historyData.isNotEmpty) {
          _addHistoryTablePages(
            pdf,
            historyData,
            adminInfo,
            reportTitle,
            showUserColumn: true,
            usersList: usersList,
          );
        }
        break;

      case ReportType.monthly:
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
            build: (pw.Context context) {
              return [
                _buildEnhancedHeader(
                  dateFormat.format(now),
                  timeFormat.format(now),
                  adminInfo,
                  reportTitle,
                  logoImage: logoImage,
                  printLogoImage: printLogoImage,
                ),
                pw.SizedBox(height: 30),
                _buildStatisticsSection(
                  totalScans,
                  diseaseDetected,
                  healthyScans,
                ),
                pw.SizedBox(height: 30),
                if (diseaseDistribution != null)
                  _buildDiseaseDistributionSection(
                    diseaseDistribution,
                    diseaseDetected,
                  ),
                pw.SizedBox(height: 30),
                if (weeklyComparison != null)
                  _buildWeeklyComparisonSection(weeklyComparison),
                pw.SizedBox(height: 30),
                _buildChartSection(diseaseScansPerDay),
              ];
            },
            footer: (pw.Context context) {
              return _buildEnhancedFooter(context, adminInfo);
            },
          ),
        );
        break;
    }

    // Generate filename based on report type
    final fileName = _generateFileName(
      reportType,
      now,
      adminInfo,
      userId,
      startDate,
      endDate,
    );

    // Print or save the PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: fileName,
    );
  }

  // Get current admin information from Firebase
  static Future<Map<String, dynamic>> _getCurrentAdminInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final adminDoc =
            await FirebaseFirestore.instance
                .collection('admins')
                .doc(user.uid)
                .get();

        if (adminDoc.exists) {
          final data = adminDoc.data();
          return {
            'name': data?['name'] ?? 'Admin',
            'email': data?['email'] ?? user.email ?? 'N/A',
            'role': data?['role'] ?? 'Admin',
            'uid': user.uid,
          };
        }
      }

      // Fallback if admin not found in Firestore
      final currentUser = FirebaseAuth.instance.currentUser;
      return {
        'name': 'Admin',
        'email': currentUser?.email ?? 'N/A',
        'role': 'Admin',
        'uid': currentUser?.uid ?? 'N/A',
      };
    } catch (e) {
      // Default admin info if error
      return {
        'name': 'Admin',
        'email': 'admin@cropcure.com',
        'role': 'Admin',
        'uid': 'N/A',
      };
    }
  }

  // Get report title based on type
  static String _getReportTitle(
    ReportType type,
    DateTime now,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    switch (type) {
      case ReportType.summary:
        return 'Summary Report';
      case ReportType.detailed:
        return 'Detailed Analytics Report';
      case ReportType.userSpecific:
        if (startDate != null && endDate != null) {
          return 'Date Range Report - ${DateFormat('MMM dd, yyyy').format(startDate)} to ${DateFormat('MMM dd, yyyy').format(endDate)}';
        }
        return 'Date Range Report';
      case ReportType.monthly:
        return 'Monthly Report - ${DateFormat('MMMM yyyy').format(now)}';
    }
  }

  // Generate filename based on report type and admin info
  static String _generateFileName(
    ReportType type,
    DateTime now,
    Map<String, dynamic>? adminInfo,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final adminName =
        adminInfo?['name']?.toString().replaceAll(' ', '_') ?? 'Admin';

    switch (type) {
      case ReportType.summary:
        return 'CropCure_Summary_${adminName}_$dateStr.pdf';
      case ReportType.detailed:
        return 'CropCure_Detailed_${adminName}_$dateStr.pdf';
      case ReportType.userSpecific:
        if (startDate != null && endDate != null) {
          final dateRangeStr =
              '${DateFormat('MMMdd').format(startDate)}_${DateFormat('MMMdd').format(endDate)}';
          return 'CropCure_DateRange_${dateRangeStr}_$dateStr.pdf';
        }
        return 'CropCure_DateRange_$dateStr.pdf';
      case ReportType.monthly:
        return 'CropCure_Monthly_${DateFormat('MMM-yyyy').format(now)}_$dateStr.pdf';
    }
  }

  // Enhanced header with admin information
  static pw.Widget _buildEnhancedHeader(
    String date,
    String time,
    Map<String, dynamic>? adminInfo,
    String reportTitle, {
    Uint8List? logoImage,
    Uint8List? printLogoImage,
  }) {
    final adminName = adminInfo?['name'] ?? 'Admin';
    final adminRole = adminInfo?['role'] ?? 'Admin';
    final adminEmail = adminInfo?['email'] ?? 'N/A';

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#10B981'),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Flexible(
                flex: 3,
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logoImage != null)
                      pw.Container(
                        margin: const pw.EdgeInsets.only(right: 16),
                        child: pw.Image(
                          pw.MemoryImage(logoImage),
                          width: 60,
                          height: 60,
                        ),
                      ),
                    pw.Flexible(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'CropCure Analytics Report',
                            style: pw.TextStyle(
                              fontSize: 28,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            reportTitle,
                            style: pw.TextStyle(
                              fontSize: 14,
                              color: PdfColors.white,
                              fontStyle: pw.FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.Flexible(
                flex: 1,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    if (printLogoImage != null)
                      pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Image(
                          pw.MemoryImage(printLogoImage),
                          width: 50,
                          height: 50,
                        ),
                      ),
                    pw.Text(
                      date,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      time,
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.Divider(color: PdfColors.white, height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Flexible(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Generated By:',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColor(0.85, 0.85, 0.85), // Light gray
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      adminName.toString(),
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      '$adminRole | $adminEmail',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColor(0.85, 0.85, 0.85), // Light gray
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Enhanced footer with admin information
  static pw.Widget _buildEnhancedFooter(
    pw.Context context,
    Map<String, dynamic>? adminInfo,
  ) {
    final adminName = adminInfo?['name'] ?? 'Admin';
    final adminRole = adminInfo?['role'] ?? 'Admin';

    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Flexible(
            child: pw.Text(
              'Generated by $adminName ($adminRole) - CropCure Admin Portal',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColor.fromHex('#6B7280'),
              ),
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColor.fromHex('#6B7280'),
            ),
          ),
        ],
      ),
    );
  }

  // User information section
  static pw.Widget _buildUserInfoSection(Map<String, dynamic> user) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F9FAFB'),
        border: pw.Border.all(color: PdfColor.fromHex('#E5E7EB')),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'User Information',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1A1A1A'),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Flexible(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Name:',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColor.fromHex('#6B7280'),
                      ),
                    ),
                    pw.Text(
                      user['fullname']?.toString() ?? 'N/A',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#1A1A1A'),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Flexible(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Email:',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColor.fromHex('#6B7280'),
                      ),
                    ),
                    pw.Text(
                      user['email']?.toString() ?? 'N/A',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColor.fromHex('#1A1A1A'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Disease distribution section with table format
  static pw.Widget _buildDiseaseDistributionSection(
    Map<String, int> diseaseDistribution,
    int diseaseDetected,
  ) {
    final sortedDiseases =
        diseaseDistribution.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Show all diseases, not just top 10
    final allDiseases = sortedDiseases;

    // Use diseaseDetected as the total for accurate percentage calculation
    final total =
        diseaseDetected > 0
            ? diseaseDetected
            : diseaseDistribution.values.fold(0, (a, b) => a + b);

    if (allDiseases.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#F9FAFB'),
          borderRadius: pw.BorderRadius.circular(12),
          border: pw.Border.all(color: PdfColor.fromHex('#E5E7EB'), width: 1),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Disease Distribution',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1A1A1A'),
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Center(
              child: pw.Text(
                'No disease data available for distribution.',
                style: pw.TextStyle(
                  fontSize: 14,
                  color: PdfColor.fromHex('#6B7280'),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F9FAFB'),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColor.fromHex('#E5E7EB'), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Disease Distribution',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1A1A1A'),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfColor.fromHex('#E5E7EB'),
              width: 1,
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F9FAFB'),
                ),
                children: [
                  _buildTableHeader('Disease Name'),
                  _buildTableHeader('Count'),
                  _buildTableHeader('Percentage'),
                ],
              ),
              ...allDiseases.map((entry) {
                // Safe percentage calculation with NaN protection
                String percentage = '0.0';
                if (total > 0 && entry.value >= 0) {
                  final calc = (entry.value / total * 100);
                  if (calc.isFinite && !calc.isNaN) {
                    percentage = calc.toStringAsFixed(1);
                  }
                }
                return pw.TableRow(
                  children: [
                    _buildTableCell(entry.key),
                    _buildTableCell(
                      entry.value.toString(),
                      textAlign: pw.TextAlign.center,
                    ),
                    _buildTableCell(
                      '$percentage%',
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  // Weekly comparison section
  static pw.Widget _buildWeeklyComparisonSection(
    Map<String, dynamic> weeklyComparison,
  ) {
    final current = weeklyComparison['current'] ?? 0;
    final previous = weeklyComparison['previous'] ?? 0;
    final changeValue = weeklyComparison['change'] ?? 0.0;
    // Ensure change is a valid number, not NaN
    final change =
        (changeValue is num && changeValue.isFinite && !changeValue.isNaN)
            ? changeValue.toDouble()
            : 0.0;
    final isIncrease = change >= 0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F9FAFB'),
        border: pw.Border.all(color: PdfColor.fromHex('#E5E7EB')),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Weekly Comparison',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1A1A1A'),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              pw.Flexible(
                child: _buildComparisonCard('Current Week', current.toString()),
              ),
              pw.Flexible(
                child: _buildComparisonCard(
                  'Previous Week',
                  previous.toString(),
                ),
              ),
              pw.Flexible(
                child: _buildComparisonCard(
                  'Change',
                  '${isIncrease ? '+' : ''}${change.isFinite && !change.isNaN ? change.toStringAsFixed(1) : '0.0'}%',
                  color:
                      isIncrease
                          ? PdfColor.fromHex('#EF4444')
                          : PdfColor.fromHex('#10B981'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildComparisonCard(
    String title,
    String value, {
    PdfColor? color,
  }) {
    return pw.Column(
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#6B7280')),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: color ?? PdfColor.fromHex('#1A1A1A'),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildStatisticsSection(
    int totalScans,
    int diseaseDetected,
    int healthyScans,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F9FAFB'),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColor.fromHex('#E5E7EB'), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Summary Statistics',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1A1A1A'),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard(
                'Total Scans',
                totalScans.toString(),
                PdfColor.fromHex('#3B82F6'),
              ),
              _buildStatCard(
                'Diseases Detected',
                diseaseDetected.toString(),
                PdfColor.fromHex('#F97316'),
              ),
              _buildStatCard(
                'Healthy Plants',
                healthyScans.toString(),
                PdfColor.fromHex('#10B981'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStatCard(
    String title,
    String value,
    PdfColor color, {
    String? subtitle,
  }) {
    return pw.Flexible(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(16),
        margin: const pw.EdgeInsets.symmetric(horizontal: 4),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#F3F4F6'),
          border: pw.Border.all(color: color, width: 2),
          borderRadius: pw.BorderRadius.circular(12),
        ),
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColor.fromHex('#6B7280'),
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 32,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
              textAlign: pw.TextAlign.center,
            ),
            if (subtitle != null) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                subtitle,
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColor.fromHex('#6B7280'),
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildChartSection(Map<String, int> diseaseScansPerDay) {
    // Handle null or empty map
    if (diseaseScansPerDay.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Disease Scans Per Day',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1A1A1A'),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            height: 200,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromHex('#E5E7EB')),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Center(
              child: pw.Text(
                'No disease scan data available',
                style: pw.TextStyle(
                  fontSize: 14,
                  color: PdfColor.fromHex('#6B7280'),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Sort days numerically (as integers) instead of alphabetically
    final days =
        diseaseScansPerDay.keys.toList()..sort((a, b) {
          final aInt = int.tryParse(a) ?? 0;
          final bInt = int.tryParse(b) ?? 0;
          return aInt.compareTo(bInt);
        });

    // Validate all values before mapping - ensure they're valid integers
    final validDays = <String>[];
    final validScans = <int>[];

    for (final day in days) {
      final value = diseaseScansPerDay[day];
      if (value != null && value >= 0 && day.isNotEmpty) {
        validDays.add(day);
        validScans.add(value);
      }
    }

    if (validDays.isEmpty ||
        validScans.isEmpty ||
        validDays.length != validScans.length) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Disease Scans Per Day',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1A1A1A'),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            height: 200,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromHex('#E5E7EB')),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Center(
              child: pw.Text(
                'No disease scan data available',
                style: pw.TextStyle(
                  fontSize: 14,
                  color: PdfColor.fromHex('#6B7280'),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Limit to reasonable number of data points to avoid rendering issues
    final maxDataPoints = 31; // Max days in a month
    final displayDays =
        validDays.length > maxDataPoints
            ? validDays.take(maxDataPoints).toList()
            : validDays;
    final displayScans = validScans.take(displayDays.length).toList();

    // Ensure we have matching lengths
    if (displayDays.length != displayScans.length || displayDays.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Disease Scans Per Day',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1A1A1A'),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            height: 200,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromHex('#E5E7EB')),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Center(
              child: pw.Text(
                'No disease scan data available',
                style: pw.TextStyle(
                  fontSize: 14,
                  color: PdfColor.fromHex('#6B7280'),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Calculate max scan (int values are always valid)
    int maxScan = 0;
    if (displayScans.isNotEmpty) {
      maxScan = displayScans.reduce((a, b) => a > b ? a : b);
    }

    final yAxisValues = <double>[];

    // Calculate step for y-axis with NaN protection
    double step = 1.0;
    if (maxScan > 0) {
      final calculatedStep = (maxScan / 5).ceilToDouble();
      if (calculatedStep.isFinite &&
          !calculatedStep.isNaN &&
          calculatedStep > 0) {
        step = calculatedStep;
      }
    }

    // Generate y-axis values with validation
    for (int i = 0; i <= 5; i++) {
      final value = i * step;
      if (value.isFinite && !value.isNaN && value >= 0) {
        yAxisValues.add(value);
      } else {
        yAxisValues.add(i.toDouble());
      }
    }

    // Remove duplicates and ensure at least 2 values
    final uniqueYValues =
        yAxisValues
            .where((v) => v.isFinite && !v.isNaN && v >= 0)
            .toSet()
            .toList()
          ..sort();
    if (uniqueYValues.length < 2) {
      uniqueYValues.clear();
      for (int i = 0; i <= 5; i++) {
        uniqueYValues.add(i.toDouble());
      }
    }

    // Create chart data points with NaN protection
    final chartData = <pw.LineChartValue>[];
    for (int i = 0; i < displayScans.length; i++) {
      final x = i.toDouble();
      final y = displayScans[i].toDouble();
      // Validate both x and y are finite and not NaN
      final safeX = x.isFinite && !x.isNaN && x >= 0 ? x : 0.0;
      final safeY = y.isFinite && !y.isNaN && y >= 0 ? y : 0.0;
      chartData.add(pw.LineChartValue(safeX, safeY));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Disease Scans Per Day',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#1A1A1A'),
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Container(
          height: 200,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColor.fromHex('#E5E7EB')),
            borderRadius: pw.BorderRadius.circular(12),
          ),
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(16),
            child: pw.Chart(
              grid: pw.CartesianGrid(
                xAxis: pw.FixedAxis.fromStrings(
                  displayDays,
                  marginStart: 30,
                  marginEnd: 10,
                  ticks: true,
                  textStyle: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColor.fromHex('#6B7280'),
                  ),
                ),
                yAxis: pw.FixedAxis(
                  uniqueYValues,
                  format: (v) {
                    // Strict validation to prevent NaN
                    if (!v.isFinite || v.isNaN || v < 0) {
                      return '0';
                    }
                    try {
                      final intValue = v.toInt();
                      return intValue.toString();
                    } catch (e) {
                      return '0';
                    }
                  },
                  divisions: true,
                  ticks: true,
                  textStyle: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColor.fromHex('#6B7280'),
                  ),
                ),
              ),
              datasets: [
                pw.LineDataSet(
                  legend: 'Disease Scans',
                  drawPoints: true,
                  isCurved: true,
                  color: PdfColor.fromHex('#10B981'),
                  data: chartData,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to add history table across multiple pages
  static void _addHistoryTablePages(
    pw.Document pdf,
    List<Map<String, dynamic>> historyData,
    Map<String, dynamic>? adminInfo,
    String reportTitle, {
    bool showUserColumn = true,
    List<Map<String, dynamic>>? usersList,
  }) {
    const rowsPerPage = 15; // Reduced from 30 to prevent overflow
    final totalPages = (historyData.length / rowsPerPage).ceil();

    for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
      final startIndex = pageIndex * rowsPerPage;
      final endIndex =
          (startIndex + rowsPerPage < historyData.length)
              ? startIndex + rowsPerPage
              : historyData.length;
      final pageData = historyData.sublist(startIndex, endIndex);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              pw.Text(
                'Scan History',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1A1A1A'),
                ),
              ),
              if (totalPages > 1)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Text(
                    'Page ${pageIndex + 1} of $totalPages',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColor.fromHex('#6B7280'),
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
              pw.SizedBox(height: 16),
              _buildTable(
                pageData,
                showUserColumn: showUserColumn,
                usersList: usersList,
              ),
              if (totalPages > 1 && pageIndex < totalPages - 1)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 12),
                  child: pw.Text(
                    'Continues on next page...',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColor.fromHex('#6B7280'),
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
            ];
          },
          footer: (pw.Context context) {
            return _buildEnhancedFooter(context, adminInfo);
          },
        ),
      );
    }
  }

  // Helper function to get user name from userId
  static String _getUserNameFromId(
    String? userId,
    List<Map<String, dynamic>>? usersList,
  ) {
    if (userId == null || userId.isEmpty || usersList == null) {
      return 'N/A';
    }

    try {
      final user = usersList.firstWhere(
        (user) =>
            (user['uid']?.toString() == userId) ||
            (user['userId']?.toString() == userId),
        orElse: () => {},
      );

      return user['fullname']?.toString() ??
          user['name']?.toString() ??
          'Unknown User';
    } catch (e) {
      return 'N/A';
    }
  }

  // Build table widget
  static pw.Widget _buildTable(
    List<Map<String, dynamic>> historyData, {
    bool showUserColumn = true,
    List<Map<String, dynamic>>? usersList,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColor.fromHex('#E5E7EB'), width: 1),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F9FAFB')),
          children: [
            _buildTableHeader('Timestamp'),
            _buildTableHeader('Plant Name'),
            _buildTableHeader('Condition'),
            _buildTableHeader('Status'),
            if (showUserColumn) _buildTableHeader('User'),
          ],
        ),
        ...historyData.map((row) {
          final timestamp =
              row['timestamp'] is Timestamp
                  ? DateFormat(
                    'MMM dd, yyyy HH:mm',
                  ).format((row['timestamp'] as Timestamp).toDate())
                  : row['timestamp']?.toString() ?? 'N/A';
          final plantName = row['name']?.toString() ?? 'N/A';
          final disease = row['disease']?.toString() ?? 'N/A';
          final isHealthy = _isPlantHealthy(disease);
          final userId =
              row['userId']?.toString() ?? row['user_id']?.toString();
          final userName =
              showUserColumn ? _getUserNameFromId(userId, usersList) : 'N/A';

          return pw.TableRow(
            children: [
              _buildTableCell(timestamp),
              _buildTableCell(plantName),
              _buildTableCell(disease),
              _buildTableCell(
                isHealthy ? 'Healthy' : 'Infected',
                color:
                    isHealthy
                        ? PdfColor.fromHex('#10B981')
                        : PdfColor.fromHex('#EF4444'),
              ),
              if (showUserColumn) _buildTableCell(userName),
            ],
          );
        }),
      ],
    );
  }

  // Legacy method kept for backward compatibility (for summary reports)
  static pw.Widget _buildHistoryTable(
    List<Map<String, dynamic>> historyData, {
    bool showUserColumn = true,
    List<Map<String, dynamic>>? usersList,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Scan History',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#1A1A1A'),
          ),
        ),
        pw.SizedBox(height: 16),
        _buildTable(
          historyData.take(15).toList(),
          showUserColumn: showUserColumn,
          usersList: usersList,
        ),
        if (historyData.length > 15)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 12),
            child: pw.Text(
              'Showing first 15 of ${historyData.length} records',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColor.fromHex('#6B7280'),
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#374151'),
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    PdfColor? color,
    pw.TextAlign? textAlign,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: textAlign ?? pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 10,
          color: color ?? PdfColor.fromHex('#1F2937'),
        ),
      ),
    );
  }
}

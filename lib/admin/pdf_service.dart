import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum ReportType { summary, detailed, userSpecific, monthly }

class PdfService {
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
  }) async {
    // Get admin information if not provided
    if (adminInfo == null) {
      adminInfo = await _getCurrentAdminInfo();
    }

    final pdf = pw.Document();
    final now = DateTime.now();
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final reportTitle = _getReportTitle(reportType, now);

    // Generate report based on type
    switch (reportType) {
      case ReportType.summary:
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
                  _buildDiseaseDistributionSection(diseaseDistribution),
              ];
            },
            footer: (pw.Context context) {
              return _buildEnhancedFooter(context, adminInfo);
            },
          ),
        );
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
                  _buildDiseaseDistributionSection(diseaseDistribution),
              ];
            },
            footer: (pw.Context context) {
              return _buildEnhancedFooter(context, adminInfo);
            },
          ),
        );

        // Additional pages: History table split into manageable chunks
        _addHistoryTablePages(pdf, historyData, adminInfo, reportTitle);
        break;

      case ReportType.userSpecific:
        if (userId != null && usersList != null) {
          final user = usersList.firstWhere(
            (u) => u['uid'] == userId,
            orElse: () => {},
          );
          final userScans =
              historyData.where((scan) => scan['userId'] == userId).toList();
          final userTotalScans = userScans.length;
          final userDiseaseDetected =
              userScans
                  .where(
                    (scan) => !_isPlantHealthy(scan['disease']?.toString()),
                  )
                  .length;
          final userHealthy = userTotalScans - userDiseaseDetected;

          // First page: User info and statistics
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
                  ),
                  pw.SizedBox(height: 25),
                  _buildUserInfoSection(user),
                  pw.SizedBox(height: 25),
                  _buildStatisticsSection(
                    userTotalScans,
                    userDiseaseDetected,
                    userHealthy,
                  ),
                ];
              },
              footer: (pw.Context context) {
                return _buildEnhancedFooter(context, adminInfo);
              },
            ),
          );

          // Additional pages: User's scan history
          if (userScans.isNotEmpty) {
            _addHistoryTablePages(
              pdf,
              userScans,
              adminInfo,
              reportTitle,
              showUserColumn: false,
            );
          }
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
                ),
                pw.SizedBox(height: 30),
                _buildStatisticsSection(
                  totalScans,
                  diseaseDetected,
                  healthyScans,
                ),
                pw.SizedBox(height: 30),
                if (diseaseDistribution != null)
                  _buildDiseaseDistributionSection(diseaseDistribution),
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
    final fileName = _generateFileName(reportType, now, adminInfo, userId);

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
  static String _getReportTitle(ReportType type, DateTime now) {
    switch (type) {
      case ReportType.summary:
        return 'Summary Report';
      case ReportType.detailed:
        return 'Detailed Analytics Report';
      case ReportType.userSpecific:
        return 'User-Specific Report';
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
        return 'CropCure_UserReport_${userId ?? 'User'}_$dateStr.pdf';
      case ReportType.monthly:
        return 'CropCure_Monthly_${DateFormat('MMM-yyyy').format(now)}_$dateStr.pdf';
    }
  }

  // Enhanced header with admin information
  static pw.Widget _buildEnhancedHeader(
    String date,
    String time,
    Map<String, dynamic>? adminInfo,
    String reportTitle,
  ) {
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
            children: [
              pw.Expanded(
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
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
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
            ],
          ),
          pw.Divider(color: PdfColors.white, height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
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
          pw.Text(
            'Generated by $adminName ($adminRole) - CropCure Admin Portal',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColor.fromHex('#6B7280'),
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
              pw.Expanded(
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
              pw.Expanded(
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

  // Disease distribution section
  static pw.Widget _buildDiseaseDistributionSection(
    Map<String, int> diseaseDistribution,
  ) {
    final sortedDiseases =
        diseaseDistribution.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Column(
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
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F9FAFB')),
              children: [
                _buildTableHeader('Disease Name'),
                _buildTableHeader('Count'),
                _buildTableHeader('Percentage'),
              ],
            ),
            ...sortedDiseases.take(10).map((entry) {
              final total = diseaseDistribution.values.reduce((a, b) => a + b);
              final percentage = (entry.value / total * 100).toStringAsFixed(1);
              return pw.TableRow(
                children: [
                  _buildTableCell(entry.key),
                  _buildTableCell(entry.value.toString()),
                  _buildTableCell('$percentage%'),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  // Weekly comparison section
  static pw.Widget _buildWeeklyComparisonSection(
    Map<String, dynamic> weeklyComparison,
  ) {
    final current = weeklyComparison['current'] ?? 0;
    final previous = weeklyComparison['previous'] ?? 0;
    final change = weeklyComparison['change'] ?? 0.0;
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
              _buildComparisonCard('Current Week', current.toString()),
              _buildComparisonCard('Previous Week', previous.toString()),
              _buildComparisonCard(
                'Change',
                '${isIncrease ? '+' : ''}${change.toStringAsFixed(1)}%',
                color:
                    isIncrease
                        ? PdfColor.fromHex('#EF4444')
                        : PdfColor.fromHex('#10B981'),
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
    return pw.Column(
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
    );
  }

  static pw.Widget _buildStatCard(String title, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(16),
        margin: const pw.EdgeInsets.symmetric(horizontal: 4),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 2),
          borderRadius: pw.BorderRadius.circular(12),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColor.fromHex('#6B7280'),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 32,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildChartSection(Map<String, int> diseaseScansPerDay) {
    final days = diseaseScansPerDay.keys.toList()..sort();
    final scans = days.map((d) => diseaseScansPerDay[d]!).toList();

    final maxScan = scans.isEmpty ? 10 : scans.reduce((a, b) => a > b ? a : b);
    final yAxisValues = <double>[];
    final step = (maxScan / 5).ceilToDouble();
    for (int i = 0; i <= 5; i++) {
      yAxisValues.add(i * step);
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
            child:
                scans.isEmpty
                    ? pw.Center(
                      child: pw.Text(
                        'No disease scan data available',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColor.fromHex('#6B7280'),
                        ),
                      ),
                    )
                    : pw.Chart(
                      grid: pw.CartesianGrid(
                        xAxis: pw.FixedAxis.fromStrings(
                          List<String>.from(days),
                          marginStart: 30,
                          marginEnd: 10,
                          ticks: true,
                          textStyle: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColor.fromHex('#6B7280'),
                          ),
                        ),
                        yAxis: pw.FixedAxis(
                          yAxisValues,
                          format: (v) => v.toInt().toString(),
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
                          data: List.generate(
                            scans.length,
                            (i) => pw.LineChartValue(
                              i.toDouble(),
                              scans[i].toDouble(),
                            ),
                          ),
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
              _buildTable(pageData, showUserColumn: showUserColumn),
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

  // Build table widget
  static pw.Widget _buildTable(
    List<Map<String, dynamic>> historyData, {
    bool showUserColumn = true,
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
              if (showUserColumn)
                _buildTableCell(row['userId']?.toString() ?? 'N/A'),
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

  static pw.Widget _buildTableCell(String text, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          color: color ?? PdfColor.fromHex('#1F2937'),
        ),
      ),
    );
  }
}

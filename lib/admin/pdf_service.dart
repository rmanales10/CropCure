import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PdfService {
  static Future<void> generateAnalyticsReport({
    required List<Map<String, dynamic>> historyData,
    required int totalScans,
    required int diseaseDetected,
    required int healthyScans,
    required Map<String, int> diseaseScansPerDay,
  }) async {
    final pdf = pw.Document();

    // Get current date
    final now = DateTime.now();
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header
            _buildHeader(dateFormat.format(now), timeFormat.format(now)),
            pw.SizedBox(height: 30),

            // Statistics Cards
            _buildStatisticsSection(totalScans, diseaseDetected, healthyScans),
            pw.SizedBox(height: 30),

            // Chart Data
            _buildChartSection(diseaseScansPerDay),
            pw.SizedBox(height: 30),

            // History Table
            _buildHistoryTable(historyData),
          ];
        },
        footer: (pw.Context context) {
          return _buildFooter(context);
        },
      ),
    );

    // Print or save the PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name:
          'CropCure_Analytics_Report_${DateFormat('yyyy-MM-dd').format(now)}.pdf',
    );
  }

  static pw.Widget _buildHeader(String date, String time) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#10B981'),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
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
                'Plant Disease Detection Analytics',
                style: const pw.TextStyle(fontSize: 14, color: PdfColors.white),
              ),
            ],
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
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.white),
              ),
            ],
          ),
        ],
      ),
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

    // Calculate y-axis values and ensure they're sorted in ascending order
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

  static pw.Widget _buildHistoryTable(List<Map<String, dynamic>> historyData) {
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
        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColor.fromHex('#E5E7EB'),
            width: 1,
          ),
          children: [
            // Header Row
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F9FAFB')),
              children: [
                _buildTableHeader('Timestamp'),
                _buildTableHeader('Plant Name'),
                _buildTableHeader('Disease'),
                _buildTableHeader('Status'),
              ],
            ),
            // Data Rows
            ...historyData.take(20).map((row) {
              final timestamp =
                  row['timestamp'] is Timestamp
                      ? DateFormat(
                        'MMM dd, yyyy HH:mm',
                      ).format((row['timestamp'] as Timestamp).toDate())
                      : row['timestamp']?.toString() ?? 'N/A';
              final plantName = row['name']?.toString() ?? 'N/A';
              final disease = row['disease']?.toString() ?? 'N/A';
              final isHealthy =
                  disease.trim().toLowerCase() == 'no disease detected';

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
                ],
              );
            }),
          ],
        ),
        if (historyData.length > 20)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 12),
            child: pw.Text(
              'Showing first 20 of ${historyData.length} records',
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

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by CropCure Admin Portal',
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
}

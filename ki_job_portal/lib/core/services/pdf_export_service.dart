import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/analytics_model.dart';
import 'package:intl/intl.dart';

class PdfExportService {
  static Future<void> exportAnalyticsReport(PlatformStats stats) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('KI Job Portal - Admin Analytics Report',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24)),
              ),
              pw.Text('Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
              pw.SizedBox(height: 30),
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Metric', 'Value'],
                  <String>['Total Users', '${stats.totalUsers}'],
                  <String>['Total Workers', '${stats.totalWorkers}'],
                  <String>['Total Employers', '${stats.totalEmployers}'],
                  <String>['Total Jobs', '${stats.totalJobs}'],
                  <String>['Total Revenue', 'Rs. ${stats.totalRevenue}'],
                ],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerRight,
                },
              ),
              pw.SizedBox(height: 40),
              pw.Text('Report Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text(
                  'The platform continues to show strong worker acquisition. Revenue is steady. Focus on reducing pending posts (${stats.pendingPosts} currently awaiting review).'),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Analytics_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}

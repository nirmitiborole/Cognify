
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'dart:math' as math;
import 'report_model.dart';

class PDFGenerator {
  Future<Uint8List> generateReport(MentalHealthReport report) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            _buildHeader(report),
            pw.SizedBox(height: 20),

            // User Info and Wellness Score Section
            _buildUserInfoSection(report),
            pw.SizedBox(height: 20),

            // Divider
            pw.Container(
              height: 2,
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#6A1B9A'),
              ),
            ),
            pw.SizedBox(height: 20),

            // Mental Health Status and Risk Factor
            _buildStatusSection(report),
            pw.SizedBox(height: 20),

            // Key Indicators
            _buildKeyIndicatorsSection(report),
            pw.SizedBox(height: 20),

            // Screening Observation
            _buildObservationSection(report),
            pw.SizedBox(height: 20),

            // Suggested Actions
            _buildSuggestionsSection(report),
            pw.SizedBox(height: 20),

            // Disclaimer
            _buildDisclaimerSection(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(MentalHealthReport report) {
    return pw.Container(
      padding: pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#6A1B9A'),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Center(
        child: pw.Text(
          'AI REPORT',
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }

  pw.Widget _buildUserInfoSection(MentalHealthReport report) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // User Info
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  _buildGenderIcon(report.userGender),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    report.userName,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text('Age: ${report.userAge}'),
              pw.SizedBox(height: 4),
              pw.Text('Date: ${_formatDate(report.reportDate)}'),
              pw.SizedBox(height: 4),
              pw.Text('Report ID: ${report.reportId.split('_').last}'),
            ],
          ),
        ),
        // Wellness Score Gauge
        pw.Expanded(
          flex: 1,
          child: _buildWellnessGauge(report.comprehensiveScore),
        ),
      ],
    );
  }

  pw.Widget _buildGenderIcon(String gender) {
    String icon = '👤';
    switch (gender.toLowerCase()) {
      case 'male':
        icon = '♂';
        break;
      case 'female':
        icon = '♀';
        break;
      default:
        icon = '👤';
    }
    return pw.Text(
      icon,
      style: pw.TextStyle(
        fontSize: 16,
        color: PdfColor.fromHex('#6A1B9A'),
      ),
    );
  }

  pw.Widget _buildWellnessGauge(double score) {
    return pw.Container(
      width: 120,
      height: 120,
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          // Background circle
          pw.Container(
            width: 120,
            height: 120,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(
                color: PdfColors.grey300,
                width: 8,
              ),
            ),
          ),
          // Progress arc (simplified for PDF)
          pw.Container(
            width: 120,
            height: 120,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(
                color: _getScoreColor(score),
                width: 8,
              ),
            ),
          ),
          // Score text
          pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                '${score.toStringAsFixed(1)}',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Wellness Score',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStatusSection(MentalHealthReport report) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Mental Health Status',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  report.mentalHealthStatus,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: report.mentalHealthStatus == 'Stable'
                        ? PdfColors.green
                        : PdfColors.orange,
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Expanded(
          child: pw.Container(
            padding: pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Risk Factor',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  report.riskFactor,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: report.riskFactor == 'Low' ? PdfColors.green :
                    report.riskFactor == 'Medium' ? PdfColors.orange :
                    PdfColors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildKeyIndicatorsSection(MentalHealthReport report) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Key Indicators',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children: [
            _buildIndicatorChart(
              'Depression Risk',
              report.depressionProbability,
              _getScoreColor(100 - report.depressionProbability),
            ),
            _buildIndicatorChart(
              'Anxiety Risk',
              report.anxietyProbability,
              _getScoreColor(100 - report.anxietyProbability),
            ),
            _buildIndicatorChart(
              'Stress Level',
              (report.stressLevel / 41) * 100,
              _getScoreColor(100 - (report.stressLevel / 41) * 100),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildIndicatorChart(String label, double value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Container(
          width: 80,
          height: 80,
          child: pw.Stack(
            alignment: pw.Alignment.center,
            children: [
              pw.Container(
                width: 80,
                height: 80,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  border: pw.Border.all(
                    color: PdfColors.grey300,
                    width: 6,
                  ),
                ),
              ),
              pw.Container(
                width: 80,
                height: 80,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  border: pw.Border.all(
                    color: color,
                    width: 6,
                  ),
                ),
              ),
              pw.Text(
                '${value.toStringAsFixed(0)}%',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 10),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  pw.Widget _buildObservationSection(MentalHealthReport report) {
    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColor.fromHex('#6A1B9A'), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Screening Observation',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            report.screeningObservation,
            style: pw.TextStyle(fontSize: 12),
            textAlign: pw.TextAlign.justify,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSuggestionsSection(MentalHealthReport report) {
    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColor.fromHex('#00BFA5'), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(
                '💡',
                style: pw.TextStyle(fontSize: 16),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'Suggested Actions',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            report.suggestedActions,
            style: pw.TextStyle(fontSize: 12),
            textAlign: pw.TextAlign.justify,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDisclaimerSection() {
    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FFF3E0'),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.orange, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(
                '⚠️',
                style: pw.TextStyle(fontSize: 16),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'Important Disclaimer',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'This is an AI-generated report based on your responses and is not a medical diagnosis. The information provided is for educational and awareness purposes only. Please consult with qualified mental health professionals for proper assessment, diagnosis, and treatment recommendations.',
            style: pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.justify,
          ),
        ],
      ),
    );
  }

  PdfColor _getScoreColor(double score) {
    if (score >= 80) return PdfColors.green;
    if (score >= 60) return PdfColor.fromHex('#8BC34A');
    if (score >= 40) return PdfColors.yellow;
    if (score >= 20) return PdfColors.orange;
    return PdfColors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
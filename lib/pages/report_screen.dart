import 'package:cognify/pages/user_prefs.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
//import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:math';
import 'report_model.dart';
import 'gemini_service.dart';
import 'semi_circle_chart.dart';
import 'pdf_generator.dart';
import 'package:open_file/open_file.dart';


class ReportScreen extends StatefulWidget {
  final String userGender;
  final int userAge;
  final Map<dynamic, dynamic> testResults;
  final List<int> userResponses;

  const ReportScreen({
    Key? key,
    required this.userGender,
    required this.userAge,
    required this.testResults,
    required this.userResponses,
  }) : super(key: key);

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late MentalHealthReport report;
  bool isLoading = true;
  bool isSaving = false;
  final GeminiService geminiService = GeminiService();

  @override
  void initState() {
    super.initState();
    _initializeReport();
  }

  Future<void> _initializeReport() async {
    try {
      // Get user data from Firebase
      // final user = FirebaseAuth.instance.currentUser;
      // String userName = "User";
      //
      // if (user != null) {
      //   final userDoc = await FirebaseFirestore.instance
      //       .collection('users')
      //       .doc(user.uid)
      //       .get();
      //
      //   if (userDoc.exists) {
      //     userName = userDoc.data()?['name'] ?? user.displayName ?? "User";
      //   }
      // }


      // Get User Data from Shared Preference
      String userName = await UserPrefs.getUserName();

      // Generate report ID
      final reportId = "${FirebaseAuth.instance.currentUser?.uid ?? 'guest'}_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}";

      // Calculate stress level (WHO-5 + Social functioning)
      final wellbeingScore = widget.testResults['wellbeing_score'] ?? 0;
      final socialScore = widget.testResults['social_functioning_score'] ?? 0;
      final stressLevel = (wellbeingScore + socialScore).toDouble();

      // Determine mental health status and risk factor using new methods
      final comprehensiveScore = widget.testResults['comprehensive_score']?.toDouble() ?? 0.0;
      final depressionProb = widget.testResults['depression_probability']?.toDouble() ?? 0.0;
      final anxietyProb = widget.testResults['anxiety_probability']?.toDouble() ?? 0.0;

      // Generate AI observations and suggestions with personalized data
      final screeningObservation = await geminiService.generateScreeningObservation(
        comprehensiveScore: comprehensiveScore,
        depressionProbability: depressionProb,
        anxietyProbability: anxietyProb,
        stressLevel: stressLevel,
        depressionScore: widget.testResults['depression_score'] ?? 0,
        anxietyScore: widget.testResults['anxiety_score'] ?? 0,
        wellbeingScore: wellbeingScore,
        socialFunctioningScore: socialScore,
        userResponses: widget.userResponses, // Pass individual responses for personalization
      );

      final suggestedActions = await geminiService.generateSuggestedActions(
        comprehensiveScore: comprehensiveScore,
        depressionProbability: depressionProb,
        anxietyProbability: anxietyProb,
        stressLevel: stressLevel,
        mentalHealthStatus: "temp", // Will be calculated in report model
        riskFactor: "temp", // Will be calculated in report model
        userResponses: widget.userResponses, // Pass individual responses for personalization
      );

      // Create report object
      report = MentalHealthReport(
        reportId: reportId,
        userName: userName,
        userGender: widget.userGender,
        userAge: widget.userAge,
        reportDate: DateTime.now(),
        comprehensiveScore: comprehensiveScore,
        depressionProbability: depressionProb,
        anxietyProbability: anxietyProb,
        stressLevel: stressLevel,
        depressionScore: widget.testResults['depression_score'] ?? 0,
        anxietyScore: widget.testResults['anxiety_score'] ?? 0,
        wellbeingScore: wellbeingScore,
        socialFunctioningScore: socialScore,
        mentalHealthStatus: "", // Will use model methods
        riskFactor: "", // Will use model methods
        screeningObservation: screeningObservation,
        suggestedActions: suggestedActions,
        userResponses: widget.userResponses,
      );

      setState(() {
        isLoading = false;
      });

    } catch (e) {
      print('Error initializing report: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  IconData _getGenderIcon() {
    switch (widget.userGender.toLowerCase()) {
      case 'male':
        return Icons.male;
      case 'female':
        return Icons.female;
      default:
        return Icons.person;
    }
  }

  Future<bool> _showPermissionExplanationDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Storage Permission Required'),
          content: Text(
            'Cognify needs storage permission to save your mental health report as a PDF file. '
            'This allows you to access the report later or share it with healthcare professionals.'
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Continue'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<bool> _requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        // For Android 10 and above
        if (await Permission.manageExternalStorage.request().isGranted) {
          return true;
        }
        
        // Fallback to regular storage permission
        final status = await Permission.storage.request();
        return status.isGranted;
      } else if (Platform.isIOS) {
        // iOS doesn't need explicit permission for app documents directory
        return true;
      }
      return false;
    } catch (e) {
      print('Error requesting permission: $e');
      // Fallback to basic permission
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  Future<void> _downloadPDF() async {
    setState(() {
      isSaving = true;
    });

    try {
      // Show permission explanation dialog
      bool proceed = await _showPermissionExplanationDialog();
      if (!proceed) {
        setState(() {
          isSaving = false;
        });
        return;
      }

      // Request appropriate storage permissions
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Storage permission denied. Cannot save PDF.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {
                openAppSettings();
              },
            ),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Generate PDF
      final pdfGenerator = PDFGenerator();
      final pdfBytes = await pdfGenerator.generateReport(report);

      // Get downloads directory
      Directory? downloadsDir;
      try {
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          downloadsDir = Directory('${directory.parent.parent.parent.parent.path}/Download');
        } else {
          // Fallback to application documents directory
          final appDir = await getApplicationDocumentsDirectory();
          downloadsDir = Directory('${appDir.path}/downloads');
        }
      } catch (e) {
        print('Error getting directory: $e');
        // Fallback to application documents directory
        final appDir = await getApplicationDocumentsDirectory();
        downloadsDir = Directory('${appDir.path}/downloads');
      }

      if (!downloadsDir.existsSync()) {
        downloadsDir.createSync(recursive: true);
      }

      // Save PDF file
      final fileName = 'Mental_Health_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${downloadsDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      
      // Log the exact file path for debugging
      print('PDF saved successfully at: ${file.path}');
      
      // Show a dialog with the exact file location
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('PDF Saved Successfully'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your report has been saved to:'),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    file.path,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 16),
                Text('You can find this file in your device\'s file manager.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final result = await OpenFile.open(file.path);
                  if (result.type != ResultType.done) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not open file: ${result.message}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text('Open File', style: TextStyle(color: Colors.blue)),
              ),
            ],
          );
        },
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report saved to: ${file.path}'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  Future<void> _saveInApp() async {
    setState(() {
      isSaving = true;
    });

    try {
      // Get the app's documents directory
      final appDocumentsDir = await getApplicationDocumentsDirectory();

      // Create Report List folder inside documents directory
      final reportListDir = Directory('${appDocumentsDir.path}/Report List');
      if (!reportListDir.existsSync()) {
        reportListDir.createSync(recursive: true);
        print('Created Report List directory: ${reportListDir.path}');
      }

      // Generate PDF
      final pdfGenerator = PDFGenerator();
      final pdfBytes = await pdfGenerator.generateReport(report);

      // Create filename with timestamp
      final timestamp = DateTime.now();
      final fileName = 'Mental_Health_Report_${timestamp.day}-${timestamp.month}-${timestamp.year}_${timestamp.hour}-${timestamp.minute}-${timestamp.second}.pdf';

      // Full file path inside Report List folder
      final filePath = '${reportListDir.path}/$fileName';

      // Save the PDF file
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      print('PDF saved successfully in Report List folder: $filePath');
      print('File exists: ${file.existsSync()}');
      print('File size: ${file.lengthSync()} bytes');

      // Show success dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Report Saved Successfully'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your mental health report has been saved in:'),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Folder: Report List',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'File: $fileName',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Text('The PDF is now saved in your app\'s Report List folder.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    final result = await OpenFile.open(filePath);
                    if (result.type != ResultType.done) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Could not open file: ${result.message}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error opening file: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text('Open PDF', style: TextStyle(color: Colors.blue)),
              ),
            ],
          );
        },
      );

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report saved in Report List folder!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

    } catch (e) {
      print('Error saving report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving report: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }




  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF6A1B9A)),
              SizedBox(height: 20),
              Text(
                'Generating your comprehensive report...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16), // Reduced padding for less height
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      'AI REPORT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            // Report Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Info and Wellness Gauge
                    _buildHeaderSection(),

                    SizedBox(height: 20),

                    // Divider
                    Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Mental Health Status & Risk Factor
                    _buildStatusSection(),

                    SizedBox(height: 20),

                    // Key Indicators
                    _buildKeyIndicators(),

                    SizedBox(height: 20),

                    // Screening Observation
                    _buildObservationSection(),

                    SizedBox(height: 20),

                    // Suggested Actions
                    _buildSuggestionsSection(),

                    SizedBox(height: 20),

                    // Disclaimer
                    _buildDisclaimerSection(),

                    SizedBox(height: 30),

                    // Action Buttons
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                      _getGenderIcon(),
                      color: report.getGenderColor(), // Use model method for gender color
                      size: 20
                  ),
                  SizedBox(width: 8),
                  Text(
                    report.userName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Age: ${report.userAge}',
                style: TextStyle(color: Colors.grey.shade300, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'Date: ${report.reportDate.day}/${report.reportDate.month}/${report.reportDate.year}',
                style: TextStyle(color: Colors.grey.shade300, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'Report ID: ${report.reportId.split('_').last}',
                style: TextStyle(color: Colors.grey.shade300, fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: WellnessGaugeChart(
            value: report.comprehensiveScore,
            size: 120,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mental Health Status',
                  style: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  report.getMentalHealthStatusText(), // Use model method
                  style: TextStyle(
                    color: report.getMentalHealthStatusColor(), // Use model method
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Risk Factor',
                  style: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  report.getRiskFactorText(), // Use model method
                  style: TextStyle(
                    color: report.getRiskFactorColor(), // Use model method
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyIndicators() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Indicators',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 35), // Increased spacing further to prevent overlap
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SemiCircleChart(
              value: report.depressionProbability,
              label: 'Depression\nRisk',
              color: _getKeyIndicatorColor(report.depressionProbability),
              size: 100,
            ),
            SemiCircleChart(
              value: report.anxietyProbability,
              label: 'Anxiety\nRisk',
              color: _getKeyIndicatorColor(report.anxietyProbability),
              size: 100,
            ),
            SemiCircleChart(
              value: (report.stressLevel / 41) * 100, // Normalize stress (max 41)
              label: 'Stress\nLevel',
              color: _getKeyIndicatorColor((report.stressLevel / 41) * 100),
              size: 100,
            ),
          ],
        ),
      ],
    );
  }

  // Helper method for Key Indicators color scheme
  Color _getKeyIndicatorColor(double value) {
    if (value >= 69) return Color(0xFFF44336); // Red
    if (value >= 35) return Color(0xFFFFC107); // Yellow
    return Color(0xFF4CAF50); // Green
  }

  Widget _buildObservationSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF6A1B9A).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Screening Observation',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Text(
            report.screeningObservation,
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF00BFA5).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Color(0xFF00BFA5), size: 20),
              SizedBox(width: 8),
              Text(
                'Suggested Actions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildFormattedText(report.suggestedActions),
        ],
      ),
    );
  }

  Widget _buildFormattedText(String text) {
    List<TextSpan> spans = [];

    // Split text by **bold** markers
    List<String> parts = text.split('**');

    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 0) {
        // Normal text
        spans.add(TextSpan(
          text: parts[i],
          style: TextStyle(
            color: Colors.grey.shade300,
            fontSize: 14,
            height: 1.4,
          ),
        ));
      } else {
        // Bold text
        spans.add(TextSpan(
          text: parts[i],
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.4,
            fontWeight: FontWeight.bold,
          ),
        ));
      }
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }


  Widget _buildDisclaimerSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_outlined, color: Colors.orange, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Important Disclaimer',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'This is an AI-generated report based on your responses and is not a medical diagnosis. The information provided is for educational and awareness purposes only. Please consult with qualified mental health professionals for proper assessment, diagnosis, and treatment recommendations.',
                  style: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isSaving ? null : _downloadPDF,
                icon: isSaving
                    ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Icon(Icons.download),
                label: Text(
                  isSaving ? 'Processing...' : 'Download PDF',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF00BFA5),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isSaving ? null : _saveInApp,
                icon: isSaving
                    ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Icon(Icons.save),
                label: Text(
                  isSaving ? 'Saving...' : 'Save in App',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop(); // Go back to home
          },
          child: Text(
            'Back to Home',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
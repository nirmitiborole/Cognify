import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SavedReport {
  final String id;
  final String fileName;
  final String filePath;
  final DateTime savedDate;
  final String title;

  SavedReport({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.savedDate,
    required this.title,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'savedDate': savedDate.toIso8601String(),
      'title': title,
    };
  }

  factory SavedReport.fromJson(Map<String, dynamic> json) {
    return SavedReport(
      id: json['id'],
      fileName: json['fileName'],
      filePath: json['filePath'],
      savedDate: DateTime.parse(json['savedDate']),
      title: json['title'],
    );
  }
}

class ReportStorageService {
  static const String _savedReportsKey = 'saved_reports';
  static const String _reportsDirectory = 'saved_reports';

  // Get the directory where reports will be saved
  static Future<Directory> get _reportsDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final reportsDir = Directory('${appDir.path}/$_reportsDirectory');
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }
    return reportsDir;
  }

  // Save a report to local storage
  static Future<SavedReport> saveReport(List<int> pdfBytes, String title) async {
    final reportsDir = await _reportsDir;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final fileName = 'Report_$id.pdf';
    final filePath = '${reportsDir.path}/$fileName';
    
    // Save the PDF file
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes);
    
    // Create a SavedReport object
    final report = SavedReport(
      id: id,
      fileName: fileName,
      filePath: filePath,
      savedDate: DateTime.now(),
      title: title,
    );
    
    // Save the report metadata to SharedPreferences
    await _saveReportMetadata(report);
    
    return report;
  }

  // Save report metadata to SharedPreferences
  static Future<void> _saveReportMetadata(SavedReport report) async {
    final prefs = await SharedPreferences.getInstance();
    final savedReports = await getAllSavedReports();
    
    savedReports.add(report);
    
    final reportsJson = savedReports.map((r) => r.toJson()).toList();
    await prefs.setString(_savedReportsKey, jsonEncode(reportsJson));
  }

  // Get all saved reports
  static Future<List<SavedReport>> getAllSavedReports() async {
    final prefs = await SharedPreferences.getInstance();
    final reportsJson = prefs.getString(_savedReportsKey);
    
    if (reportsJson == null) {
      return [];
    }
    
    final List<dynamic> decodedReports = jsonDecode(reportsJson);
    return decodedReports
        .map((reportJson) => SavedReport.fromJson(reportJson))
        .toList()
        ..sort((a, b) => b.savedDate.compareTo(a.savedDate)); // Sort by date, newest first
  }

  // Delete a saved report
  static Future<bool> deleteReport(String reportId) async {
    final prefs = await SharedPreferences.getInstance();
    final savedReports = await getAllSavedReports();
    
    final reportToDelete = savedReports.firstWhere(
      (report) => report.id == reportId,
      orElse: () => throw Exception('Report not found'),
    );
    
    // Delete the file
    final file = File(reportToDelete.filePath);
    if (await file.exists()) {
      await file.delete();
    }
    
    // Remove from saved reports list
    savedReports.removeWhere((report) => report.id == reportId);
    
    // Update SharedPreferences
    final reportsJson = savedReports.map((r) => r.toJson()).toList();
    await prefs.setString(_savedReportsKey, jsonEncode(reportsJson));
    
    return true;
  }

  // Get a specific report by ID
  static Future<SavedReport?> getReportById(String reportId) async {
    final savedReports = await getAllSavedReports();
    try {
      return savedReports.firstWhere((report) => report.id == reportId);
    } catch (e) {
      return null;
    }
  }
}
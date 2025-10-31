import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'home_screen.dart';
import 'PreTestScreen.dart';
import 'location_screen.dart';
import '../services/report_storage_service.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import 'saved_report_viewer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../pages/user_prefs.dart';


class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User data
  String userName = "Faiq";
  String userEmail = "faiq@gmail.com";
  int userAge = 21;
  String userGender = "Male";
  String userAddress = "Not specified";
  String userContact = "Not specified";

  // Loading states
  bool isLoading = true;
  bool isUpdating = false;
  bool isLoadingAddress = false;

  // Controllers for editing
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Test reports
  List<Map<String, dynamic>> testReports = [];

  // Locally saved reports
  List<SavedReport> savedReports = [];

  // PDF reports from Report List folder
  List<File> savedPDFReports = [];

  // Navigation
  int _selectedIndex = 4; // Profile screen is index 4

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSavedReports();
    _loadPDFReports();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          setState(() async {
            // userName = userData['name'] ?? user.displayName ?? 'User';
            // userEmail = user.email ?? 'No email';
            // userAge = userData['age'] ?? 0;
            // userGender = userData['gender'] ?? 'Not specified';

            userName = await UserPrefs.getUserName();
            userEmail = await UserPrefs.getUserEmail();
            userAge = await UserPrefs.getUserAge();
            userGender = await UserPrefs.getUserGender();
            userAddress = await UserPrefs.getUserAddress();


            userAddress = await UserPrefs.getUserAddress();
            if (userAddress.isEmpty || userAddress == "Not specified") {
              _loadLocationAddress();
            }


            userContact = userData['contact'] ?? 'Not specified';
          });

          _addressController.text = userAddress;
          _contactController.text = userContact;
          _emailController.text = userEmail;
        }

        await _loadTestReports(user.uid);
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }



  Future<void> _loadLocationAddress() async {
    setState(() {
      isLoadingAddress = true;
      userAddress = "Getting location...";
    });

    try {
      // Check location permission
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          userAddress = "Location services disabled";
          isLoadingAddress = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            userAddress = "Location permission denied";
            isLoadingAddress = false;
          });
          return;
        }
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      );

      // Get address from coordinates (reverse geocoding)
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = _formatAddress(place);

        // Save to SharedPreferences
        await UserPrefs.setUserAddress(address);

        setState(() {
          userAddress = address;
        });
      }
    } catch (e) {
      setState(() {
        userAddress = "Unable to get location";
      });
    } finally {
      setState(() {
        isLoadingAddress = false;
      });
    }
  }

  String _formatAddress(Placemark place) {
    List<String> addressParts = [];

    if (place.subLocality?.isNotEmpty == true) {
      addressParts.add(place.subLocality!);
    }
    if (place.locality?.isNotEmpty == true) {
      addressParts.add(place.locality!);
    }
    if (place.administrativeArea?.isNotEmpty == true) {
      addressParts.add(place.administrativeArea!);
    }
    if (place.country?.isNotEmpty == true) {
      addressParts.add(place.country!);
    }

    return addressParts.isNotEmpty ? addressParts.join(', ') : "Address unavailable";
  }


  Future<void> _loadSavedReports() async {
    try {
      final reports = await ReportStorageService.getAllSavedReports();
      setState(() {
        savedReports = reports;
      });
    } catch (e) {
      print('Error loading saved reports: $e');
    }
  }

  // NEW: Load PDF reports from Report List folder
  Future<void> _loadPDFReports() async {
    try {
      final appDocumentsDir = await getApplicationDocumentsDirectory();
      final reportListDir = Directory('${appDocumentsDir.path}/Report List');

      if (reportListDir.existsSync()) {
        final files = reportListDir.listSync()
            .where((file) => file.path.endsWith('.pdf'))
            .cast<File>()
            .toList();

        // Sort by modification date (newest first)
        files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

        setState(() {
          savedPDFReports = files;
        });

        print('Found ${files.length} PDF reports in Report List folder');
      } else {
        print('Report List folder does not exist');
        setState(() {
          savedPDFReports = [];
        });
      }
    } catch (e) {
      print('Error loading PDF reports: $e');
      setState(() {
        savedPDFReports = [];
      });
    }
  }

  Future<void> _loadTestReports(String userId) async {
    try {
      final reportsQuery = await _firestore
          .collection('reports')
          .where('userId', isEqualTo: userId)
          .orderBy('reportDate', descending: true)
          .limit(3)
          .get();

      setState(() {
        testReports = reportsQuery.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
      });
    } catch (e) {
      print('Error loading test reports: $e');
    }
  }

  Future<void> _updateField(String field, String value) async {
    if (value.trim().isEmpty) return;

    setState(() {
      isUpdating = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          field: value.trim(),
        });

        await _loadUserData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${_getFieldDisplayName(field)} updated successfully'),
            backgroundColor: Color(0xFF6A1B9A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error updating ${_getFieldDisplayName(field)}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        isUpdating = false;
      });
    }
  }

  String _getFieldDisplayName(String field) {
    switch (field) {
      case 'address': return 'Address';
      case 'contact': return 'Contact Number';
      case 'email': return 'Email';
      default: return field;
    }
  }

  String _formatReportDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';

    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return DateFormat('MMM d, yyyy').format(date);
      } else {
        return 'Unknown date format';
      }
    } catch (e) {
      return 'Invalid date';
    }
  }

  // NEW: Helper methods for PDF reports
  String _getFileName(String path) {
    return path.split('/').last.replaceAll('.pdf', '');
  }

  String _getFileDate(File file) {
    final date = file.lastModifiedSync();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // NEW: Delete confirmation dialog
  void _showDeleteConfirmation(File file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A1A),
        title: Text('Delete Report', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete this report?\n\n${_getFileName(file.path)}',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await file.delete();
                Navigator.pop(context); // Close delete dialog
                _loadPDFReports(); // Refresh the list
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Report deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting report: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(String field, String currentValue, TextEditingController controller) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Color(0xFF6A1B9A).withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit ${_getFieldDisplayName(field)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF6A1B9A).withOpacity(0.3)),
                ),
                child: TextField(
                  controller: controller,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Enter ${_getFieldDisplayName(field).toLowerCase()}',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  keyboardType: field == 'contact' ? TextInputType.phone :
                  field == 'email' ? TextInputType.emailAddress :
                  TextInputType.text,
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.grey.withOpacity(0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Cancel', style: TextStyle(color: Colors.grey.shade400)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateField(field, controller.text);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Color(0xFF6A1B9A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A1B9A)),
          ),
        ),
        bottomNavigationBar: _buildCustomBottomNavBar(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 36), // Balance for back button
                ],
              ),

              SizedBox(height: 40),

              // ENHANCED Avatar Section
              Stack(
                alignment: Alignment.center,
                children: [
                  // Glassmorphic Avatar Container
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF6A1B9A).withOpacity(0.3),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Container(
                      margin: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF6A1B9A),
                            Color(0xFF8E24AA),
                            Color(0xFFAB47BC),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 65,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // Modern Edit Badge
                  Positioned(
                    bottom: 5,
                    right: 5,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
                        ),
                        border: Border.all(color: Colors.black, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF6A1B9A).withOpacity(0.4),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // Enhanced Name
              Text(
                userName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),

              SizedBox(height: 12),

              // ENHANCED Age and Gender Section
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF6A1B9A).withOpacity(0.2),
                      Color(0xFF8E24AA).withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Color(0xFF6A1B9A).withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF6A1B9A).withOpacity(0.2),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Gender Icon with Gradient Background
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        userGender.toLowerCase() == 'male' ? Icons.male :
                        userGender.toLowerCase() == 'female' ? Icons.female : Icons.person,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    SizedBox(width: 12),
                    // Age Text with Enhanced Style
                    Text(
                      userAge > 0 ? '$userAge years old' : 'Age not specified',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40),

              // Menu Items
              _buildMenuItem(Icons.lock, 'Privacy & Setting', () {}),
              _buildMenuItem(Icons.notifications, 'Notifications', () {}),
              _buildEditableMenuItem(Icons.location_on, 'Address', userAddress, 'address', _addressController),
              _buildEditableMenuItem(Icons.phone, 'Contact Number', userContact, 'contact', _contactController),
              _buildEditableMenuItem(Icons.email, 'Email', userEmail, 'email', _emailController),
              _buildMenuItem(Icons.assessment, 'Test Reports', () {
                _showTestReportsDialog();
              }),

              SizedBox(height: 30),

              // Sign Out Button
              GestureDetector(
                onTap: () async {
                  await _auth.signOut();
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFF6A1B9A), width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Color(0xFF6A1B9A), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Sign Out',
                        style: TextStyle(
                          color: Color(0xFF6A1B9A),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 100), // Space for bottom nav
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildCustomBottomNavBar(),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Color(0xFF6A1B9A), size: 22),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade600, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyReportsMessage() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          'No test reports available',
          style: TextStyle(color: Colors.grey.shade400),
        ),
      ),
    );
  }

  Widget _buildEmptySavedReportsMessage() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          'No saved reports found',
          style: TextStyle(color: Colors.grey.shade400),
        ),
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF6A1B9A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.assessment, color: Color(0xFF6A1B9A), size: 24),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Score: ${(report["comprehensiveScore"] ?? 0).toStringAsFixed(1)}/100',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  _formatReportDate(report["reportDate"]),
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedReportCard(SavedReport report) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SavedReportViewer(report: report),
          ),
        ).then((deleted) {
          if (deleted == true) {
            _loadSavedReports(); // Refresh if report was deleted
          }
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF6A1B9A).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.description, color: Color(0xFF6A1B9A), size: 24),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Saved on: ${report.savedDate}',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.open_in_new, color: Color(0xFF6A1B9A), size: 20),
              onPressed: () {
                OpenFile.open(report.filePath);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableMenuItem(IconData icon, String title, String value, String field, TextEditingController controller) {
    return GestureDetector(
      onTap: () {
        controller.text = value == 'Not specified' ? '' : value;
        _showEditDialog(field, value, controller);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Color(0xFF6A1B9A), size: 22),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (value != 'Not specified')
                    Text(
                      value,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.edit, color: Color(0xFF6A1B9A), size: 18),
          ],
        ),
      ),
    );
  }

  // UPDATED: Enhanced Test Reports Dialog with PDF reports
  void _showTestReportsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(20),
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Test Reports',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _loadPDFReports(); // Refresh reports
                    },
                    icon: Icon(Icons.refresh, color: Color(0xFF6A1B9A)),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Tabs
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Color(0xFF6A1B9A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Saved PDF Reports',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Reports List
              Expanded(
                child: savedPDFReports.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No PDF reports found',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Complete a mental health test and save the report',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: savedPDFReports.length,
                  itemBuilder: (context, index) {
                    final file = savedPDFReports[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF6A1B9A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(0xFF6A1B9A).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // File Name Section
                          Container(
                            width: double.infinity,
                            child: Text(
                              _getFileName(file.path),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          SizedBox(height: 8),

                          // File Details
                          Text(
                            'Created: ${_getFileDate(file)}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Size: ${_getFileSize(file)}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),

                          SizedBox(height: 16),

                          // PDF Icon and Action Buttons Row
                          Row(
                            children: [
                              // PDF Icon
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(0xFF6A1B9A),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.picture_as_pdf,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),

                              Spacer(), // This creates space between PDF icon and action buttons

                              // Action Buttons
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Open Button
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      try {
                                        final result = await OpenFile.open(file.path);
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
                                    icon: Icon(Icons.open_in_new, size: 16),
                                    label: Text('', style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      minimumSize: Size(0, 32),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),

                                  SizedBox(width: 12), // Space between buttons

                                  // Delete Button
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      _showDeleteConfirmation(file);
                                    },
                                    icon: Icon(Icons.delete, size: 16),
                                    label: Text('Delete', style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      minimumSize: Size(0, 32),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 20),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6A1B9A),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  String _formatReportDateSimple(dynamic timestamp) {
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return 'Unknown date';
      }
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (context) => PreTestScreen()));
        break;
      case 2:
      // AI Chat - implement later
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (context) => LocationScreen()));
        break;
      case 4:
      // Already on profile screen
        break;
    }
  }

  // Custom Bottom Navigation Bar (Your Code)
  Widget _buildCustomBottomNavBar() {
    return Container(
      height: 70,
      margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Animated sliding capsule indicator
          AnimatedPositioned(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: _getIndicatorPosition(),
            top: 10,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Color(0xFF6A1B9A),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF6A1B9A).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // Navigation items
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.home_rounded, 0),
                _buildNavItem(Icons.quiz_rounded, 1),
                _buildNavItem(Icons.smart_toy_rounded, 2),
                _buildNavItem(Icons.location_on_rounded, 3),
                _buildNavItem(Icons.person_rounded, 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _getIndicatorPosition() {
    double screenWidth = MediaQuery.of(context).size.width;
    double containerWidth = screenWidth - 40; // Total container width minus margins
    double tabWidth = containerWidth / 5;
    return (_selectedIndex * tabWidth) + (tabWidth - 50) / 2 + 5; // +5 for alignment
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      child: Container(
        width: (MediaQuery.of(context).size.width - 40) / 5,
        height: 70,
        child: Center(
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            padding: EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 26,
              color: isSelected ? Color(0xFF6A1B9A) : Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }
}

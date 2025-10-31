
import 'package:cognify/pages/PreTestScreen.dart';
import 'package:cognify/pages/user_prefs.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import 'login_screen.dart';
import 'test_screen.dart';
import 'chatbot_screen.dart';
import 'location_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  String _userName = '';
  int _selectedIndex = 0;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // Mental health quotes
  final List<String> _mentalHealthQuotes = [
    "Your mental health is a priority. Your happiness is essential. Your self-care is a necessity.",
    "It's okay to not be okay. What's not okay is staying that way.",
    "You are stronger than you think and more resilient than you imagine.",
    "Progress, not perfection. Small steps count too.",
    "Your current situation is not your final destination.",
    "Mental health is not a destination, but a process.",
    "Be patient with yourself. Self-growth is tender; it's holy ground.",
  ];

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _fetchUserName();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  // Future<void> _fetchUserName() async {
  //   if (_user != null) {
  //     try {
  //       DocumentSnapshot userDoc = await _firestore.collection('users').doc(_user!.uid).get();
  //       if (userDoc.exists) {
  //         setState(() {
  //           _userName = userDoc['name'] ?? _user!.displayName ?? 'User';
  //         });
  //       }
  //     } catch (e) {
  //       setState(() {
  //         _userName = _user!.displayName ?? 'User';
  //       });
  //     }
  //   }
  // }


  // fetching user name from shred prefrence rather than firebase
  Future<void> _fetchUserName() async {
    try {
      // Get user name from SharedPreferences (super fast!)
      String userName = await UserPrefs.getUserName();

      setState(() {
        _userName = userName;
      });

      print('User name fetched from SharedPreferences: $userName');

    } catch (e) {
      print('Error fetching user name from SharedPreferences: $e');

      // Fallback to Firebase user display name if SharedPreferences fails
      setState(() {
        _userName = _user?.displayName ?? 'User';
      });
    }
  }


  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (context) => PreTestScreen()));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (context) => ChatbotScreen()));
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (context) => LocationScreen()));
        break;
      case 4:
        Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
        break;
    }
  }

  String _getTodaysQuote() {
    int today = DateTime.now().day;
    return _mentalHealthQuotes[today % _mentalHealthQuotes.length];
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 30),

                // Simple Welcome Text
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildSimpleWelcome(),
                ),

                SizedBox(height: 25),

                // Daily Quote Section with Blur Effect
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildDailyQuoteSection(),
                ),

                SizedBox(height: 30),

                // Featured Assessment Section
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildFeaturedAssessmentSection(),
                ),

                SizedBox(height: 30),

                // 2x2 Grid Layout with Blur Effects
                SlideTransition(
                  position: _slideAnimation,
                  child: _buildGridExploreSection(),
                ),

                SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildCustomBottomNavBar(),
    );
  }

  Widget _buildSimpleWelcome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back,',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 18,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Text(
              _userName.isNotEmpty ? _userName : 'Loading...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 10),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF6A1B9A).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.waving_hand,
                color: Color(0xFF6A1B9A),
                size: 24,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          'Ready to prioritize your mental wellness today?',
          style: TextStyle(
            color: Colors.grey.shade300,
            fontSize: 16,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyQuoteSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.format_quote, color: Color(0xFF6A1B9A), size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Daily Inspiration',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Text(
                _getTodaysQuote(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedAssessmentSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A148C), Color(0xFF6A1B9A), Color(0xFF8E24AA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6A1B9A).withOpacity(0.5),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.quiz_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🧠 Take Your Assessment',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Discover Your Mental Wellness Level',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                '✨ "Understanding your mind is the first step towards healing. Take our scientifically-backed assessment to unlock personalized insights about your mental health."',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 15,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.timer, color: Colors.white70, size: 18),
                  SizedBox(width: 5),
                  Text(
                    '5-7 minutes  •  ',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Icon(Icons.verified_user, color: Colors.white70, size: 18),
                  SizedBox(width: 5),
                  Text(
                    'Confidential & Secure',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF6A1B9A),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PreTestScreen()),
                    );
                  },
                  child: Text(
                    'Start Assessment Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  Widget _buildGridExploreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: Color(0xFF6A1B9A),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Explore More',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          'Comprehensive tools for your mental wellness journey',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 25),

        // First Row (2 cards) - Fixed overflow
        Row(
          children: [
            Expanded(
              child: _buildBlurredGridCard(
                'MindBot AI',
                'Your Personal Mental Health Companion',
                Icons.psychology_rounded,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatbotScreen())),
              ),
            ),
            SizedBox(width: 15),
            Expanded(
              child: _buildBlurredGridCard(
                'Find Experts',
                'Connect with Licensed Professionals',
                Icons.local_hospital_rounded,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => LocationScreen())),
              ),
            ),
          ],
        ),
        SizedBox(height: 15),

        // Second Row (2 cards) - Fixed overflow
        Row(
          children: [
            Expanded(
              child: _buildBlurredGridCard(
                'Mind Exercises',
                'Guided Meditation & Relaxation',
                Icons.self_improvement_rounded,
                    () {},
              ),
            ),
            SizedBox(width: 15),
            Expanded(
              child: _buildBlurredGridCard(
                'Wellness Tips',
                'Daily Mental Health Insights',
                Icons.tips_and_updates_rounded,
                    () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBlurredGridCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 120,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Color(0xFF6A1B9A), size: 28),
                SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Expanded(
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
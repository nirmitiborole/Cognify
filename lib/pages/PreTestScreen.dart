import 'package:flutter/material.dart';
import 'package:cognify/pages/user_prefs.dart'; // Import your UserPrefs class
import 'test_screen.dart'; // Import your existing TestScreen

class PreTestScreen extends StatefulWidget {
  @override
  _PreTestScreenState createState() => _PreTestScreenState();
}

class _PreTestScreenState extends State<PreTestScreen> with TickerProviderStateMixin {
  String? selectedGender;
  TextEditingController ageController = TextEditingController();

  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> genderOptions = [
    {'value': 'Male', 'icon': Icons.male},
    {'value': 'Female', 'icon': Icons.female},
    {'value': 'Other', 'icon': Icons.transgender},
    {'value': 'Prefer not to say', 'icon': Icons.help_outline},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSavedData(); // Load previously saved data
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeIn),
    );

    _pulseController.repeat(reverse: true);
    _slideController.forward();
  }

  // Load previously saved gender and age from SharedPreferences
  Future<void> _loadSavedData() async {
    try {
      final savedGender = await UserPrefs.getUserGender();
      final savedAge = await UserPrefs.getUserAge();

      setState(() {
        if (savedGender.isNotEmpty && savedGender != 'Not specified') {
          selectedGender = savedGender;
        }
        if (savedAge > 0) {
          ageController.text = savedAge.toString();
        }
      });
    } catch (e) {
      print('Error loading saved data: $e');
    }
  }

  // Save gender to SharedPreferences when changed
  Future<void> _saveGender(String gender) async {
    try {
      await UserPrefs.setUserGender(gender);
      print('Gender saved: $gender');
    } catch (e) {
      print('Error saving gender: $e');
    }
  }

  // Save age to SharedPreferences when changed
  Future<void> _saveAge(int age) async {
    try {
      await UserPrefs.setUserAge(age);
      print('Age saved: $age');
    } catch (e) {
      print('Error saving age: $e');
    }
  }

  @override
  void dispose() {
    ageController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  bool _canStartTest() {
    return selectedGender != null &&
        ageController.text.isNotEmpty &&
        int.tryParse(ageController.text) != null &&
        int.parse(ageController.text) >= 13 &&
        int.parse(ageController.text) <= 100;
  }

  void _startTest() {
    if (_canStartTest()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TestScreen(
            userGender: selectedGender!,
            userAge: int.parse(ageController.text),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          children: [
            // Header with floating effect
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA), Color(0xFFAB47BC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF6A1B9A).withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          'HEALTH ASSESSMENT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Container(
                          width: 60,
                          height: 2,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 36),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          SizedBox(height: 20),

                          // Animated Central Container
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      colors: [
                                        Color(0xFF6A1B9A).withOpacity(0.8),
                                        Color(0xFF8E24AA).withOpacity(0.6),
                                        Color(0xFFAB47BC).withOpacity(0.4),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF6A1B9A).withOpacity(0.4),
                                        blurRadius: 30,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.psychology_outlined,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: 30),

                          // Title with gradient
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
                            ).createShader(bounds),
                            child: Text(
                              'Before We Begin',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Help us personalize your mental health assessment',
                            style: TextStyle(
                              color: Colors.grey.shade300,
                              fontSize: 16,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: 30),

                          // Gender Selection with animated cards
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.person_outline,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Gender',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 13),

                                // Custom Dropdown
                                Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF3D3D3D),
                                    borderRadius: BorderRadius.circular(15),
                                    border: selectedGender != null ? Border.all(
                                      color: Color(0xFF6A1B9A),
                                      width: 2,
                                    ) : null,
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: selectedGender,
                                      hint: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 16),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.arrow_drop_down,
                                              color: Colors.grey.shade400,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Select your gender',
                                              style: TextStyle(
                                                color: Colors.grey.shade400,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      dropdownColor: Color(0xFF3D3D3D),
                                      borderRadius: BorderRadius.circular(15),
                                      items: genderOptions.map((option) {
                                        return DropdownMenuItem<String>(
                                          value: option['value'],
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 16),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  option['icon'],
                                                  color: Color(0xFF6A1B9A),
                                                  size: 20,
                                                ),
                                                SizedBox(width: 12),
                                                Text(
                                                  option['value'],
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          selectedGender = value;
                                        });
                                        // Save gender immediately when changed
                                        if (value != null) {
                                          _saveGender(value);
                                        }
                                      },
                                      selectedItemBuilder: (context) {
                                        return genderOptions.map((option) {
                                          return Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 16),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  option['icon'],
                                                  color: Color(0xFF6A1B9A),
                                                  size: 20,
                                                ),
                                                SizedBox(width: 10),
                                                Text(
                                                  option['value'],
                                                  style: TextStyle(
                                                    color: Color(0xFF6A1B9A),
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList();
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 18),

                          // Age Input with modern design
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.cake_outlined,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Age',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 15),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF3D3D3D),
                                    borderRadius: BorderRadius.circular(15),
                                    border: ageController.text.isNotEmpty && _canStartTest()
                                        ? Border.all(color: Color(0xFF6A1B9A), width: 2)
                                        : null,
                                  ),
                                  child: TextField(
                                    controller: ageController,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Enter your age (13-100)',
                                      hintStyle: TextStyle(color: Colors.grey.shade400),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                      prefixIcon: Icon(
                                        Icons.numbers,
                                        color: ageController.text.isNotEmpty && _canStartTest()
                                            ? Color(0xFF6A1B9A)
                                            : Colors.grey.shade500,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      setState(() {});
                                      // Save age immediately when changed and valid
                                      final age = int.tryParse(value);
                                      if (age != null && age >= 13 && age <= 100) {
                                        _saveAge(age);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 20),

                          // Privacy Notice with animation
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Color(0xFF6A1B9A).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF6A1B9A).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.security,
                                    color: Color(0xFF6A1B9A),
                                    size: 18,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Your information is secure and automatically saved for future assessments',
                                    style: TextStyle(
                                      color: Colors.grey.shade300,
                                      fontSize: 13,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 30),

                          // Simple Start Button that always works
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF00BFA5), Color(0xFF00ACC1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF00BFA5).withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TestScreen(
                                        userGender: selectedGender ?? 'Not specified',
                                        userAge: int.tryParse(ageController.text) ?? 18,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(28),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Start Assessment',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'test_screen.dart'; // Import your existing TestScreen
//
// class PreTestScreen extends StatefulWidget {
//   @override
//   _PreTestScreenState createState() => _PreTestScreenState();
// }
//
// class _PreTestScreenState extends State<PreTestScreen> with TickerProviderStateMixin {
//   String? selectedGender;
//   TextEditingController ageController = TextEditingController();
//
//   late AnimationController _pulseController;
//   late AnimationController _slideController;
//   late Animation<double> _pulseAnimation;
//   late Animation<Offset> _slideAnimation;
//   late Animation<double> _fadeAnimation;
//
//   final List<Map<String, dynamic>> genderOptions = [
//     {'value': 'Male', 'icon': Icons.male},
//     {'value': 'Female', 'icon': Icons.female},
//     {'value': 'Other', 'icon': Icons.transgender},
//     {'value': 'Prefer not to say', 'icon': Icons.help_outline},
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeAnimations();
//   }
//
//   void _initializeAnimations() {
//     _pulseController = AnimationController(
//       duration: Duration(seconds: 2),
//       vsync: this,
//     );
//
//     _slideController = AnimationController(
//       duration: Duration(milliseconds: 800),
//       vsync: this,
//     );
//
//     _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
//       CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
//     );
//
//     _slideAnimation = Tween<Offset>(begin: Offset(0, 0.5), end: Offset.zero).animate(
//       CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
//     );
//
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _slideController, curve: Curves.easeIn),
//     );
//
//     _pulseController.repeat(reverse: true);
//     _slideController.forward();
//   }
//
//   @override
//   void dispose() {
//     ageController.dispose();
//     _pulseController.dispose();
//     _slideController.dispose();
//     super.dispose();
//   }
//
//   bool _canStartTest() {
//     return selectedGender != null &&
//         ageController.text.isNotEmpty &&
//         int.tryParse(ageController.text) != null &&
//         int.parse(ageController.text) >= 13 &&
//         int.parse(ageController.text) <= 100;
//   }
//
//   void _startTest() {
//     if (_canStartTest()) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => TestScreen(
//             userGender: selectedGender!,
//             userAge: int.parse(ageController.text),
//           ),
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFF1A1A1A),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Header with floating effect
//             Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA), Color(0xFFAB47BC)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: BorderRadius.only(
//                   bottomLeft: Radius.circular(50),
//                   bottomRight: Radius.circular(50),
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Color(0xFF6A1B9A).withOpacity(0.3),
//                     blurRadius: 20,
//                     offset: Offset(0, 10),
//                   ),
//                 ],
//               ),
//               child: Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     GestureDetector(
//                       onTap: () => Navigator.pop(context),
//                       child: Container(
//                         padding: EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.2),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Icon(
//                           Icons.arrow_back_ios_new,
//                           color: Colors.white,
//                           size: 20,
//                         ),
//                       ),
//                     ),
//                     Column(
//                       children: [
//                         Text(
//                           'HEALTH ASSESSMENT',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             letterSpacing: 1.5,
//                           ),
//                         ),
//                         SizedBox(height: 4),
//                         Container(
//                           width: 60,
//                           height: 2,
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(1),
//                           ),
//                         ),
//                       ],
//                     ),
//                     SizedBox(width: 36),
//                   ],
//                 ),
//               ),
//             ),
//
//             // Content
//             Expanded(
//               child: SingleChildScrollView(
//                 physics: BouncingScrollPhysics(),
//                 child: Padding(
//                   padding: EdgeInsets.all(24),
//                   child: FadeTransition(
//                     opacity: _fadeAnimation,
//                     child: SlideTransition(
//                       position: _slideAnimation,
//                       child: Column(
//                         children: [
//                           SizedBox(height: 20),
//
//                           // Animated Central Container
//                           AnimatedBuilder(
//                             animation: _pulseAnimation,
//                             builder: (context, child) {
//                               return Transform.scale(
//                                 scale: _pulseAnimation.value,
//                                 child: Container(
//                                   width: 120,
//                                   height: 120,
//                                   decoration: BoxDecoration(
//                                     gradient: RadialGradient(
//                                       colors: [
//                                         Color(0xFF6A1B9A).withOpacity(0.8),
//                                         Color(0xFF8E24AA).withOpacity(0.6),
//                                         Color(0xFFAB47BC).withOpacity(0.4),
//                                       ],
//                                     ),
//                                     shape: BoxShape.circle,
//                                     boxShadow: [
//                                       BoxShadow(
//                                         color: Color(0xFF6A1B9A).withOpacity(0.4),
//                                         blurRadius: 30,
//                                         spreadRadius: 5,
//                                       ),
//                                     ],
//                                   ),
//                                   child: Icon(
//                                     Icons.psychology_outlined,
//                                     color: Colors.white,
//                                     size: 50,
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//
//                           SizedBox(height: 30),
//
//                           // Title with gradient
//                           ShaderMask(
//                             shaderCallback: (bounds) => LinearGradient(
//                               colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
//                             ).createShader(bounds),
//                             child: Text(
//                               'Before We Begin',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 28,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                           SizedBox(height: 10),
//                           Text(
//                             'Help us personalize your mental health assessment',
//                             style: TextStyle(
//                               color: Colors.grey.shade300,
//                               fontSize: 16,
//                               height: 1.4,
//                             ),
//                             textAlign: TextAlign.center,
//                           ),
//
//                           SizedBox(height: 30),
//
//                           // Gender Selection with animated cards
//                           Container(
//                             padding: EdgeInsets.all(20),
//                             decoration: BoxDecoration(
//                               color: Color(0xFF2A2A2A),
//                               borderRadius: BorderRadius.circular(20),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.black.withOpacity(0.3),
//                                   blurRadius: 15,
//                                   offset: Offset(0, 5),
//                                 ),
//                               ],
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Row(
//                                   children: [
//                                     Container(
//                                       padding: EdgeInsets.all(8),
//                                       decoration: BoxDecoration(
//                                         gradient: LinearGradient(
//                                           colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
//                                         ),
//                                         borderRadius: BorderRadius.circular(8),
//                                       ),
//                                       child: Icon(
//                                         Icons.person_outline,
//                                         color: Colors.white,
//                                         size: 20,
//                                       ),
//                                     ),
//                                     SizedBox(width: 12),
//                                     Text(
//                                       'Gender',
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 18,
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 SizedBox(height: 13),
//
//                                 // Custom Dropdown
//                                 Container(
//                                   decoration: BoxDecoration(
//                                     color: Color(0xFF3D3D3D),
//                                     borderRadius: BorderRadius.circular(15),
//                                     border: selectedGender != null ? Border.all(
//                                       color: Color(0xFF6A1B9A),
//                                       width: 2,
//                                     ) : null,
//                                   ),
//                                   child: DropdownButtonHideUnderline(
//                                     child: DropdownButton<String>(
//                                       isExpanded: true,
//                                       value: selectedGender,
//                                       hint: Padding(
//                                         padding: EdgeInsets.symmetric(horizontal: 16),
//                                         child: Row(
//                                           children: [
//                                             Icon(
//                                               Icons.arrow_drop_down,
//                                               color: Colors.grey.shade400,
//                                             ),
//                                             SizedBox(width: 8),
//                                             Text(
//                                               'Select your gender',
//                                               style: TextStyle(
//                                                 color: Colors.grey.shade400,
//                                                 fontSize: 16,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                       dropdownColor: Color(0xFF3D3D3D),
//                                       borderRadius: BorderRadius.circular(15),
//                                       items: genderOptions.map((option) {
//                                         return DropdownMenuItem<String>(
//                                           value: option['value'],
//                                           child: Padding(
//                                             padding: EdgeInsets.symmetric(horizontal: 16),
//                                             child: Row(
//                                               children: [
//                                                 Icon(
//                                                   option['icon'],
//                                                   color: Color(0xFF6A1B9A),
//                                                   size: 20,
//                                                 ),
//                                                 SizedBox(width: 12),
//                                                 Text(
//                                                   option['value'],
//                                                   style: TextStyle(
//                                                     color: Colors.white,
//                                                     fontSize: 16,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           ),
//                                         );
//                                       }).toList(),
//                                       onChanged: (value) {
//                                         setState(() {
//                                           selectedGender = value;
//                                         });
//                                       },
//                                       selectedItemBuilder: (context) {
//                                         return genderOptions.map((option) {
//                                           return Padding(
//                                             padding: EdgeInsets.symmetric(horizontal: 16),
//                                             child: Row(
//                                               children: [
//                                                 Icon(
//                                                   option['icon'],
//                                                   color: Color(0xFF6A1B9A),
//                                                   size: 20,
//                                                 ),
//                                                 SizedBox(width: 10),
//                                                 Text(
//                                                   option['value'],
//                                                   style: TextStyle(
//                                                     color: Color(0xFF6A1B9A),
//                                                     fontSize: 16,
//                                                     fontWeight: FontWeight.w600,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           );
//                                         }).toList();
//                                       },
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//
//                           SizedBox(height: 18),
//
//                           // Age Input with modern design
//                           Container(
//                             padding: EdgeInsets.all(20),
//                             decoration: BoxDecoration(
//                               color: Color(0xFF2A2A2A),
//                               borderRadius: BorderRadius.circular(20),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.black.withOpacity(0.3),
//                                   blurRadius: 15,
//                                   offset: Offset(0, 5),
//                                 ),
//                               ],
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Row(
//                                   children: [
//                                     Container(
//                                       padding: EdgeInsets.all(8),
//                                       decoration: BoxDecoration(
//                                         gradient: LinearGradient(
//                                           colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
//                                         ),
//                                         borderRadius: BorderRadius.circular(8),
//                                       ),
//                                       child: Icon(
//                                         Icons.cake_outlined,
//                                         color: Colors.white,
//                                         size: 20,
//                                       ),
//                                     ),
//                                     SizedBox(width: 10),
//                                     Text(
//                                       'Age',
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 18,
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 SizedBox(height: 15),
//                                 Container(
//                                   decoration: BoxDecoration(
//                                     color: Color(0xFF3D3D3D),
//                                     borderRadius: BorderRadius.circular(15),
//                                     border: ageController.text.isNotEmpty && _canStartTest()
//                                         ? Border.all(color: Color(0xFF6A1B9A), width: 2)
//                                         : null,
//                                   ),
//                                   child: TextField(
//                                     controller: ageController,
//                                     keyboardType: TextInputType.number,
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                     decoration: InputDecoration(
//                                       hintText: 'Enter your age (13-100)',
//                                       hintStyle: TextStyle(color: Colors.grey.shade400),
//                                       border: InputBorder.none,
//                                       contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//                                       prefixIcon: Icon(
//                                         Icons.numbers,
//                                         color: ageController.text.isNotEmpty && _canStartTest()
//                                             ? Color(0xFF6A1B9A)
//                                             : Colors.grey.shade500,
//                                       ),
//                                     ),
//                                     onChanged: (value) {
//                                       setState(() {});
//                                     },
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//
//                           SizedBox(height: 20),
//
//                           // Privacy Notice with animation
//                           Container(
//                             padding: EdgeInsets.all(12),
//                             decoration: BoxDecoration(
//                               color: Color(0xFF2A2A2A),
//                               borderRadius: BorderRadius.circular(15),
//                               border: Border.all(
//                                 color: Color(0xFF6A1B9A).withOpacity(0.3),
//                                 width: 1,
//                               ),
//                             ),
//                             child: Row(
//                               children: [
//                                 Container(
//                                   padding: EdgeInsets.all(8),
//                                   decoration: BoxDecoration(
//                                     color: Color(0xFF6A1B9A).withOpacity(0.2),
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   child: Icon(
//                                     Icons.security,
//                                     color: Color(0xFF6A1B9A),
//                                     size: 18,
//                                   ),
//                                 ),
//                                 SizedBox(width: 12),
//                                 Expanded(
//                                   child: Text(
//                                     'Your information is secure and used only for personalized assessment',
//                                     style: TextStyle(
//                                       color: Colors.grey.shade300,
//                                       fontSize: 13,
//                                       height: 1.3,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//
//                           SizedBox(height: 30),
//
//                           // Simple Start Button that always works
//                           Container(
//                             width: double.infinity,
//                             height: 56,
//                             decoration: BoxDecoration(
//                               gradient: LinearGradient(
//                                 colors: [Color(0xFF00BFA5), Color(0xFF00ACC1)],
//                                 begin: Alignment.topLeft,
//                                 end: Alignment.bottomRight,
//                               ),
//                               borderRadius: BorderRadius.circular(28),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Color(0xFF00BFA5).withOpacity(0.4),
//                                   blurRadius: 20,
//                                   offset: Offset(0, 8),
//                                 ),
//                               ],
//                             ),
//                             child: Material(
//                               color: Colors.transparent,
//                               child: InkWell(
//                                 onTap: () {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (context) => TestScreen(
//                                         userGender: selectedGender ?? 'Not specified',
//                                         userAge: int.tryParse(ageController.text) ?? 18,
//                                       ),
//                                     ),
//                                   );
//                                 },
//                                 borderRadius: BorderRadius.circular(28),
//                                 child: Center(
//                                   child: Row(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Icon(
//                                         Icons.play_arrow_rounded,
//                                         color: Colors.white,
//                                         size: 24,
//                                       ),
//                                       SizedBox(width: 8),
//                                       Text(
//                                         'Start Assessment',
//                                         style: TextStyle(
//                                           color: Colors.white,
//                                           fontSize: 18,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//
//                           SizedBox(height: 20),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
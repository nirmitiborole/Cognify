import 'package:flutter/material.dart';
import 'package:cognify/pages/login_screen.dart';

class LaunchScreen extends StatefulWidget {
  @override
  _LaunchScreenState createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen>
    with TickerProviderStateMixin {
  late AnimationController _fastController;
  late AnimationController _slowController;
  late Animation<double> _fastAnimation;
  late Animation<double> _slowAnimation;

  @override
  void initState() {
    super.initState();

    // Fast animation for dark boxes (moving left)
    _fastController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 6),
    )..repeat();

    // Slow animation for light boxes (moving right)
    _slowController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10),
    )..repeat();

    _fastAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fastController, curve: Curves.linear),
    );

    _slowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slowController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _fastController.dispose();
    _slowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A), // Dark background
      body: Stack(
        children: [
          // Top header
          Positioned(
            top: size.height * 0.08,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'All Tools at Your Fingertips!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'All Tools at Your Fingertips!',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),

          // First row - Fast moving dark boxes (increased spacing)
          AnimatedBuilder(
            animation: _fastAnimation,
            builder: (context, child) {
              return Positioned(
                top: size.height * 0.38, // Moved up slightly to accommodate larger spacing
                child: _buildContinuousFastRow(),
              );
            },
          ),

          // Second row - Slow moving light boxes (increased spacing)
          AnimatedBuilder(
            animation: _slowAnimation,
            builder: (context, child) {
              return Positioned(
                top: size.height * 0.54, // Increased spacing (16% gap from row 1)
                child: _buildContinuousSlowRow(),
              );
            },
          ),

          // Third row - Fast moving dark boxes (increased spacing)
          AnimatedBuilder(
            animation: _fastAnimation,
            builder: (context, child) {
              return Positioned(
                top: size.height * 0.70, // Increased spacing (16% gap from row 2)
                child: _buildContinuousFastRow2(),
              );
            },
          ),

          // Next button with proper margin from row 3
          Positioned(
            bottom: size.height * 0.04, // Slightly reduced to make room for spacing
            left: size.width * 0.05,
            right: size.width * 0.05,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6A1B9A), // Purple color matching the boxes
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: Text(
                'Next',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinuousFastRow() {
    final Size size = MediaQuery.of(context).size;
    double offset = -size.width * 1.5 * _fastAnimation.value;

    return Transform.translate(
      offset: Offset(offset, 0),
      child: Row(
        children: [
          // First set
          _buildFeatureCard('Depression\nPrediction', Color(0xFF2D2D2D), _buildDepressionIcon()),
          SizedBox(width: 20),
          _buildFeatureCard('Mood\nAssessment', Color(0xFF6A1B9A), _buildMoodIcon()), // Purple color
          SizedBox(width: 20),
          _buildFeatureCard('Anxiety\nDetection', Color(0xFF2D2D2D), _buildAnxietyIcon()),
          SizedBox(width: 20),

          // Second set
          _buildFeatureCard('Depression\nPrediction', Color(0xFF2D2D2D), _buildDepressionIcon()),
          SizedBox(width: 20),
          _buildFeatureCard('Mood\nAssessment', Color(0xFF6A1B9A), _buildMoodIcon()), // Purple color
          SizedBox(width: 20),
          _buildFeatureCard('Anxiety\nDetection', Color(0xFF2D2D2D), _buildAnxietyIcon()),
          SizedBox(width: 20),

          // Third set
          _buildFeatureCard('Depression\nPrediction', Color(0xFF2D2D2D), _buildDepressionIcon()),
          SizedBox(width: 20),
          _buildFeatureCard('Mood\nAssessment', Color(0xFF6A1B9A), _buildMoodIcon()), // Purple color
          SizedBox(width: 20),
          _buildFeatureCard('Anxiety\nDetection', Color(0xFF2D2D2D), _buildAnxietyIcon()),
          SizedBox(width: 20),

          // Fourth set
          _buildFeatureCard('Depression\nPrediction', Color(0xFF2D2D2D), _buildDepressionIcon()),
          SizedBox(width: 20),
          _buildFeatureCard('Mood\nAssessment', Color(0xFF6A1B9A), _buildMoodIcon()), // Purple color
          SizedBox(width: 20),
          _buildFeatureCard('Anxiety\nDetection', Color(0xFF2D2D2D), _buildAnxietyIcon()),
          SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildContinuousSlowRow() {
    final Size size = MediaQuery.of(context).size;
    double offset = -size.width * 0.5 + (size.width * 1.0 * _slowAnimation.value);

    return Transform.translate(
      offset: Offset(offset, 0),
      child: Row(
        children: [
          // First set
          _buildFeatureCard('Video Chat\nConsultancy', Color(0xFFE8EAF6), _buildVideoChatIcon(), textColor: Colors.black87),
          SizedBox(width: 20),
          _buildFeatureCard('AI Report\nGeneration', Color(0xFFE8EAF6), _buildReportIcon(), textColor: Colors.black87),
          SizedBox(width: 20),

          // Second set
          _buildFeatureCard('Video Chat\nConsultancy', Color(0xFFE8EAF6), _buildVideoChatIcon(), textColor: Colors.black87),
          SizedBox(width: 20),
          _buildFeatureCard('AI Report\nGeneration', Color(0xFFE8EAF6), _buildReportIcon(), textColor: Colors.black87),
          SizedBox(width: 20),

          // Third set
          _buildFeatureCard('Video Chat\nConsultancy', Color(0xFFE8EAF6), _buildVideoChatIcon(), textColor: Colors.black87),
          SizedBox(width: 20),
          _buildFeatureCard('AI Report\nGeneration', Color(0xFFE8EAF6), _buildReportIcon(), textColor: Colors.black87),
          SizedBox(width: 20),

          // Fourth set
          _buildFeatureCard('Video Chat\nConsultancy', Color(0xFFE8EAF6), _buildVideoChatIcon(), textColor: Colors.black87),
          SizedBox(width: 20),
          _buildFeatureCard('AI Report\nGeneration', Color(0xFFE8EAF6), _buildReportIcon(), textColor: Colors.black87),
          SizedBox(width: 20),

          // Fifth set
          _buildFeatureCard('Video Chat\nConsultancy', Color(0xFFE8EAF6), _buildVideoChatIcon(), textColor: Colors.black87),
          SizedBox(width: 20),
          _buildFeatureCard('AI Report\nGeneration', Color(0xFFE8EAF6), _buildReportIcon(), textColor: Colors.black87),
          SizedBox(width: 20),

          // Sixth set - More repetitions for light boxes
          _buildFeatureCard('Video Chat\nConsultancy', Color(0xFFE8EAF6), _buildVideoChatIcon(), textColor: Colors.black87),
          SizedBox(width: 20),
          _buildFeatureCard('AI Report\nGeneration', Color(0xFFE8EAF6), _buildReportIcon(), textColor: Colors.black87),
          SizedBox(width: 20),

          // Seventh set
          _buildFeatureCard('Video Chat\nConsultancy', Color(0xFFE8EAF6), _buildVideoChatIcon(), textColor: Colors.black87),
          SizedBox(width: 20),
          _buildFeatureCard('AI Report\nGeneration', Color(0xFFE8EAF6), _buildReportIcon(), textColor: Colors.black87),
          SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildContinuousFastRow2() {
    final Size size = MediaQuery.of(context).size;
    double offset = -size.width * 1.5 * _fastAnimation.value;

    return Transform.translate(
      offset: Offset(offset, 0),
      child: Row(
        children: [
          // First set
          _buildFeatureCard('Mental\nBurnout', Color(0xFF6A1B9A), _buildBurnoutIcon()), // Purple color
          SizedBox(width: 20),
          _buildFeatureCard('Stress\nAnalysis', Color(0xFF6A1B9A), _buildStressIcon()), // Purple color
          SizedBox(width: 20),
          _buildFeatureCard('Therapy\nRecommendation', Color(0xFF2D2D2D), _buildTherapyIcon()),
          SizedBox(width: 20),

          // Second set
          _buildFeatureCard('Mental\nBurnout', Color(0xFF6A1B9A), _buildBurnoutIcon()), // Purple color
          SizedBox(width: 20),
          _buildFeatureCard('Stress\nAnalysis', Color(0xFF6A1B9A), _buildStressIcon()), // Purple color
          SizedBox(width: 20),
          _buildFeatureCard('Therapy\nRecommendation', Color(0xFF2D2D2D), _buildTherapyIcon()),
          SizedBox(width: 20),

          // Third set
          _buildFeatureCard('Mental\nBurnout', Color(0xFF6A1B9A), _buildBurnoutIcon()), // Purple color
          SizedBox(width: 20),
          _buildFeatureCard('Stress\nAnalysis', Color(0xFF6A1B9A), _buildStressIcon()), // Purple color
          SizedBox(width: 20),
          _buildFeatureCard('Therapy\nRecommendation', Color(0xFF2D2D2D), _buildTherapyIcon()),
          SizedBox(width: 20),

          // Fourth set
          _buildFeatureCard('Mental\nBurnout', Color(0xFF6A1B9A), _buildBurnoutIcon()), // Purple color
          SizedBox(width: 20),
          _buildFeatureCard('Stress\nAnalysis', Color(0xFF6A1B9A), _buildStressIcon()), // Purple color
          SizedBox(width: 20),
          _buildFeatureCard('Therapy\nRecommendation', Color(0xFF2D2D2D), _buildTherapyIcon()),
          SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, Color backgroundColor, Widget icon,
      {Color textColor = Colors.white}) {
    return Container(
      width: 110,
      height: 110,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: icon,
          ),
          SizedBox(height: 4),
          Expanded(
            flex: 1,
            child: Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // All icon methods remain the same...
  Widget _buildDepressionIcon() {
    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(50),
      ),
      child: Icon(
        Icons.sentiment_very_dissatisfied,
        color: Colors.lightBlue[200],
        size: 24,
      ),
    );
  }

  Widget _buildMoodIcon() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 18,
          height: 25,
          margin: EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: Colors.purple[300],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(Icons.person, color: Colors.white, size: 14),
        ),
        Container(
          width: 18,
          height: 25,
          decoration: BoxDecoration(
            color: Colors.purple[300],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(Icons.person, color: Colors.white, size: 14),
        ),
      ],
    );
  }

  Widget _buildAnxietyIcon() {
    return Container(
      child: Icon(
        Icons.psychology,
        color: Colors.white70,
        size: 30,
      ),
    );
  }

  Widget _buildVideoChatIcon() {
    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.video_call,
        color: Colors.blue[700],
        size: 28,
      ),
    );
  }

  Widget _buildReportIcon() {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assessment, color: Colors.orange[700], size: 24),
          SizedBox(height: 2),
          Text(
            'Deep Dive into Your\nSituation',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 7,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBurnoutIcon() {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_off, color: Colors.yellow[700], size: 24),
          Container(
            margin: EdgeInsets.only(top: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.flash_on, color: Colors.yellow, size: 10),
                Icon(Icons.flash_on, color: Colors.yellow, size: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStressIcon() {
    return Container(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.scatter_plot, color: Colors.orange, size: 28),
          Positioned(
            top: 3,
            right: 3,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.yellow,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTherapyIcon() {
    return Container(
      child: Icon(
        Icons.favorite_border,
        color: Colors.red[300],
        size: 30,
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'report_screen.dart'; // Add this import

class TestScreen extends StatefulWidget {
  final String userGender;
  final int userAge;

  const TestScreen({Key? key, required this.userGender, required this.userAge}) : super(key: key);
  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> with TickerProviderStateMixin {
  late String userGender;
  late int userAge;

  int currentSection = 0;
  int currentQuestionIndex = 0;
  Map<String, int> answers = {};

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Method channel for mental health prediction
  static const platform = MethodChannel('mental_health_prediction');

  final List<String> sectionTitles = [
    "Depression Assessment",
    "Anxiety Assessment",
    "Wellbeing Assessment",
    "Lifestyle & Social Functioning"
  ];

  final List<List<String>> questions = [
    [
      "How often have you had little interest or pleasure in doing things you usually enjoy?",
      "How often have you felt down, depressed, or hopeless?",
      "How often have you had trouble falling asleep, staying asleep, or slept too much?",
      "How often have you felt tired or had very little energy?",
      "How often have you experienced poor appetite or overeating?",
      "How often have you felt bad about yourself, or thought you were a failure?",
      "How often have you had trouble concentrating on school, work, or reading?",
      "How often have you moved or spoken noticeably slower than usual, or felt unusually restless?",
      "How often have you had thoughts that you would be better off dead, or of hurting yourself?",
    ],
    [
      "How often have you felt nervous, anxious, or on edge?",
      "How often have you found it difficult to stop or control worrying?",
      "How often have you worried excessively about different things?",
      "How often have you found it hard to relax?",
      "How often have you felt so restless that it was difficult to sit still?",
      "How often have you become easily annoyed or irritable?",
      ". How often have you felt afraid, as though something terrible might happen",
    ],
    [
      "How often have you felt cheerful and in good spirits?",
      "How often have you felt calm and relaxed?",
      "How often have you felt active and full of energy?",
      "How often have you woken up feeling fresh and well-rested?",
      "How often has your daily life felt filled with things that interest you?",
    ],
    [
      "How often have your emotional difficulties interfered with your performance at school or work?",
      "How often have your emotional difficulties affected your relationships with friends or family?",
      "How often have you felt socially isolated or withdrawn?",
      "How often have you felt that you could rely on your friends or family when you needed support?",
    ],
  ];

  final List<List<String>> optionLabels = [
    ["Never", "Rarely", "Sometimes", "Often", "Almost every day"],
    ["At no time", "Some of the time", "Less than half the time", "More than half the time", "Most of the time", "All the time"],
  ];

  @override
  void initState() {
    super.initState();
    userGender = widget.userGender;
    userAge = widget.userAge;
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String _getCurrentQuestionKey() {
    return "section_${currentSection}_question_${currentQuestionIndex}";
  }

  List<String> _getCurrentOptions() {
    return currentSection == 2 ? optionLabels[1] : optionLabels[0];
  }

  void _selectAnswer(int value) {
    setState(() {
      answers[_getCurrentQuestionKey()] = value;
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions[currentSection].length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
      _fadeController.reset();
      _fadeController.forward();
    } else if (currentSection < questions.length - 1) {
      setState(() {
        currentSection++;
        currentQuestionIndex = 0;
      });
      _fadeController.reset();
      _fadeController.forward();
    } else {
      _processResults();
    }
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
      });
      _fadeController.reset();
      _fadeController.forward();
    } else if (currentSection > 0) {
      setState(() {
        currentSection--;
        currentQuestionIndex = questions[currentSection].length - 1;
      });
      _fadeController.reset();
      _fadeController.forward();
    }
  }

  // Convert answers to the required format for the ML model
  List<int> _convertAnswersToModelFormat() {
    List<int> responses = List.filled(25, 0);

    int questionIndex = 0;
    for (int section = 0; section < questions.length; section++) {
      for (int question = 0; question < questions[section].length; question++) {
        String key = "section_${section}_question_${question}";
        if (answers.containsKey(key)) {
          responses[questionIndex] = answers[key]!;
        }
        questionIndex++;
      }
    }

    return responses;
  }

  // Process results using the ML model - MODIFIED TO NAVIGATE TO REPORT SCREEN
  Future<void> _processResults() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Color(0xFF2D2D2D),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF6A1B9A)),
              SizedBox(height: 20),
              Text(
                'Processing your responses...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      // Convert answers to model format
      List<int> userResponses = _convertAnswersToModelFormat();

      // Call the ML prediction
      final result = await platform.invokeMethod('predict', {
        'responses': userResponses
      });

      // Log the results to console
      print('=== USER INFO ===');
      print('Gender: $userGender');
      print('Age: $userAge');
      print('=== MENTAL HEALTH PREDICTION RESULTS ===');
      print('User Responses: $userResponses');
      print('Comprehensive Score: ${result['comprehensive_score']}/100');
      print('Depression Probability: ${result['depression_probability']}%');
      print('Anxiety Probability: ${result['anxiety_probability']}%');
      print('Depression Score: ${result['depression_score']}');
      print('Anxiety Score: ${result['anxiety_score']}');
      print('Wellbeing Score: ${result['wellbeing_score']}');
      print('Social Functioning Score: ${result['social_functioning_score']}');
      print('=====================================');

      // Close loading dialog
      Navigator.of(context).pop();

      // Navigate to Report Screen instead of showing dialog
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReportScreen(
            userGender: userGender,
            userAge: userAge,
            testResults: result,
            userResponses: userResponses,
          ),
        ),
      );

    } catch (e) {
      // Close loading dialog if open
      Navigator.of(context).pop();

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Color(0xFF2D2D2D),
          title: Text('Error', style: TextStyle(color: Colors.white)),
          content: Text('Failed to process results: $e', style: TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: TextStyle(color: Color(0xFF6A1B9A))),
            ),
          ],
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
            // Curved Header with Progress
            _buildCurvedHeader(),

            // Question Content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildQuestionContent(),
              ),
            ),

            // Next Button
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurvedHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          // Top Progress Lines
          Container(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            child: Row(
              children: List.generate(4, (index) {
                bool isActive = index <= currentSection;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    height: 3,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Header Content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                Text(
                  'HEALTH TEST',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  '${_getCurrentQuestionNumber()}/${_getTotalQuestions()}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildQuestionContent() {
    return Column(
      children: [
        SizedBox(height: 40),

        // Question Text
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 30),
          child: Text(
            questions[currentSection][currentQuestionIndex],
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        SizedBox(height: 50),

        // Answer Options
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 30),
            itemCount: _getCurrentOptions().length,
            itemBuilder: (context, index) {
              return _buildOptionTile(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOptionTile(int index) {
    List<String> options = _getCurrentOptions();
    String questionKey = _getCurrentQuestionKey();
    int? selectedValue = answers[questionKey];
    bool isSelected = selectedValue == index;

    return Container(
      margin: EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectAnswer(index),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: BoxDecoration(
              color: Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(8),
              border: isSelected ? Border.all(
                color: Color(0xFF6A1B9A),
                width: 2,
              ) : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    options[index],
                    style: TextStyle(
                      color: isSelected ? Color(0xFF6A1B9A) : Colors.white,
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check,
                    color: Color(0xFF6A1B9A),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    bool hasAnswer = answers.containsKey(_getCurrentQuestionKey());
    bool isLastQuestion = currentSection == questions.length - 1 &&
        currentQuestionIndex == questions[currentSection].length - 1;

    return Container(
      padding: EdgeInsets.all(30),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: hasAnswer ? Color(0xFF00BFA5) : Colors.grey.shade600,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: hasAnswer ? 8 : 2,
          ),
          onPressed: hasAnswer ? _nextQuestion : null,
          child: Text(
            isLastQuestion ? 'Finish Assessment' : 'Next',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  int _getCurrentQuestionNumber() {
    int totalPrevious = 0;
    for (int i = 0; i < currentSection; i++) {
      totalPrevious += questions[i].length;
    }
    return totalPrevious + currentQuestionIndex + 1;
  }

  int _getTotalQuestions() {
    return questions.fold(0, (sum, section) => sum + section.length);
  }
}
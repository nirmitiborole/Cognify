import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import '../pages/user_prefs.dart';

class ChatbotScreen extends StatefulWidget {
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String _userName = 'User';
  late AnimationController _typingController;
  late AnimationController _backgroundController;
  late AnimationController _messageAnimationController;
  late AnimationController _fabController;
  late Animation<double> _messageSlideAnimation;
  late Animation<double> _messageOpacityAnimation;

  final String _cohereApiKey = 'Xn841PmgOsh67A9l8Ns0BLjnnbxAsxZT8keXySpu';
  final String _cohereApiUrl = 'https://api.cohere.ai/v1/chat';

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _addInitialWelcomeMessage();

    // Initialize animation controllers
    _typingController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _messageAnimationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fabController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );

    _messageSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _messageAnimationController,
      curve: Curves.elasticOut,
    ));

    _messageOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _messageAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    _backgroundController.dispose();
    _messageAnimationController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    _userName = await UserPrefs.getUserName();
    if (mounted) setState(() {});
  }

  void _addInitialWelcomeMessage() {
    _messages.add(ChatMessage(
      text: "Hello! I'm your AI Therapy Assistant. I'm here to provide mental health support, coping strategies, and a safe space to talk. How are you feeling today?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    // Animate send button
    _fabController.forward().then((_) => _fabController.reverse());

    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _typingController.repeat();
    _scrollToBottom();

    try {
      final response = await _getCohereResponse(userMessage);

      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });

      _typingController.stop();
      _scrollToBottom();
    } catch (e) {
      print('Error getting Cohere response: $e');
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: "I apologize, I'm having trouble responding right now. Please try again in a moment. Remember, if you're experiencing a mental health emergency, please contact your local emergency services or a crisis hotline.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _typingController.stop();
    }
  }

  Future<String> _getCohereResponse(String userMessage) async {
    // Build conversation history for context
    List<Map<String, String>> chatHistory = [];

    // Add system message as first user message with preamble
    String systemPrompt = '''You are a professional, empathetic AI therapy assistant designed to provide mental health support. Your role is to:

1. Listen actively and respond with empathy and understanding
2. Provide evidence-based coping strategies and mental wellness techniques
3. Offer emotional support without diagnosing or replacing professional therapy
4. Suggest healthy lifestyle practices for mental well-being
5. Recognize crisis situations and recommend professional help when needed
6. Maintain appropriate boundaries while being supportive
7. Use a warm, non-judgmental, and encouraging tone

IMPORTANT GUIDELINES:
- Always remind users that you're an AI assistant, not a replacement for professional therapy
- If someone expresses suicidal thoughts or self-harm, immediately encourage them to seek professional help
- Keep responses concise but meaningful (2-4 sentences typically)
- Ask follow-up questions to encourage deeper reflection
- Validate emotions and experiences
- Suggest practical, actionable steps when appropriate

Remember: You're here to support, not diagnose or treat mental health conditions.''';

    // Get recent messages for context (last 10 messages)
    int startIndex = _messages.length > 10 ? _messages.length - 10 : 0;
    for (int i = startIndex; i < _messages.length; i++) {
      if (_messages[i].isUser) {
        chatHistory.add({
          'role': 'USER',
          'message': _messages[i].text,
        });
      } else {
        chatHistory.add({
          'role': 'CHATBOT',
          'message': _messages[i].text,
        });
      }
    }

    final response = await http.post(
      Uri.parse(_cohereApiUrl),
      headers: {
        'Authorization': 'Bearer $_cohereApiKey',
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: json.encode({
        'model': 'command-r-08-2024',
        'message': userMessage,
        'preamble': systemPrompt,
        'chat_history': chatHistory,
        'temperature': 0.7,
        'max_tokens': 500,
        'k': 0,
        'p': 0.75,
        'seed': null,
        'stop_sequences': [],
        'frequency_penalty': 0.0,
        'presence_penalty': 0.0,
      }),
    );

    print('Cohere API Response Status: ${response.statusCode}');
    print('Cohere API Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['text']?.toString().trim() ?? 'I apologize, but I couldn\'t generate a proper response. Please try again.';
    } else if (response.statusCode == 429) {
      throw Exception('Rate limit exceeded. Please wait a moment before trying again.');
    } else if (response.statusCode == 401) {
      throw Exception('API key is invalid or expired.');
    } else {
      final errorData = json.decode(response.body);
      throw Exception('Cohere API Error: ${errorData['message'] ?? 'Unknown error'}');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft + Alignment(_backgroundController.value * 2 - 1, 0),
                    end: Alignment.bottomRight + Alignment(_backgroundController.value * 2 - 1, 0),
                    colors: [
                      Color(0xFF0F0F0F),
                      Color(0xFF1A1A1A),
                      Color(0xFF2A1A3A),
                      Color(0xFF1A1A1A),
                      Color(0xFF0F0F0F),
                    ],
                    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                  ),
                ),
              );
            },
          ),

          // Floating particles effect
          ...List.generate(6, (index) =>
              AnimatedBuilder(
                animation: _backgroundController,
                builder: (context, child) {
                  return Positioned(
                    left: (MediaQuery.of(context).size.width * (index * 0.2)) +
                        (50 * math.sin(_backgroundController.value * 2 * math.pi + index)),
                    top: (MediaQuery.of(context).size.height * (index * 0.15)) +
                        (30 * math.cos(_backgroundController.value * 2 * math.pi + index)),
                    child: Container(
                      width: 4 + (index * 2).toDouble(),
                      height: 4 + (index * 2).toDouble(),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF6A1B9A).withOpacity(0.1 + (index * 0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF6A1B9A).withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ),

          Column(
            children: [
              // Enhanced AppBar - Fixed height and simplified
              Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF6A1B9A), // Dark purple as per your theme
                      Color(0xFF4A148C), // Even darker purple
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF6A1B9A).withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
                          ),
                        ),
                        SizedBox(width: 12),
                        // Simplified AI Avatar
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.psychology,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Therapy Assistant',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Powered by Cohere',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showInfoDialog(),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.info_outline, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Chat Messages with enhanced animations
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return _buildEnhancedTypingIndicator();
                      }
                      return _buildEnhancedMessageBubble(_messages[index], index);
                    },
                  ),
                ),
              ),

              // Enhanced Input Area
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0xFF1A1A1A).withOpacity(0.95),
                      Color(0xFF2A2A2A),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: Offset(0, -10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF3D3D3D),
                              Color(0xFF2A2A2A),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            width: 2,
                            color: Color(0xFF6A1B9A).withOpacity(0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF6A1B9A).withOpacity(0.1),
                              blurRadius: 15,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _messageController,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: 'Share what\'s on your mind...',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.chat_bubble_outline,
                                color: Color(0xFF6A1B9A).withOpacity(0.7),
                                size: 20,
                              ),
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    // Enhanced send button with animation
                    AnimatedBuilder(
                      animation: _fabController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_fabController.value * 0.1),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isTyping
                                    ? [Colors.grey[600]!, Colors.grey[700]!]
                                    : [Color(0xFF6A1B9A), Color(0xFF8E24AA), Color(0xFFAB47BC)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: _isTyping
                                      ? Colors.grey.withOpacity(0.3)
                                      : Color(0xFF6A1B9A).withOpacity(0.4),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(28),
                                onTap: _isTyping ? null : _sendMessage,
                                child: Center(
                                  child: AnimatedSwitcher(
                                    duration: Duration(milliseconds: 300),
                                    child: _isTyping
                                        ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                    )
                                        : Icon(
                                      Icons.send_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedMessageBubble(ChatMessage message, int index) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) _buildEnhancedAvatarIcon(),
          if (!message.isUser) SizedBox(width: 12),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: message.isUser
                    ? LinearGradient(
                  colors: [
                    Color(0xFF6A1B9A), // Your dark purple theme
                    Color(0xFF4A148C),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : LinearGradient(
                  colors: [
                    Color(0xFF2A2A2A),
                    Color(0xFF323232),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                  bottomLeft: message.isUser ? Radius.circular(25) : Radius.circular(8),
                  bottomRight: message.isUser ? Radius.circular(8) : Radius.circular(25),
                ),
                border: Border.all(
                  color: message.isUser
                      ? Colors.white.withOpacity(0.1)
                      : Color(0xFF6A1B9A).withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: message.isUser
                        ? Color(0xFF6A1B9A).withOpacity(0.3)
                        : Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 1,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.4,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          if (message.isUser) SizedBox(width: 12),
          if (message.isUser) _buildEnhancedUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildEnhancedAvatarIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF6A1B9A), // Your dark purple theme
            Color(0xFF4A148C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6A1B9A).withOpacity(0.4),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        Icons.psychology,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildEnhancedUserAvatar() {
    // Get first letter of username, fallback to 'U' if empty
    String firstLetter = _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U';

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2A2A2A), // Dark gray/black gradient
            Color(0xFF1A1A1A), // Even darker
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          firstLetter,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }


  Widget _buildEnhancedTypingIndicator() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildEnhancedAvatarIcon(),
          SizedBox(width: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF2A2A2A),
                  Color(0xFF323232),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
                bottomRight: Radius.circular(25),
                bottomLeft: Radius.circular(8),
              ),
              border: Border.all(
                color: Color(0xFF6A1B9A).withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 1,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _typingController,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildEnhancedTypingDot(0),
                    SizedBox(width: 6),
                    _buildEnhancedTypingDot(1),
                    SizedBox(width: 6),
                    _buildEnhancedTypingDot(2),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTypingDot(int index) {
    double delay = index * 0.2;
    return AnimatedBuilder(
      animation: _typingController,
      builder: (context, child) {
        double animationValue = (_typingController.value - delay).clamp(0.0, 1.0);
        double scale = 1.0 + (0.5 * math.sin(animationValue * 2 * math.pi));
        double opacity = (animationValue < 0.5) ? animationValue * 2 : (1.0 - animationValue) * 2;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Color(0xFF6A1B9A).withOpacity(opacity.clamp(0.3, 1.0)),
                  Color(0xFF8E24AA).withOpacity(opacity.clamp(0.3, 1.0)),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF6A1B9A).withOpacity(0.3),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2A2A2A),
                Color(0xFF1A1A1A),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color(0xFF6A1B9A).withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF6A1B9A).withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Therapy Assistant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'I\'m here to provide mental health support and coping strategies. While I can offer guidance and a listening ear, I\'m not a replacement for professional therapy.\n\nIf you\'re experiencing a mental health crisis, please contact:\n• Emergency services: 911\n• Crisis Text Line: Text HOME to 741741\n• National Suicide Prevention Lifeline: 988',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(
                        color: Color(0xFF6A1B9A),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    'Got it',
                    style: TextStyle(
                      color: Color(0xFF6A1B9A),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
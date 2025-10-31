import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyDoqEF3GuGGNaKLVLyvTic-2AJLsQdKXD0'; // Replace with your actual API key
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash', // UPDATED MODEL NAME
      apiKey: _apiKey,
    );
  }

  Future<String> generateScreeningObservation({
    required double comprehensiveScore,
    required double depressionProbability,
    required double anxietyProbability,
    required double stressLevel,
    required int depressionScore,
    required int anxietyScore,
    required int wellbeingScore,
    required int socialFunctioningScore,
    required List<int> userResponses,
  }) async {
    try {
      print('🔄 Starting Gemini API call for screening observation...');

      final prompt = '''
      As a compassionate AI wellness assistant, provide a personalized, empathetic observation about this individual's mental health assessment. Focus on their specific response patterns and provide supportive insights.

      *Individual Assessment Data:*
      - Overall Wellness Score: ${comprehensiveScore.toStringAsFixed(1)}/100
      - Depression Risk Probability: ${depressionProbability.toStringAsFixed(1)}%
      - Anxiety Risk Probability: ${anxietyProbability.toStringAsFixed(1)}%
      - Depression Score (PHQ-9): ${depressionScore}/27
      - Anxiety Score (GAD-7): ${anxietyScore}/21
      - Wellbeing Score (WHO-5): ${wellbeingScore}/25
      - Social Functioning Score: ${socialFunctioningScore}/16

      *Detailed Response Analysis:*
      Depression Questions (PHQ-9 - Scale 0-4):
      1. Interest/pleasure in activities: ${userResponses.length > 0 ? userResponses[0] : 0}
      2. Feeling down/depressed: ${userResponses.length > 1 ? userResponses[1] : 0}
      3. Sleep difficulties: ${userResponses.length > 2 ? userResponses[2] : 0}
      4. Fatigue/low energy: ${userResponses.length > 3 ? userResponses[3] : 0}
      5. Appetite changes: ${userResponses.length > 4 ? userResponses[4] : 0}
      6. Self-worth issues: ${userResponses.length > 5 ? userResponses[5] : 0}
      7. Concentration problems: ${userResponses.length > 6 ? userResponses[6] : 0}
      8. Psychomotor changes: ${userResponses.length > 7 ? userResponses[7] : 0}
      9. Thoughts of self-harm: ${userResponses.length > 8 ? userResponses[8] : 0}

      Anxiety Questions (GAD-7 - Scale 0-4):
      10. Nervousness/anxiety: ${userResponses.length > 9 ? userResponses[9] : 0}
      11. Uncontrollable worry: ${userResponses.length > 10 ? userResponses[10] : 0}
      12. Excessive worry: ${userResponses.length > 11 ? userResponses[11] : 0}
      13. Difficulty relaxing: ${userResponses.length > 12 ? userResponses[12] : 0}
      14. Restlessness: ${userResponses.length > 13 ? userResponses[13] : 0}
      15. Irritability: ${userResponses.length > 14 ? userResponses[14] : 0}
      16. Fear of terrible events: ${userResponses.length > 15 ? userResponses[15] : 0}

      Wellbeing Questions (WHO-5 - Scale 0-5):
      17. Cheerful mood: ${userResponses.length > 16 ? userResponses[16] : 0}
      18. Calm and relaxed: ${userResponses.length > 17 ? userResponses[17] : 0}
      19. Active and energetic: ${userResponses.length > 18 ? userResponses[18] : 0}
      20. Fresh and rested: ${userResponses.length > 19 ? userResponses[19] : 0}
      21. Life filled with interest: ${userResponses.length > 20 ? userResponses[20] : 0}

      Social Functioning Questions (Scale 0-4):
      22. Work/school interference: ${userResponses.length > 21 ? userResponses[21] : 0}
      23. Relationship impact: ${userResponses.length > 22 ? userResponses[22] : 0}
      24. Social isolation: ${userResponses.length > 23 ? userResponses[23] : 0}
      25. Support availability: ${userResponses.length > 24 ? userResponses[24] : 0}

      *Instructions:*
      - Write a personalized, compassionate observation in 4-5 sentences
      - Focus on their specific high-scoring areas and patterns
      - Mention both challenges and strengths you identify
      - Use supportive, non-clinical language
      - Avoid generic statements - be specific to their responses
      - If scores are concerning, acknowledge their courage in taking the assessment
      ''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final observationText = response.text ?? '';

      print('✅ Gemini observation response received: ${observationText.length} characters');

      if (observationText.isNotEmpty) {
        return observationText;
      } else {
        return _getDefaultObservation(comprehensiveScore, depressionProbability, anxietyProbability);
      }

    } catch (e) {
      print('❌ Gemini API Error (Observation): $e');
      print('❌ Error type: ${e.runtimeType}');
      return _getDefaultObservation(comprehensiveScore, depressionProbability, anxietyProbability);
    }
  }

  Future<String> generateSuggestedActions({
    required double comprehensiveScore,
    required double depressionProbability,
    required double anxietyProbability,
    required double stressLevel,
    required String mentalHealthStatus,
    required String riskFactor,
    required List<int> userResponses,
  }) async {
    try {
      print('🔄 Starting Gemini API call for suggested actions...');

      final prompt = '''
      Based on this individual's specific mental health assessment results, provide personalized, actionable wellness recommendations. Focus on practical steps they can implement immediately and longer-term strategies.

      *Assessment Summary:*
      - Overall Wellness Score: ${comprehensiveScore.toStringAsFixed(1)}/100
      - Depression Risk: ${depressionProbability.toStringAsFixed(1)}%
      - Anxiety Risk: ${anxietyProbability.toStringAsFixed(1)}%
      - Mental Health Status: ${mentalHealthStatus}
      - Risk Level: ${riskFactor}

      *Key Problem Areas (High Scores - 2+ on 0-4 scale):*
      ${_identifyProblemAreas(userResponses)}

      *Strength Areas (Wellbeing - High Scores 4+ on 0-5 scale):*
      ${_identifyStrengthAreas(userResponses)}

      *Instructions:*
      - Provide 5-6 specific, actionable suggestions formatted as bullet points
      - Address their highest-scoring problem areas first
      - Include both immediate actions (this week) and longer-term strategies (next month)
      - Be practical and realistic - avoid overwhelming recommendations
      - Include specific techniques, not just general advice
      - If depression scores are high (2+), focus on behavioral activation and routine
      - If anxiety scores are high (2+), include grounding and relaxation techniques
      - If wellbeing scores are low (0-2), suggest mood-boosting activities
      - If social functioning is impacted, recommend connection strategies
      - End with encouragement about seeking professional help if needed
      ''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final actionsText = response.text ?? '';

      print('✅ Gemini actions response received: ${actionsText.length} characters');

      if (actionsText.isNotEmpty) {
        return actionsText;
      } else {
        return _getDefaultSuggestions(comprehensiveScore, depressionProbability, anxietyProbability);
      }

    } catch (e) {
      print('❌ Gemini API Error (Actions): $e');
      print('❌ Error type: ${e.runtimeType}');
      return _getDefaultSuggestions(comprehensiveScore, depressionProbability, anxietyProbability);
    }
  }

  // Helper method to identify problem areas from responses
  String _identifyProblemAreas(List<int> responses) {
    List<String> problems = [];

    // Check depression indicators (0-8)
    if (responses.length > 2 && responses[2] >= 2) problems.add("Sleep difficulties");
    if (responses.length > 3 && responses[3] >= 2) problems.add("Fatigue/low energy");
    if (responses.length > 1 && responses[1] >= 2) problems.add("Depressed mood");
    if (responses.length > 0 && responses[0] >= 2) problems.add("Loss of interest");
    if (responses.length > 6 && responses[6] >= 2) problems.add("Concentration problems");
    if (responses.length > 5 && responses[5] >= 2) problems.add("Self-worth issues");

    // Check anxiety indicators (9-15)
    if (responses.length > 9 && responses[9] >= 2) problems.add("Nervousness/anxiety");
    if (responses.length > 10 && responses[10] >= 2) problems.add("Uncontrollable worry");
    if (responses.length > 12 && responses[12] >= 2) problems.add("Difficulty relaxing");
    if (responses.length > 13 && responses[13] >= 2) problems.add("Restlessness");

    // Check social functioning (21-24)
    if (responses.length > 21 && responses[21] >= 2) problems.add("Work/school interference");
    if (responses.length > 22 && responses[22] >= 2) problems.add("Relationship difficulties");
    if (responses.length > 23 && responses[23] >= 2) problems.add("Social isolation");

    return problems.isEmpty ? "No significant problem areas identified" : problems.join(", ");
  }

  // Helper method to identify strength areas from responses
  String _identifyStrengthAreas(List<int> responses) {
    List<String> strengths = [];

    // Check wellbeing indicators (16-20) - high scores are good
    if (responses.length > 16 && responses[16] >= 4) strengths.add("Cheerful mood");
    if (responses.length > 17 && responses[17] >= 4) strengths.add("Feeling calm");
    if (responses.length > 18 && responses[18] >= 4) strengths.add("Energy levels");
    if (responses.length > 19 && responses[19] >= 4) strengths.add("Sleep quality");
    if (responses.length > 20 && responses[20] >= 4) strengths.add("Life engagement");

    // Check social support (response 24 - low score is good)
    if (responses.length > 24 && responses[24] <= 1) strengths.add("Strong support system");

    return strengths.isEmpty ? "Areas for strength building identified" : strengths.join(", ");
  }

  // Default observation when Gemini fails
  String _getDefaultObservation(double score, double depression, double anxiety) {
    if (score >= 70) {
      return "Your assessment shows several positive indicators in your mental wellness journey. While there are some areas that could benefit from attention, you demonstrate resilience and self-awareness by taking this assessment. Your responses suggest you have foundational strengths to build upon as you continue focusing on your mental health.";
    } else if (score >= 40) {
      return "Your assessment reveals a mixed pattern of mental wellness indicators, with both challenges and areas of strength. The specific combination of your responses suggests you're experiencing some difficulties that are worth addressing, while also showing signs of coping and awareness. This assessment is a valuable first step in understanding your current mental health landscape.";
    } else {
      return "Your assessment indicates you're currently experiencing significant challenges in several areas of mental wellness. The patterns in your responses suggest you may be dealing with symptoms that are impacting your daily life and overall well-being. Taking this assessment shows courage and self-awareness - important first steps toward getting the support you deserve.";
    }
  }

  // Default suggestions when Gemini fails
  String _getDefaultSuggestions(double score, double depression, double anxiety) {
    List<String> suggestions = [];

    if (depression > 50) {
      suggestions.add("• Establish a daily routine with regular sleep and wake times to help stabilize your mood");
      suggestions.add("• Engage in at least one small pleasant activity each day, even when motivation is low");
    }

    if (anxiety > 50) {
      suggestions.add("• Practice deep breathing exercises or progressive muscle relaxation for 10 minutes daily");
      suggestions.add("• Try the 5-4-3-2-1 grounding technique when feeling overwhelmed (5 things you see, 4 you hear, etc.)");
    }

    suggestions.add("• Maintain connections with supportive friends or family members, even if it's just a quick check-in");
    suggestions.add("• Consider keeping a mood journal to track patterns and triggers in your mental wellness");
    suggestions.add("• Consult with a mental health professional for personalized guidance and support");

    return suggestions.join("\n");
  }
}
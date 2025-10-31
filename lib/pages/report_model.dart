import 'dart:ui';

class MentalHealthReport {
  final String reportId;
  final String userName;
  final String userGender;
  final int userAge;
  final DateTime reportDate;
  final double comprehensiveScore;
  final double depressionProbability;
  final double anxietyProbability;
  final double stressLevel;
  final int depressionScore;
  final int anxietyScore;
  final int wellbeingScore;
  final int socialFunctioningScore;
  final String mentalHealthStatus;
  final String riskFactor;
  final String screeningObservation;
  final String suggestedActions;
  final List<int> userResponses; // Added for personalized analysis

  MentalHealthReport({
    required this.reportId,
    required this.userName,
    required this.userGender,
    required this.userAge,
    required this.reportDate,
    required this.comprehensiveScore,
    required this.depressionProbability,
    required this.anxietyProbability,
    required this.stressLevel,
    required this.depressionScore,
    required this.anxietyScore,
    required this.wellbeingScore,
    required this.socialFunctioningScore,
    required this.mentalHealthStatus,
    required this.riskFactor,
    required this.screeningObservation,
    required this.suggestedActions,
    required this.userResponses,
  });

  // Helper methods for color coding
  Color getWellnessColor() {
    if (comprehensiveScore >= 80) return Color(0xFF4CAF50); // Green
    if (comprehensiveScore >= 60) return Color(0xFF8BC34A); // Light Green
    if (comprehensiveScore >= 40) return Color(0xFFFFC107); // Yellow
    if (comprehensiveScore >= 20) return Color(0xFFFF9800); // Orange
    return Color(0xFFF44336); // Red
  }

  String getWellnessRange() {
    if (comprehensiveScore >= 80) return "80-100";
    if (comprehensiveScore >= 60) return "60-79";
    if (comprehensiveScore >= 40) return "40-59";
    if (comprehensiveScore >= 20) return "20-39";
    return "0-19";
  }

  // Mental Health Status categorization
  String getMentalHealthStatusText() {
    if (comprehensiveScore >= 80) return "Flourishing";
    if (comprehensiveScore >= 60) return "Stable";
    if (comprehensiveScore >= 40) return "Concerning";
    if (comprehensiveScore >= 20) return "Vulnerable";
    return "Critical";
  }

  Color getMentalHealthStatusColor() {
    if (comprehensiveScore >= 80) return Color(0xFF4CAF50); // Green
    if (comprehensiveScore >= 60) return Color(0xFF8BC34A); // Light Green
    if (comprehensiveScore >= 40) return Color(0xFFFFC107); // Yellow
    if (comprehensiveScore >= 20) return Color(0xFFFF9800); // Orange
    return Color(0xFFF44336); // Red
  }

  // Risk Factor categorization
  String getRiskFactorText() {
    //double maxRisk = [depressionProbability, anxietyProbability].reduce((a, b) => a > b ? a : b);
    double riskScore = comprehensiveScore; // Invert so higher score = lower risk

    if (riskScore >= 80) return "Negligible";
    if (riskScore >= 60) return "Low";
    if (riskScore >= 40) return "Moderate";
    if (riskScore >= 20) return "High";
    return "Severe";
  }

  Color getRiskFactorColor() {
    //double maxRisk = [depressionProbability, anxietyProbability].reduce((a, b) => a > b ? a : b);
    double riskScore = comprehensiveScore; // Invert so higher score = lower risk

    if (riskScore >= 80) return Color(0xFF4CAF50); // Green
    if (riskScore >= 60) return Color(0xFF8BC34A); // Light Green
    if (riskScore >= 40) return Color(0xFFFFC107); // Yellow
    if (riskScore >= 20) return Color(0xFFFF9800); // Orange
    return Color(0xFFF44336); // Red
  }

  // Gender symbol color
  Color getGenderColor() {
    switch (userGender.toLowerCase()) {
      case 'male':
        return Color(0xFF2196F3); // Blue
      case 'female':
        return Color(0xFFE91E63); // Pink
      default:
        return Color(0xFF9E9E9E); // Grey
    }
  }
}
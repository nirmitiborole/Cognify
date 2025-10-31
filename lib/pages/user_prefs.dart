import 'package:shared_preferences/shared_preferences.dart';

class UserPrefs {
  static const String _nameKey = 'user_name';
  static const String _emailKey = 'user_email';
  static const String _genderKey = 'user_gender';
  static const String _ageKey = 'user_age';
  static const String _addressKey = 'user_address';

  // Store user data after login
  static Future<void> storeUserData(String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    await prefs.setString(_emailKey, email);
    print('User data stored: Name=$name, Email=$email');
  }

  // Store complete user profile (login + demographics)
  static Future<void> storeCompleteUserData({
    required String name,
    required String email,
    String? gender,
    int? age,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    await prefs.setString(_emailKey, email);

    if (gender != null) {
      await prefs.setString(_genderKey, gender);
    }
    if (age != null) {
      await prefs.setInt(_ageKey, age);
    }

    print('Complete user data stored: Name=$name, Email=$email, Gender=$gender, Age=$age');
  }

  // Get user name
  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey) ?? 'User';
  }

  // Get user email
  static Future<String> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey) ?? '';
  }

  // Get user gender
  static Future<String> getUserGender() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_genderKey) ?? '';
  }

  // Get user age
  static Future<int> getUserAge() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_ageKey) ?? 0;
  }

  // Set user gender
  static Future<void> setUserGender(String gender) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_genderKey, gender);
    print('User gender updated: $gender');
  }

  // Set user age
  static Future<void> setUserAge(int age) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_ageKey, age);
    print('User age updated: $age');
  }

  // Update user name
  static Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    print('User name updated: $name');
  }

  // Update user email
  static Future<void> setUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
    print('User email updated: $email');
  }

  // Check if user data exists (basic login data)
  static Future<bool> hasUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_nameKey) && prefs.containsKey(_emailKey);
  }

  // Check if demographic data exists
  static Future<bool> hasDemographicData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_genderKey) && prefs.containsKey(_ageKey);
  }

  // Check if complete profile exists
  static Future<bool> hasCompleteProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_nameKey) &&
        prefs.containsKey(_emailKey) &&
        prefs.containsKey(_genderKey) &&
        prefs.containsKey(_ageKey);
  }

  // Get all user data at once
  static Future<Map<String, dynamic>> getAllUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_nameKey) ?? 'User',
      'email': prefs.getString(_emailKey) ?? '',
      'gender': prefs.getString(_genderKey) ?? '',
      'age': prefs.getInt(_ageKey) ?? 0,
      'address': prefs.getString(_addressKey) ?? '',
    };
  }

  // Clear all user data on logout
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_genderKey);
    await prefs.remove(_ageKey);
    await prefs.remove(_addressKey);
    print('All user data cleared from SharedPreferences');
  }

  // Clear only demographic data (keep login info)
  static Future<void> clearDemographicData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_genderKey);
    await prefs.remove(_ageKey);
    print('Demographic data cleared from SharedPreferences');
  }

  // Utility method to check if age is valid for assessments
  static Future<bool> isAgeValidForAssessment() async {
    final age = await getUserAge();
    return age >= 13 && age <= 100;
  }

  // Utility method to get formatted user info for display
  static Future<String> getFormattedUserInfo() async {
    final userData = await getAllUserData();
    final name = userData['name'] as String;
    final age = userData['age'] as int;
    final gender = userData['gender'] as String;

    if (age > 0 && gender.isNotEmpty) {
      return '$name, $age years old, $gender';
    } else if (age > 0) {
      return '$name, $age years old';
    } else {
      return name;
    }
  }

  // Get user address
  static Future<String> getUserAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_addressKey) ?? '';
  }

  // Set user address
  static Future<void> setUserAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_addressKey, address);
    print('User address updated: $address');
  }



  // Debug method to print all stored data
  static Future<void> debugPrintAllData() async {
    final userData = await getAllUserData();
    print('=== User Preferences Debug ===');
    print('Name: ${userData['name']}');
    print('Email: ${userData['email']}');
    print('Gender: ${userData['gender']}');
    print('Age: ${userData['age']}');
    print('Address: ${userData['address']}'); // Add this line
    print('Has Complete Profile: ${await hasCompleteProfile()}');
    print('Age Valid for Assessment: ${await isAgeValidForAssessment()}');
    print('=============================');
  }
}

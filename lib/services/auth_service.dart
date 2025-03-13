import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String TOKEN_KEY = 'auth_token';
  static const String USER_ID_KEY = 'user_id';

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(TOKEN_KEY);
      
      if (token == null) return false;
      
      // Validate token with backend
      return await _validateToken(token);
    } catch (e) {
      print('Auth check error: $e');
      return false;
    }
  }

  // Validate token with backend
  Future<bool> _validateToken(String token) async {
    try {
      // TODO: Replace with actual API call to validate token
      await Future.delayed(Duration(milliseconds: 500));
      return token.isNotEmpty;
    } catch (e) {
      print('Token validation error: $e');
      return false;
    }
  }

  // Store authentication data
  Future<void> saveAuthData(String token, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(TOKEN_KEY, token);
    await prefs.setString(USER_ID_KEY, userId);
  }

  // Clear authentication data
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(TOKEN_KEY);
    await prefs.remove(USER_ID_KEY);
  }
}
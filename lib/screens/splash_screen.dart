import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Add minimum splash screen duration
      final splashDuration = Future.delayed(const Duration(seconds: 2));
      
      // Check authentication in parallel
      final isLoggedIn = await _authService.isAuthenticated();
      
      // Wait for minimum duration to complete
      await splashDuration;

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          isLoggedIn ? AppRoutes.dashboard : AppRoutes.login,
        );
      }
    } catch (e) {
      print('Auth check error: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6C5CE7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_sharp,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 16),
            Text(
              'Trading Bot',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    
    // Main animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Pulse animation controller (added as a separate controller)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    // Fade-in animation
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    
    // Scale animation
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    
    // Rotation animation for the analytics icon
    _rotateAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi * 0.25).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.5, curve: Curves.easeOut),
      ),
    );
    
    // Start the animation
    _animationController.forward();
    
    // Start the authentication check
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose(); // Dispose the pulse controller too
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Add minimum splash screen duration
      final splashDuration = Future.delayed(const Duration(milliseconds: 2200));
      
      // Check authentication in parallel
      final isLoggedIn = await _authService.isAuthenticated();
      
      // Wait for minimum duration to complete
      await splashDuration;

      if (mounted) {
        // Prepare exit animation
        _animationController.reverse().then((_) {
          Navigator.pushReplacementNamed(
            context,
            isLoggedIn ? AppRoutes.dashboard : AppRoutes.login,
          );
        });
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
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: const Color(0xFF4A55A2),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4A55A2),
              Color(0xFF3D4785),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeInAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo container with depth effect
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Transform.rotate(
                            angle: _rotateAnimation.value,
                            child: Icon(
                              Icons.analytics_sharp,
                              size: screenSize.width * 0.18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // App name with enhanced typography
                        Text(
                          'Trading Bot',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenSize.width * 0.068,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            shadows: const [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Tagline
                        Text(
                          'Smart Trading, Simplified',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: screenSize.width * 0.035,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Custom loading indicator
                        SizedBox(
                          width: screenSize.width * 0.18,
                          height: screenSize.width * 0.18,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer progress ring
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 3,
                              ),
                              // Inner dot pulse using a separate AnimatedBuilder
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Container(
                                    width: 12 + (4 * math.sin(_pulseController.value * 2 * math.pi)),
                                    height: 12 + (4 * math.sin(_pulseController.value * 2 * math.pi)),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
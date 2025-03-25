import 'package:flutter/material.dart';
import 'package:trading_bot/screens/auth/login_screen.dart';
import 'package:trading_bot/screens/dashboard/dashboard_screen.dart';
import 'package:trading_bot/screens/splash_screen.dart';
import 'package:trading_bot/screens/prediction_analysis_screen.dart'; // Import the screen

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String predictionAnalysis = '/prediction-analysis'; // Add this route

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) =>  SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) =>  LoginScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case predictionAnalysis: // Add this case
        return MaterialPageRoute(builder: (_) => const PredictionAnalysisScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
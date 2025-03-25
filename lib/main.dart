import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trading_bot/providers/stock_prediction_provider.dart'; // Import the provider
import 'routes/app_routes.dart';
import 'constants/colors.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StockPredictionProvider()), // Provide the provider
      ],
      child: MaterialApp(
        title: 'Trading Bot',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Poppins',
        ),
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
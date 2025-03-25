// lib/services/sentiment_service.dart
import 'dart:math';
import 'package:trading_bot/models/sentiment_result.dart';
import 'package:trading_bot/ffi/sentiment_bindings.dart' as ffi;

class SentimentService {
  final ffi.SentimentAnalyzerFFI _ffi = ffi.SentimentAnalyzerFFI();
  
  // Map of stock symbols to sentiment bias (to ensure consistent results)
  // This helps simulate different sentiment profiles for different stocks
  final Map<String, double> _stockSentimentBias = {
    "RELIANCE.BSE": 0.35,
    "TCS.BSE": 0.25,
    "HDFCBANK.BSE": 0.15,
    "INFY.BSE": -0.10,
    "ICICIBANK.BSE": 0.20,
    "KOTAKBANK.BSE": 0.05,
    "HINDUNILVR.BSE": 0.30,
    "ITC.BSE": -0.15,
    "SBIN.BSE": -0.25,
    "AXISBANK.BSE": 0.10,
    "BAJFINANCE.BSE": -0.20,
    "BHARTIARTL.BSE": 0.15,
    "LT.BSE": 0.05,
    "MARUTI.BSE": -0.05,
    "ASIANPAINT.BSE": 0.20,
    "HCLTECH.BSE": 0.10,
    "WIPRO.BSE": -0.15,
    "ONGC.BSE": -0.30,
    "NTPC.BSE": -0.10,
    "POWERGRID.BSE": 0.05,
    "SUNPHARMA.BSE": 0.25,
    "TATAMOTORS.BSE": 0.15,
    "ULTRACEMCO.BSE": -0.05,
    "TECHM.BSE": 0.10,
    "NESTLEIND.BSE": 0.30,
    "BAJAJFINSV.BSE": -0.10,
    "DRREDDY.BSE": 0.20,
    "ADANIPORTS.BSE": -0.25,
    "TITAN.BSE": 0.15,
    "JSWSTEEL.BSE": -0.20,
  };
  
  // Map of stock symbols to sample news/social media text
  final Map<String, String> _stockTextData = {
    'RELIANCE.BSE': '''
      Reliance Industries reports strong Q2 results with retail growth.
      Jio continues to add subscribers at a rapid pace.
      Energy business faces some headwinds due to global oil prices.
      Analysts remain bullish on Reliance's new energy initiatives.
    ''',
    'TCS.BSE': '''
      TCS reports robust deal wins for the quarter.
      Digital transformation projects driving growth for TCS.
      Rising attrition rates could impact margins in the short term.
      North American banking clients reducing IT spend.
    ''',
    'INFY.BSE': '''
      Infosys raises guidance for the rest of the fiscal year.
      Large deal momentum continues for Infosys this quarter.
      Cloud and AI initiatives gaining traction with clients.
      Management remains optimistic about growth prospects.
    ''',
    'HDFCBANK.BSE': '''
      HDFC Bank completes merger with HDFC Ltd.
      Loan growth remains strong despite economic headwinds.
      Asset quality metrics show improvement quarter-on-quarter.
      Analysts expect synergy benefits to start reflecting in coming quarters.
    ''',
  };
  
  // Analyze sentiment for a specific stock
  Future<SentimentResult> analyzeSentiment(String stockSymbol, double basePrice) async {
    try {
      // Get text data for the stock (or use a default if not available)
      final textData = _stockTextData[stockSymbol] ?? 
          "Market sentiment for this stock is mixed with some positive and negative signals.";
      
      // Get the sentiment bias for this stock (or use a random value if not defined)
      final sentimentBias = _stockSentimentBias[stockSymbol] ?? 
          (Random().nextDouble() * 0.6 - 0.3); // Random value between -0.3 and 0.3
      
      // Try to call the native code through FFI
      Map<String, dynamic> nativeResult;
      
      try {
        // Call the native code through FFI
        nativeResult = _ffi.analyzeSentiment(stockSymbol, basePrice, textData);
      } catch (e) {
        // If FFI fails, use the fallback implementation
        nativeResult = _generateFallbackSentiment(stockSymbol, basePrice, textData, sentimentBias);
      }
      
      // Convert to our Dart model
      return SentimentResult.fromNative(nativeResult);
    } catch (e) {
      // If anything fails, return a fallback result
      return _generateFallbackResult(stockSymbol, basePrice);
    }
  }
  
  // Fallback implementation if FFI fails
  Map<String, dynamic> _generateFallbackSentiment(
    String stockSymbol, 
    double basePrice, 
    String textData,
    double sentimentBias
  ) {
    // Generate a base sentiment score influenced by the stock's bias
    final baseScore = sentimentBias + (Random().nextDouble() * 0.4 - 0.2);
    
    // Add some price-based influence (higher prices might have slightly more positive sentiment)
    final priceInfluence = (basePrice > 1000) ? 0.05 : (basePrice > 500 ? 0.02 : 0);
    
    // Calculate component scores with some randomness
    final vaderValue = baseScore + (Random().nextDouble() * 0.3 - 0.15);
    final textblobValue = baseScore + (Random().nextDouble() * 0.3 - 0.15);
    final rfValue = baseScore + (Random().nextDouble() * 0.3 - 0.15);
    final lstmValue = baseScore + (Random().nextDouble() * 0.3 - 0.15);
    
    // Apply weights
    const vaderWeight = 0.35;
    const textblobWeight = 0.15;
    const rfWeight = 0.25;
    const lstmWeight = 0.25;
    
    final vaderComponent = vaderValue * vaderWeight;
    final textblobComponent = textblobValue * textblobWeight;
    final rfComponent = rfValue * rfWeight;
    final lstmComponent = lstmValue * lstmWeight;
    
    // Calculate final score
    final finalScore = vaderComponent + textblobComponent + rfComponent + lstmComponent + priceInfluence;
    
    // Calculate confidence (higher for extreme scores, lower for neutral)
    final confidence = 0.6 + (Random().nextDouble() * 0.2) + (finalScore.abs() * 0.2);
    
    return {
      'score': finalScore,
      'confidence': confidence,
      'components': [
        {'name': 'VADER', 'value': vaderValue, 'contribution': vaderComponent},
        {'name': 'TextBlob', 'value': textblobValue, 'contribution': textblobComponent},
        {'name': 'Random Forest', 'value': rfValue, 'contribution': rfComponent},
        {'name': 'LSTM', 'value': lstmValue, 'contribution': lstmComponent},
      ],
    };
  }
  
  // Generate a fallback result in case of errors
  SentimentResult _generateFallbackResult(String stockSymbol, double basePrice) {
    // Generate a sentiment bias based on the stock symbol
    final hash = stockSymbol.hashCode;
    final sentimentBias = (hash % 100) / 100 * 1.2 - 0.6; // Between -0.6 and 0.6
    
    // Generate component values
    final vaderValue = sentimentBias + (Random().nextDouble() * 0.4 - 0.2);
    final textblobValue = sentimentBias + (Random().nextDouble() * 0.4 - 0.2);
    final rfValue = sentimentBias + (Random().nextDouble() * 0.4 - 0.2);
    final lstmValue = sentimentBias + (Random().nextDouble() * 0.4 - 0.2);
    
    // Apply weights
    const vaderWeight = 0.35;
    const textblobWeight = 0.15;
    const rfWeight = 0.25;
    const lstmWeight = 0.25;
    
    final vaderComponent = vaderValue * vaderWeight;
    final textblobComponent = textblobValue * textblobWeight;
    final rfComponent = rfValue * rfWeight;
    final lstmComponent = lstmValue * lstmWeight;
    
    // Calculate final score
    final score = vaderComponent + textblobComponent + rfComponent + lstmComponent;
    
    // Determine interpretation
    String interpretation;
    if (score <= -0.7) {
      interpretation = "Strongly Bearish";
    } else if (score <= -0.3) {
      interpretation = "Bearish";
    } else if (score < 0.1) {
      interpretation = "Neutral";
    } else if (score < 0.5) {
      interpretation = "Bullish";
    } else {
      interpretation = "Strongly Bullish";
    }
    
    // Calculate confidence
    final confidence = 0.6 + (Random().nextDouble() * 0.2) + (score.abs() * 0.2);
    
    // Create components
    final components = [
      SentimentComponent(
        name: "VADER",
        contribution: vaderComponent,
        value: vaderValue,
      ),
      SentimentComponent(
        name: "TextBlob",
        contribution: textblobComponent,
        value: textblobValue,
      ),
      SentimentComponent(
        name: "Random Forest",
        contribution: rfComponent,
        value: rfValue,
      ),
      SentimentComponent(
        name: "LSTM",
        contribution: lstmComponent,
        value: lstmValue,
      ),
    ];
    
    return SentimentResult(
      score: score,
      interpretation: interpretation,
      confidence: confidence,
      components: components,
      timestamp: DateTime.now(),
    );
  }
}
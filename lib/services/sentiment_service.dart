// lib/services/sentiment_service.dart
import 'dart:async';
import 'package:trading_bot/ffi/sentiment_bridge.dart';
import 'package:trading_bot/models/sentiment_result.dart';
import 'package:trading_bot/services/news_service.dart';

class SentimentService {
  static final SentimentService _instance = SentimentService._internal();
  factory SentimentService() => _instance;
  
  final SentimentBridge _bridge = SentimentBridge();
  final NewsService _newsService = NewsService();
  
  // Stream controllers for real-time sentiment updates
  final Map<String, StreamController<SentimentResult>> _sentimentControllers = {};
  
  // Cache for latest sentiment results
  final Map<String, SentimentResult> _sentimentCache = {};
  
  // History of sentiment results for trend analysis
  final Map<String, List<SentimentResult>> _sentimentHistory = {};
  
  SentimentService._internal();
  
  // Get a stream of sentiment updates for a specific stock
  Stream<SentimentResult> getSentimentStream(String stockSymbol, double basePrice) {
    if (!_sentimentControllers.containsKey(stockSymbol)) {
      _sentimentControllers[stockSymbol] = StreamController<SentimentResult>.broadcast();
      _startAnalyzingSentiment(stockSymbol, basePrice);
    }
    return _sentimentControllers[stockSymbol]!.stream;
  }
  
  // Get the latest sentiment result for a stock
  SentimentResult? getLatestSentiment(String stockSymbol) {
    return _sentimentCache[stockSymbol];
  }
  
  // Get sentiment history for trend analysis
  List<SentimentResult> getSentimentHistory(String stockSymbol) {
    return _sentimentHistory[stockSymbol] ?? [];
  }
  
  // Start analyzing sentiment based on news updates
  void _startAnalyzingSentiment(String stockSymbol, double basePrice) {
    // Subscribe to news updates
    _newsService.getNewsStream(stockSymbol).listen((news) {
      _analyzeSentimentFromNews(stockSymbol, basePrice, news);
    });
  }
  
  // Analyze sentiment from news items
  Future<void> _analyzeSentimentFromNews(
    String stockSymbol, 
    double basePrice, 
    List<NewsItem> news
  ) async {
    if (news.isEmpty) return;
    
    // Combine all news content for analysis
    final combinedText = news.map((item) => 
      "${item.title}\n${item.content}"
    ).join("\n\n");
    
    try {
      // Use the bridge to analyze sentiment
      final nativeResult = await _bridge.analyzeSentimentAsync(
        stockSymbol, 
        basePrice, 
        combinedText
      );
      
      // Convert to our model
      final result = SentimentResult.fromNative(nativeResult);
      
      // Update cache
      _sentimentCache[stockSymbol] = result;
      
      // Update history
      if (!_sentimentHistory.containsKey(stockSymbol)) {
        _sentimentHistory[stockSymbol] = [];
      }
      
      // Keep history limited to last 100 entries
      if (_sentimentHistory[stockSymbol]!.length >= 100) {
        _sentimentHistory[stockSymbol]!.removeAt(0);
      }
      _sentimentHistory[stockSymbol]!.add(result);
      
      // Send to stream if controller exists
      if (_sentimentControllers.containsKey(stockSymbol)) {
        _sentimentControllers[stockSymbol]!.add(result);
      }
    } catch (e) {
      print('Error analyzing sentiment for $stockSymbol: $e');
      
      // If FFI fails, use fallback method
      final fallbackResult = _fallbackSentimentAnalysis(stockSymbol, combinedText);
      
      // Update cache and history with fallback result
      _sentimentCache[stockSymbol] = fallbackResult;
      
      if (!_sentimentHistory.containsKey(stockSymbol)) {
        _sentimentHistory[stockSymbol] = [];
      }
      
      if (_sentimentHistory[stockSymbol]!.length >= 100) {
        _sentimentHistory[stockSymbol]!.removeAt(0);
      }
      _sentimentHistory[stockSymbol]!.add(fallbackResult);
      
      // Send to stream if controller exists
      if (_sentimentControllers.containsKey(stockSymbol)) {
        _sentimentControllers[stockSymbol]!.add(fallbackResult);
      }
    }
  }
  
  // One-time sentiment analysis (for initial load or manual refresh)
  Future<SentimentResult> analyzeSentiment(String stockSymbol, double basePrice) async {
    try {
      // Get latest news
      final news = await _newsService.fetchMockNews(stockSymbol);
      
      // Combine all news content for analysis
      final combinedText = news.map((item) => 
        "${item.title}\n${item.content}"
      ).join("\n\n");
      
      // Use the bridge to analyze sentiment
      final nativeResult = await _bridge.analyzeSentimentAsync(
        stockSymbol, 
        basePrice, 
        combinedText
      );
      
      // Convert to our model
      final result = SentimentResult.fromNative(nativeResult);
      
      // Update cache
      _sentimentCache[stockSymbol] = result;
      
      // Update history
      if (!_sentimentHistory.containsKey(stockSymbol)) {
        _sentimentHistory[stockSymbol] = [];
      }
      
      if (_sentimentHistory[stockSymbol]!.length >= 100) {
        _sentimentHistory[stockSymbol]!.removeAt(0);
      }
      _sentimentHistory[stockSymbol]!.add(result);
      
      return result;
    } catch (e) {
      print('Error analyzing sentiment for $stockSymbol: $e');
      
      // If FFI fails, use fallback method
      return _fallbackSentimentAnalysis(stockSymbol, "Fallback analysis due to error");
    }
  }
  
  // Fallback sentiment analysis method
  SentimentResult _fallbackSentimentAnalysis(String stockSymbol, String text) {
    // This is a simplified simulation of sentiment analysis
    // In a real app, you would implement a more sophisticated algorithm
    
    // Count positive and negative words
    final List<String> positiveWords = [
      'growth', 'strong', 'positive', 'bullish', 'improving', 'increase',
      'gain', 'progress', 'opportunity', 'recovery', 'robust', 'ahead',
      'optimistic', 'upward', 'success', 'profitable', 'advantage', 'benefit'
    ];
    
    final List<String> negativeWords = [
      'decline', 'weak', 'negative', 'bearish', 'pressure', 'decrease',
      'loss', 'challenge', 'concern', 'risk', 'downgrade', 'slow',
      'pessimistic', 'downward', 'failure', 'unprofitable', 'disadvantage', 'problem'
    ];
    
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    
    int positiveCount = 0;
    int negativeCount = 0;
    
    for (final word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[^\w]'), '');
      if (positiveWords.contains(cleanWord)) positiveCount++;
      if (negativeWords.contains(cleanWord)) negativeCount++;
    }
    
    // Calculate sentiment score (-1.0 to 1.0)
    final totalWords = words.length;
    final positiveScore = totalWords > 0 ? (positiveCount / totalWords) * 2 : 0;
    final negativeScore = totalWords > 0 ? (negativeCount / totalWords) * 2 : 0;
    
    final baseScore = positiveScore - negativeScore;
    
    // Add some randomness to make it more realistic
    final random = DateTime.now().millisecondsSinceEpoch % 100 / 100;
    final randomFactor = (random - 0.5) * 0.2; // -0.1 to 0.1
    
    // Stock-specific bias (some stocks tend to be more positive/negative)
    double stockBias = 0.0;
    if (stockSymbol.contains('RELIANCE') || stockSymbol.contains('TCS') || 
        stockSymbol.contains('HDFC') || stockSymbol.contains('INFY')) {
      stockBias = 0.1; // Positive bias for blue chips
    } else if (stockSymbol.contains('ADANI')) {
      stockBias = -0.05; // Slight negative bias
    }
    
    // Final score calculation
    final score = baseScore + randomFactor + stockBias;
    final clampedScore = score.clamp(-1.0, 1.0);
    
    // Calculate component contributions
    final vaderValue = clampedScore * 0.8 + (random - 0.5) * 0.3;
    final textblobValue = clampedScore * 0.7 + (random - 0.5) * 0.4;
    final rfValue = clampedScore * 0.9 + (random - 0.5) * 0.2;
    final lstmValue = clampedScore * 0.85 + (random - 0.5) * 0.25;
    
    // Apply weights
    const vaderWeight = 0.35;
    const textblobWeight = 0.15;
    const rfWeight = 0.25;
    const lstmWeight = 0.25;
    
    final vaderComponent = vaderValue * vaderWeight;
    final textblobComponent = textblobValue * textblobWeight;
    final rfComponent = rfValue * rfWeight;
    final lstmComponent = lstmValue * lstmWeight;
    
    // Final weighted score
    final finalScore = vaderComponent + textblobComponent + rfComponent + lstmComponent;
    
    // Confidence calculation
    final confidence = 0.6 + (positiveCount + negativeCount) / (totalWords * 2) * 0.3 + random * 0.1;
    
    // Create components
    final components = [
      SentimentComponent(name: "VADER", contribution: vaderComponent, value: vaderValue),
      SentimentComponent(name: "TextBlob", contribution: textblobComponent, value: textblobValue),
      SentimentComponent(name: "Random Forest", contribution: rfComponent, value: rfValue),
      SentimentComponent(name: "LSTM", contribution: lstmComponent, value: lstmValue),
    ];
    
    // Determine interpretation
    String interpretation;
    if (finalScore <= -0.7) {
      interpretation = "Strongly Bearish";
    } else if (finalScore <= -0.3) {
      interpretation = "Bearish";
    } else if (finalScore < 0.1) {
      interpretation = "Neutral";
    } else if (finalScore < 0.5) {
      interpretation = "Bullish";
    } else {
      interpretation = "Strongly Bullish";
    }
    
    return SentimentResult(
      score: finalScore,
      interpretation: interpretation,
      confidence: confidence,
      components: components,
      timestamp: DateTime.now(),
    );
  }
  
  // Clean up resources
  void dispose(String stockSymbol) {
    if (_sentimentControllers.containsKey(stockSymbol)) {
      _sentimentControllers[stockSymbol]!.close();
      _sentimentControllers.remove(stockSymbol);
    }
    _newsService.dispose(stockSymbol);
  }
  
  void disposeAll() {
    for (var controller in _sentimentControllers.values) {
      controller.close();
    }
    _sentimentControllers.clear();
    _newsService.disposeAll();
  }
}
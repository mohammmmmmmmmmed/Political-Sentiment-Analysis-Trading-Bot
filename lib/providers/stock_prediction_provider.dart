import 'package:flutter/foundation.dart';
// import 'package:stock_sentiment_analyzer/models/sentiment_result.dart';
// import 'package:stock_sentiment_analyzer/services/sentiment_service.dart';
import 'package:trading_bot/models/sentiment_result.dart';
import 'package:trading_bot/services/sentiment_service.dart';

class StockPredictionProvider with ChangeNotifier {
  final SentimentService _sentimentService = SentimentService();
  
  String? _selectedStock;
  double? _basePrice;
  SentimentResult? _sentimentResult;
  bool _isLoading = false;
  String? _error;
  List<SentimentResult> _history = [];
  
  String? get selectedStock => _selectedStock;
  double? get basePrice => _basePrice;
  SentimentResult? get sentimentResult => _sentimentResult;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<SentimentResult> get history => _history;

  void setSelectedStock(String stock) {
    _selectedStock = stock;
    _sentimentResult = null;
    _error = null;
    notifyListeners();
  }

  void setBasePrice(double price) {
    _basePrice = price;
    notifyListeners();
  }

  Future<void> analyzeSentiment() async {
    if (_selectedStock == null || _basePrice == null) {
      _error = "Please select a stock and enter a base price";
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _sentimentService.analyzeSentiment(
        _selectedStock!, 
        _basePrice!,
      );
      
      _sentimentResult = result;
      _history.add(result);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = "Error analyzing sentiment: ${e.toString()}";
      notifyListeners();
    }
  }

  void clearResults() {
    _sentimentResult = null;
    notifyListeners();
  }

  void clearHistory() {
    _history = [];
    notifyListeners();
  }
}


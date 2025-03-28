// lib/providers/stock_prediction_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:trading_bot/models/sentiment_result.dart';
import 'package:trading_bot/services/sentiment_service.dart';
import 'package:trading_bot/services/news_service.dart';

class StockPredictionProvider with ChangeNotifier {
  final SentimentService _sentimentService = SentimentService();
  final NewsService _newsService = NewsService();
  
  String? _selectedStock;
  double? _basePrice;
  SentimentResult? _sentimentResult;
  List<NewsItem> _newsItems = [];
  bool _isLoading = false;
  String? _error;
  List<SentimentResult> _history = [];
  
  // Fix type casting issues with StreamSubscription
  StreamSubscription? _sentimentSubscription;
  StreamSubscription? _newsSubscription;
  
  String? get selectedStock => _selectedStock;
  double? get basePrice => _basePrice;
  SentimentResult? get sentimentResult => _sentimentResult;
  List<NewsItem> get newsItems => _newsItems;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<SentimentResult> get history => _history;

  void setSelectedStock(String stock) {
    // Cancel existing subscriptions
    _cancelSubscriptions();
    
    _selectedStock = stock;
    _sentimentResult = null;
    _newsItems = [];
    _error = null;
    notifyListeners();
    
    // If we have a base price, start analysis
    if (_basePrice != null) {
      _subscribeToUpdates();
    }
  }

  void setBasePrice(double price) {
    _basePrice = price;
    notifyListeners();
    
    // If we have a selected stock, start analysis
    if (_selectedStock != null) {
      _subscribeToUpdates();
    }
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

      // Get initial sentiment analysis
      final result = await _sentimentService.analyzeSentiment(
        _selectedStock!, 
        _basePrice!,
      );
      
      _sentimentResult = result;
      
      // Get history
      _history = _sentimentService.getSentimentHistory(_selectedStock!);
      
      _isLoading = false;
      notifyListeners();
      
      // Subscribe to real-time updates
      _subscribeToUpdates();
    } catch (e) {
      _isLoading = false;
      _error = "Error analyzing sentiment: ${e.toString()}";
      notifyListeners();
    }
  }
  
  void _subscribeToUpdates() {
    // Cancel existing subscriptions
    _cancelSubscriptions();
    
    if (_selectedStock == null || _basePrice == null) return;
    
    // Subscribe to sentiment updates with proper casting
    _sentimentSubscription = _sentimentService
      .getSentimentStream(_selectedStock!, _basePrice!)
      .listen((result) {
        _sentimentResult = result;
        
        // Update history
        _history = _sentimentService.getSentimentHistory(_selectedStock!);
        
        notifyListeners();
      });
    
    // Subscribe to news updates with proper casting
    _newsSubscription = _newsService
      .getNewsStream(_selectedStock!)
      .listen((news) {
        _newsItems = news;
        notifyListeners();
      });
  }
  
  void _cancelSubscriptions() {
    _sentimentSubscription?.cancel();
    _sentimentSubscription = null;
    
    _newsSubscription?.cancel();
    _newsSubscription = null;
  }

  void clearResults() {
    _sentimentResult = null;
    _newsItems = [];
    notifyListeners();
  }

  void clearHistory() {
    _history = [];
    notifyListeners();
  }
  
  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
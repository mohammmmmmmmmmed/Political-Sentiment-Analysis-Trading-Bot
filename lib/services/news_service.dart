// lib/services/news_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';

class NewsItem {
  final String title;
  final String content;
  final String source;
  final DateTime timestamp;
  final String url;
  
  NewsItem({
    required this.title,
    required this.content,
    required this.source,
    required this.timestamp,
    required this.url,
  });
}

class NewsService {
  static final NewsService _instance = NewsService._internal();
  factory NewsService() => _instance;
  
  // Stream controllers for real-time news updates
  final Map<String, StreamController<List<NewsItem>>> _newsControllers = {};
  
  // Cache for news items
  final Map<String, List<NewsItem>> _newsCache = {};
  
  // Random generator for mock data
  final Random _random = Random();
  
  NewsService._internal();
  
  // Get a stream of news for a specific stock
  Stream<List<NewsItem>> getNewsStream(String stockSymbol) {
    if (!_newsControllers.containsKey(stockSymbol)) {
      _newsControllers[stockSymbol] = StreamController<List<NewsItem>>.broadcast();
      _startFetchingNews(stockSymbol);
    }
    return _newsControllers[stockSymbol]!.stream;
  }
  
  // Start fetching news periodically
  void _startFetchingNews(String stockSymbol) {
    // Initial fetch
    _fetchNewsForStock(stockSymbol);
    
    // Set up periodic fetch (every 30 seconds)
    Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchNewsForStock(stockSymbol);
    });
  }
  
  // Fetch news for a specific stock
  Future<void> _fetchNewsForStock(String stockSymbol) async {
    try {
      // In a real app, you would fetch from actual APIs
      // For now, we'll simulate with mock data
      final news = await fetchMockNews(stockSymbol);
      
      // Update cache
      _newsCache[stockSymbol] = news;
      
      // Send to stream if controller exists
      if (_newsControllers.containsKey(stockSymbol)) {
        _newsControllers[stockSymbol]!.add(news);
      }
    } catch (e) {
      print('Error fetching news for $stockSymbol: $e');
    }
  }
  
  // Mock news fetching (replace with real API calls)
  // Make this public so it can be called from other services
  Future<List<NewsItem>> fetchMockNews(String stockSymbol) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Get company name from stock symbol
    final companyName = _getCompanyName(stockSymbol);
    
    // Generate random news based on time
    final now = DateTime.now();
    final random = _random.nextInt(100);
    
    List<NewsItem> news = [];
    
    // Add some positive news
    if (random > 30) {
      news.add(NewsItem(
        title: '$companyName reports strong quarterly results',
        content: '$companyName announced better-than-expected earnings for the quarter, with revenue growing by ${5 + (random % 10)}% year-over-year.',
        source: 'Financial Times',
        timestamp: now.subtract(Duration(minutes: random % 60)),
        url: 'https://example.com/news/1',
      ));
    }
    
    // Add some negative news
    if (random < 70) {
      news.add(NewsItem(
        title: 'Analysts concerned about $companyName\'s growth prospects',
        content: 'Several analysts have expressed concerns about $companyName\'s ability to maintain its growth rate in the coming quarters due to increasing competition.',
        source: 'Bloomberg',
        timestamp: now.subtract(Duration(minutes: (random + 10) % 60)),
        url: 'https://example.com/news/2',
      ));
    }
    
    // Add some neutral news
    news.add(NewsItem(
      title: '$companyName announces new product launch',
      content: '$companyName is set to launch a new product next month, which could potentially impact its market position.',
      source: 'Reuters',
      timestamp: now.subtract(Duration(minutes: (random + 20) % 60)),
      url: 'https://example.com/news/3',
    ));
    
    // Add some industry news
    news.add(NewsItem(
      title: 'Industry outlook remains positive despite challenges',
      content: 'The industry in which $companyName operates is expected to grow by 5% this year, despite macroeconomic challenges.',
      source: 'Industry Today',
      timestamp: now.subtract(Duration(minutes: (random + 30) % 60)),
      url: 'https://example.com/news/4',
    ));
    
    return news;
  }
  
  // Helper method to get company name from stock symbol
 String _getCompanyName(String stockSymbol) {
  final Map<String, String> companyNames = {
    'RELIANCE.BSE': 'Reliance Industries',
    'TCS.BSE': 'Tata Consultancy Services',
    'HDFCBANK.BSE': 'HDFC Bank',
    'INFY.BSE': 'Infosys',
    'ICICIBANK.BSE': 'ICICI Bank',
    'KOTAKBANK.BSE': 'Kotak Mahindra Bank',
    'HINDUNILVR.BSE': 'Hindustan Unilever',
    'ITC.BSE': 'ITC Limited',
    'SBIN.BSE': 'State Bank of India',
    'AXISBANK.BSE': 'Axis Bank',
    'BAJFINANCE.BSE': 'Bajaj Finance',
    'BHARTIARTL.BSE': 'Bharti Airtel',
    'LT.BSE': 'Larsen & Toubro',
    'MARUTI.BSE': 'Maruti Suzuki',
    'ASIANPAINT.BSE': 'Asian Paints',
    'HCLTECH.BSE': 'HCL Technologies',
    'WIPRO.BSE': 'Wipro',
    'ONGC.BSE': 'Oil & Natural Gas Corporation',
    'NTPC.BSE': 'NTPC Limited',
    'POWERGRID.BSE': 'Power Grid Corporation of India',
    'SUNPHARMA.BSE': 'Sun Pharmaceutical Industries',
    'TATAMOTORS.BSE': 'Tata Motors',
    'ULTRACEMCO.BSE': 'UltraTech Cement',
    'TECHM.BSE': 'Tech Mahindra',
    'NESTLEIND.BSE': 'Nestle India',
    'BAJAJFINSV.BSE': 'Bajaj Finserv',
    'DRREDDY.BSE': "Dr. Reddy's Laboratories",
    'ADANIPORTS.BSE': 'Adani Ports & SEZ',
    'TITAN.BSE': 'Titan Company',
    'JSWSTEEL.BSE': 'JSW Steel',
  };
    
    return companyNames[stockSymbol] ?? stockSymbol.split('.').first;
  }
  
  // Clean up resources
  void dispose(String stockSymbol) {
    if (_newsControllers.containsKey(stockSymbol)) {
      _newsControllers[stockSymbol]!.close();
      _newsControllers.remove(stockSymbol);
    }
  }
  
  void disposeAll() {
    for (var controller in _newsControllers.values) {
      controller.close();
    }
    _newsControllers.clear();
  }
}
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Color primaryColor = const Color(0xFF00FFFF); // Electric Blue
  final Color secondaryColor = const Color(0xFFFF00FF); // Hot Pink
  final Color accentColor = const Color(0xFF39FF14); // Neon Green
  final Color backgroundColor = const Color(0xFF1A1A1A); // Dark Gray
  final Color textColor = const Color(0xFFFFFFFF); // White
  final Color highlightColor = const Color(0xFF8A2BE2);
  
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  List<String> _stockSymbols = [];
  String? _selectedStockSymbol;
  Map<String, dynamic>? stockData;
  List<CandleData> _candleData = [];
  bool isLoading = false;
  String? errorMessage;
  List<String> _watchlist = [];
  List<Map<String, String>> _newsItems = [];
  List<Map<String, dynamic>> _majorStocks = [];
  List<NotificationItem> _notifications = [];

  // Replace with your API key
  final String _apiKey = 'VFFWYEE3C54S3TY2';

  @override
  void initState() {
    super.initState();
    fetchStockSymbols();
    fetchNews();
    _initializeMajorStocks();
  }

  void _initializeMajorStocks() {
    // Simulate major stocks data (replace with actual API call)
    setState(() {
      _majorStocks = [
        {'symbol': 'RELIANCE.BSE', 'price': 2500.0, 'change': 12.5},
        {'symbol': 'TCS.BSE', 'price': 3400.0, 'change': -8.3},
        {'symbol': 'HDFCBANK.BSE', 'price': 1600.0, 'change': 5.7},
        {'symbol': 'INFY.BSE', 'price': 1800.0, 'change': 3.2},
        {'symbol': 'ICICIBANK.BSE', 'price': 800.0, 'change': -2.1},
      ];
    });
  }

  Future<void> fetchStockSymbols() async {
    setState(() {
      _stockSymbols = [
        "RELIANCE.BSE",
        "TCS.BSE",
        "HDFCBANK.BSE",
        "INFY.BSE",
        "ICICIBANK.BSE",
        "KOTAKBANK.BSE",
        "HINDUNILVR.BSE",
        "ITC.BSE",
        "SBIN.BSE",
        "AXISBANK.BSE",
        "BAJFINANCE.BSE",
        "BHARTIARTL.BSE",
        "LT.BSE",
        "MARUTI.BSE",
        "ASIANPAINT.BSE",
        "HCLTECH.BSE",
        "WIPRO.BSE",
        "ONGC.BSE",
        "NTPC.BSE",
        "POWERGRID.BSE",
        "SUNPHARMA.BSE",
        "TATAMOTORS.BSE",
        "ULTRACEMCO.BSE",
        "TECHM.BSE",
        "NESTLEIND.BSE",
        "BAJAJFINSV.BSE",
        "DRREDDY.BSE",
        "ADANIPORTS.BSE",
        "TITAN.BSE",
        "JSWSTEEL.BSE",
      ];
    });
  }

  Future<void> fetchStockData(String symbol) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      stockData = null;
      _candleData = [];
    });

    final url =
        'https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=$symbol&apikey=$_apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['Time Series (Daily)'] == null) {
          throw Exception('No data found for symbol $symbol');
        }

        setState(() {
          stockData = data['Time Series (Daily)'];
          _candleData = stockData!.entries.map((entry) {
            final date = DateTime.parse(entry.key);
            final values = entry.value;
            return CandleData(
              date: date,
              open: double.parse(values['1. open']),
              high: double.parse(values['2. high']),
              low: double.parse(values['3. low']),
              close: double.parse(values['4. close']),
            );
          }).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load stock data');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> fetchNews() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _newsItems = [
        {
          'title': 'Reliance Industries announces Q4 results',
          'source': 'Economic Times',
        },
        {
          'title': 'TCS signs 1 billion deal with UK firm',
          'source': 'Business Standard',
        },
        {
          'title': 'HDFC Bank launches new credit card',
          'source': 'Moneycontrol',
        },
      ];
    });
  }

  void _addToWatchlist(String symbol) {
    setState(() {
      if (!_watchlist.contains(symbol)) {
        _watchlist.add(symbol);
        _showNotification('Added to Watchlist', '$symbol has been added to your watchlist.');
      }
    });
  }

  Future<void> _showNotification(String title, String body) async {
    _notifications.add(NotificationItem(
      title: title,
      body: body,
      timestamp: DateTime.now(),
    ));

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Widget _buildNotificationBar() {
    return IconButton(
      icon: const Icon(Icons.notifications),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NotificationScreen(notifications: _notifications),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[100],
      drawer: _buildDrawer(), 
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppBar(),
              _buildSearchBar(),
              SwipeableStockRow(stocks: _majorStocks),
              _buildStockInfo(),
              _buildSentimentChart(),
              _buildWatchlist(),
              _buildNewsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF6C5CE7), 
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage('assets/profile_picture.png'), // Add profile picture
                ),
                SizedBox(height: 10),
                Text(
                  'Trading Bot', // Replace with user's name
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'tradingbot@gmail.com', // Replace with user's email
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              // Add navigation logic here
            },
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              // Add navigation logic here
            },
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationScreen(notifications: _notifications),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              // Add logout logic here
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF6C5CE7), const Color(0xFF6C5CE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stock Dashboard',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Real-time Analysis',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _buildNotificationBar(),
        ],
      ),
    );
  }


  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<String>.empty();
          }
          return _stockSymbols.where((symbol) =>
              symbol.toLowerCase().contains(textEditingValue.text.toLowerCase()));
        },
        onSelected: (String value) {
          setState(() {
            _selectedStockSymbol = value;
          });
          fetchStockData(value);
        },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: 'Search for a stock symbol',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  if (_selectedStockSymbol != null) {
                    fetchStockData(_selectedStockSymbol!);
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStockInfo() {
    if (stockData == null || _candleData.isEmpty) return const SizedBox.shrink();

    final latestData = _candleData.first;
    final price = latestData.close;
    final change = price - _candleData[1].close;
    final changePercent = (change / _candleData[1].close) * 100;
    final isPositive = change >= 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedStockSymbol ?? 'Unknown Symbol',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  if (_selectedStockSymbol != null) {
                    _addToWatchlist(_selectedStockSymbol!);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${change.toStringAsFixed(2)} (${changePercent.toStringAsFixed(2)}%)',
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentChart() {
    if (_candleData.isEmpty) {
      return const Center(child: Text('No historical data available'));
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Movement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                lineBarsData: _generateCandlestickData(),
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: _candleData.length.toDouble() - 1,
                minY: _getMinPrice(),
                maxY: _getMaxPrice(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchlist() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Watchlist',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ..._watchlist.map((symbol) => ListTile(
              title: Text(symbol),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  setState(() {
                    _watchlist.remove(symbol);
                  });
                },
              ),
            )),
      ],
    );
  }

  Widget _buildNewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Latest News',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ..._newsItems.map((news) => ListTile(
              title: Text(news['title']!),
              subtitle: Text(news['source']!),
            )),
      ],
    );
  }

  List<LineChartBarData> _generateCandlestickData() {
    List<LineChartBarData> bars = [];

    for (int i = 0; i < _candleData.length; i++) {
      final data = _candleData[i];
      final bool isGreen = data.close >= data.open;
      final color = isGreen ? Colors.green : Colors.red;

      // Vertical line (high to low)
      bars.add(
        LineChartBarData(
          spots: [
            FlSpot(i.toDouble(), data.low),
            FlSpot(i.toDouble(), data.high),
          ],
          color: color,
          barWidth: 1,
          dotData: FlDotData(show: false),
        ),
      );

      // Body (open to close)
      bars.add(
        LineChartBarData(
          spots: [
            FlSpot(i.toDouble() - 0.1, data.open),
            FlSpot(i.toDouble() + 0.1, data.open),
            FlSpot(i.toDouble() + 0.1, data.close),
            FlSpot(i.toDouble() - 0.1, data.close),
            FlSpot(i.toDouble() - 0.1, data.open),
          ],
          color: color,
          barWidth: 2,
          isCurved: false,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: color.withOpacity(0.1),
          ),
        ),
      );
    }

    return bars;
  }

  double _getMinPrice() {
    return _candleData.map((data) => data.low).reduce((a, b) => a < b ? a : b);
  }

  double _getMaxPrice() {
    return _candleData.map((data) => data.high).reduce((a, b) => a > b ? a : b);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class CandleData {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;

  CandleData({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });
}

class SwipeableStockRow extends StatefulWidget {
  final List<Map<String, dynamic>> stocks;

  const SwipeableStockRow({Key? key, required this.stocks}) : super(key: key);

  @override
  _SwipeableStockRowState createState() => _SwipeableStockRowState();
}

class _SwipeableStockRowState extends State<SwipeableStockRow> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.stocks.length,
            itemBuilder: (context, index) {
              final stock = widget.stocks[index];
              return _buildStockCard(stock, index);
            },
          ),
        ),
        const SizedBox(height: 10),
        _buildPageIndicator(),
      ],
    );
  }

  Widget _buildStockCard(Map<String, dynamic> stock, int index) {
    final isActive = index == _currentPage;
    final price = stock['price'];
    final change = stock['change'];
    final isPositive = change >= 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: isActive ? 0 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              stock['symbol'],
              style: TextStyle(
                fontSize: isActive ? 20 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${price.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: isActive ? 18 : 14,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
            Text(
              '${change.toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: isActive ? 16 : 12,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.stocks.length,
        (index) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index ? Colors.blue : Colors.grey,
          ),
        ),
      ),
    );
  }
}

class NotificationItem {
  final String title;
  final String body;
  final DateTime timestamp;

  NotificationItem({
    required this.title,
    required this.body,
    required this.timestamp,
  });
}

class NotificationScreen extends StatelessWidget {
  final List<NotificationItem> notifications;

  const NotificationScreen({Key? key, required this.notifications}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return ListTile(
            title: Text(notification.title),
            subtitle: Text(notification.body),
            trailing: Text(
              '${notification.timestamp.hour}:${notification.timestamp.minute}',
            ),
          );
        },
      ),
    );
  }
}
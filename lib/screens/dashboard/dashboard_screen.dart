// dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Define the CandleData class first so it can be used throughout the file
class CandleData {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  CandleData({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
}

// Define NotificationItem class
class NotificationItem {
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;

  NotificationItem({
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });
}

// Custom painter for chart background
class ChartBackgroundPainter extends CustomPainter {
  final Color color;

  ChartBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    path.moveTo(0, size.height);

    // Create a simple chart-like path
    path.lineTo(size.width * 0.2, size.height * 0.7);
    path.lineTo(size.width * 0.4, size.height * 0.8);
    path.lineTo(size.width * 0.6, size.height * 0.3);
    path.lineTo(size.width * 0.8, size.height * 0.5);
    path.lineTo(size.width, size.height * 0.2);

    canvas.drawPath(path, paint);

    // Fill the area below the line
    final fillPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom placeholder image widget
class PlaceholderImage extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const PlaceholderImage({
    Key? key,
    required this.width,
    required this.height,
    this.color = const Color(0xFFCCCCCC),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: color.withOpacity(0.2),
      child: Center(
        child: Icon(
          Icons.image,
          size: width * 0.5,
          color: color,
        ),
      ),
    );
  }
}

// Swipeable stock row widget
class SwipeableStockRow extends StatefulWidget {
  final List<Map<String, dynamic>> stocks;
  final AnimationController animationController;

  const SwipeableStockRow({
    Key? key,
    required this.stocks,
    required this.animationController,
  }) : super(key: key);

  @override
  _SwipeableStockRowState createState() => _SwipeableStockRowState();
}

class _SwipeableStockRowState extends State<SwipeableStockRow> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
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
              HapticFeedback.selectionClick();
            },
            itemCount: widget.stocks.length,
            itemBuilder: (context, index) {
              final stock = widget.stocks[index];
              return AnimatedBuilder(
                animation: widget.animationController,
                builder: (context, child) {
                  final animationValue = widget.animationController.value;
                  final isVisible = index <= (widget.stocks.length * animationValue);
                 
                  if (!isVisible) {
                    return const SizedBox();
                  }
                 
                  return _buildStockCard(stock, index);
                },
              );
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
    final color = stock['color'] ?? (isPositive ? Colors.green : Colors.red);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: isActive ? 0 : 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: isActive ? 2 : 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (isActive)
            Positioned(
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(16),
                ),
                child: CustomPaint(
                  size: const Size(100, 70),
                  painter: ChartBackgroundPainter(
                    color: color.withOpacity(0.1),
                  ),
                ),
              ),
            ),
          Center(
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
                const SizedBox(height: 12),
                Text(
                  '₹${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: isActive ? 24 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 14,
                        color: color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${change.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: isActive ? 14 : 12,
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.stocks.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? const Color(0xFF6C5CE7)
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

// Notification screen
class NotificationScreen extends StatefulWidget {
  final List<NotificationItem> notifications;

  const NotificationScreen({Key? key, required this.notifications}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    // Mark all notifications as read when screen is opened
    for (var notification in widget.notifications) {
      notification.isRead = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear All Notifications'),
                    content: const Text('Are you sure you want to clear all notifications?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            widget.notifications.clear();
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: widget.notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'ll notify you when something happens',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.notifications.length,
              itemBuilder: (context, index) {
                final notification = widget.notifications[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.1),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Color(0xFF6C5CE7),
                      ),
                    ),
                    title: Text(
                      notification.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notification.body),
                        const SizedBox(height: 8),
                        Text(
                          '${DateFormat('MMM dd, yyyy').format(notification.timestamp)} at ${DateFormat('hh:mm a').format(notification.timestamp)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        setState(() {
                          widget.notifications.removeAt(index);
                        });
                      },
                    ),
                  ),
                ).animate()
                  .fadeIn(
                    duration: Duration(milliseconds: 300 + (index * 50)),
                    curve: Curves.easeOut,
                  )
                  .slideY(
                    begin: 0.1,
                    end: 0,
                    duration: Duration(milliseconds: 300 + (index * 50)),
                    curve: Curves.easeOut,
                  );
              },
            ),
    );
  }
}

// Main dashboard screen
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  // Colors
  final Color primaryColor = const Color(0xFF6C5CE7);
  final Color secondaryColor = const Color(0xFFFF00FF);
  final Color accentColor = const Color(0xFF39FF14);
  final Color backgroundColor = const Color(0xFFF8F9FA);
  final Color textColor = const Color(0xFF1A1A1A);
  final Color highlightColor = const Color(0xFF8A2BE2);
 
  // Keys and controllers
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  
  // Data
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
 
  // Animation controllers
  late AnimationController _chartAnimationController;
  late AnimationController _searchAnimationController;
  late AnimationController _stockCardAnimationController;
  late TabController _tabController;
 
  // Chart period
  String _selectedPeriod = '1W';
  final List<String> _periods = ['1D', '1W', '1M', '3M', '1Y', 'All'];

  // Theme mode
  bool _isDarkMode = false;

  // API key
  final String _apiKey = 'VFFWYEE3C54S3TY2';

  // Notifications plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
   
    // Initialize animation controllers
    _chartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
   
    _searchAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
   
    _stockCardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
   
    _tabController = TabController(length: 3, vsync: this);
   
    // Initialize notifications
    _initializeNotifications();
    
    // Fetch data
    fetchStockSymbols();
    fetchNews();
    _initializeMajorStocks();
   
    // Start animations
    _chartAnimationController.forward();
    _searchAnimationController.forward();
    _stockCardAnimationController.forward();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification taps
        print('Notification tapped: ${response.payload}');
      },
    );
  }

  void _initializeMajorStocks() {
    // Simulate major stocks data (replace with actual API call)
    setState(() {
      _majorStocks = [
        {'symbol': 'RELIANCE.BSE', 'price': 2500.0, 'change': 12.5, 'color': const Color(0xFF4CAF50)},
        {'symbol': 'TCS.BSE', 'price': 3400.0, 'change': -8.3, 'color': const Color(0xFFF44336)},
        {'symbol': 'HDFCBANK.BSE', 'price': 1600.0, 'change': 5.7, 'color': const Color(0xFF4CAF50)},
        {'symbol': 'INFY.BSE', 'price': 1800.0, 'change': 3.2, 'color': const Color(0xFF4CAF50)},
        {'symbol': 'ICICIBANK.BSE', 'price': 800.0, 'change': -2.1, 'color': const Color(0xFFF44336)},
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

    // Reset chart animation
    _chartAnimationController.reset();

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
              volume: double.parse(values['5. volume']),
            );
          }).toList();
          
          // Sort data by date (newest first)
          _candleData.sort((a, b) => b.date.compareTo(a.date));
          
          isLoading = false;
        });
       
        // Start chart animation
        _chartAnimationController.forward();
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
          'time': '2 hours ago',
          'image': 'placeholder', // Changed to use our custom placeholder
        },
        {
          'title': 'TCS signs 1 billion deal with UK firm',
          'source': 'Business Standard',
          'time': '4 hours ago',
          'image': 'placeholder',
        },
        {
          'title': 'HDFC Bank launches new credit card',
          'source': 'Moneycontrol',
          'time': '6 hours ago',
          'image': 'placeholder',
        },
        {
          'title': 'Market outlook: Experts predict bull run to continue',
          'source': 'Financial Express',
          'time': '8 hours ago',
          'image': 'placeholder',
        },
      ];
    });
  }

  void _addToWatchlist(String symbol) {
    HapticFeedback.mediumImpact();
   
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
      isRead: false,
    ));

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'stock_alerts',
      'Stock Alerts',
      channelDescription: 'Notifications for stock alerts',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFF6C5CE7),
      ledOnMs: 1000,
      ledOffMs: 500,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'watchlist_$title',
    );
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    HapticFeedback.lightImpact();
  }

  // Helper methods for building UI components
  Widget _buildStockMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatVolume(double volume) {
    if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(2)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(2)}K';
    } else {
      return volume.toStringAsFixed(0);
    }
  }

  Widget _buildLoadingChart() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildLoadingStockInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 150,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: 120,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                4,
                (index) => Column(
                  children: [
                    Container(
                      width: 60,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 60,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCandleStickChart(List<CandleData> data) {
    if (data.isEmpty) {
      return const Center(child: Text("No data available for chart"));
    }
    
    // Reverse the data for display (oldest to newest)
    final displayData = data.reversed.toList();
    
    // Calculate min and max values for Y axis
    final minY = displayData.map((e) => e.low).reduce((a, b) => a < b ? a : b) * 0.99;
    final maxY = displayData.map((e) => e.high).reduce((a, b) => a > b ? a : b) * 1.01;
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: minY,
        groupsSpace: 12,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            // tooltipBgColor: primaryColor.withOpacity(0.8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex >= displayData.length) {
                return null;
              }
              final candle = displayData[groupIndex];
              return BarTooltipItem(
                '${DateFormat('MMM dd, yyyy').format(candle.date)}\n'
                'O: ₹${candle.open.toStringAsFixed(2)}\n'
                'H: ₹${candle.high.toStringAsFixed(2)}\n'
                'L: ₹${candle.low.toStringAsFixed(2)}\n'
                'C: ₹${candle.close.toStringAsFixed(2)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= displayData.length || index < 0 || displayData.isEmpty) {
                  return const SizedBox();
                }
                
                // Only show some dates to avoid overcrowding
                if (index % (displayData.length > 10 ? 5 : 2) != 0) {
                  return const SizedBox();
                }
                
                final date = displayData[index].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('dd/MM').format(date),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (maxY - minY) / 5,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '₹${value.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.15),
              strokeWidth: 1,
            );
          },
        ),
        barGroups: List.generate(displayData.length, (index) {
          final candle = displayData[index];
          final isUp = candle.close >= candle.open;
          
          // Calculate the width of the candle body
          final bodyWidth = 6.0;
          
          // Calculate the width of the wick
          final wickWidth = 1.0;
          
          return BarChartGroupData(
            x: index,
            barRods: [
              // Candle body
              BarChartRodData(
                toY: isUp ? candle.close : candle.open,
                fromY: isUp ? candle.open : candle.close,
                width: bodyWidth,
                color: isUp ? Colors.green : Colors.red,
                borderRadius: BorderRadius.zero,
              ),
              // Upper wick
              BarChartRodData(
                toY: candle.high,
                fromY: isUp ? candle.close : candle.open,
                width: wickWidth,
                color: isUp ? Colors.green : Colors.red,
                borderRadius: BorderRadius.zero,
              ),
              // Lower wick
              BarChartRodData(
                toY: isUp ? candle.open : candle.close,
                fromY: candle.low,
                width: wickWidth,
                color: isUp ? Colors.green : Colors.red,
                borderRadius: BorderRadius.zero,
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(50),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _periods.map((period) {
            final isSelected = period == _selectedPeriod;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                });
                HapticFeedback.selectionClick();
                // In a real app, you would fetch data for the selected period
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  period,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Price Chart',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildPeriodSelector(),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: isLoading
                ? _buildLoadingChart()
                : _candleData.isEmpty 
                  ? const Center(child: Text("No data available"))
                  : AnimatedBuilder(
                      animation: _chartAnimationController,
                      builder: (context, child) {
                        // Calculate the number of candles to show based on animation progress
                        final animationValue = _chartAnimationController.value;
                        final candlesToShow = (animationValue * _candleData.length).round();
                        
                        if (candlesToShow <= 0) {
                          return const Center(child: Text("Loading chart data..."));
                        }
                        
                        // Get the visible data
                        final visibleData = _candleData.sublist(0, candlesToShow);
                        
                        return _buildCandleStickChart(visibleData);
                      },
                    ),
          ),
        ],
      ),
    ).animate(controller: _chartAnimationController)
      .fadeIn(duration: const Duration(milliseconds: 800))
      .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 800));
  }

  Widget _buildStockInfo() {
    if (isLoading) {
      return _buildLoadingStockInfo();
    }
   
    if (stockData == null || _candleData.isEmpty) {
      return const SizedBox.shrink();
    }

    // Check if we have at least 2 data points
    if (_candleData.length < 2) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text("Insufficient data to display stock information"),
        ),
      );
    }

    final latestData = _candleData.first;
    final price = latestData.close;
    final change = price - _candleData[1].close;
    final changePercent = (change / _candleData[1].close) * 100;
    final isPositive = change >= 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedStockSymbol ?? 'Unknown Symbol',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last updated: ${DateFormat('MMM dd, yyyy').format(latestData.date)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _watchlist.contains(_selectedStockSymbol)
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  color: _watchlist.contains(_selectedStockSymbol)
                      ? primaryColor
                      : null,
                ),
                onPressed: () {
                  if (_selectedStockSymbol != null) {
                    if (_watchlist.contains(_selectedStockSymbol)) {
                      setState(() {
                        _watchlist.remove(_selectedStockSymbol);
                      });
                    } else {
                      _addToWatchlist(_selectedStockSymbol!);
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 16,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${change.toStringAsFixed(2)} (${changePercent.toStringAsFixed(2)}%)',
                      style: TextStyle(
                        color: isPositive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStockMetric('Open', '₹${latestData.open.toStringAsFixed(2)}'),
                const SizedBox(width: 16),
                _buildStockMetric('High', '₹${latestData.high.toStringAsFixed(2)}'),
                const SizedBox(width: 16),
                _buildStockMetric('Low', '₹${latestData.low.toStringAsFixed(2)}'),
                const SizedBox(width: 16),
                _buildStockMetric('Volume', _formatVolume(latestData.volume)),
              ],
            ),
          ),
        ],
      ),
    ).animate(controller: _chartAnimationController)
      .fadeIn(duration: const Duration(milliseconds: 500))
      .slideY(begin: 0.1, end: 0, duration: const Duration(milliseconds: 500));
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
          HapticFeedback.selectionClick();
        },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: 'Search for a stock symbol',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        controller.clear();
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(50),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ).animate(controller: _searchAnimationController)
            .fadeIn(duration: const Duration(milliseconds: 300))
            .slideY(begin: 0.1, end: 0, duration: const Duration(milliseconds: 300));
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200, maxWidth: double.infinity),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final option = options.elementAt(index);
                    return ListTile(
                      title: Text(option),
                      onTap: () {
                        onSelected(option);
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Color(0xFF6C5CE7),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Trading Bot',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'tradingbot@gmail.com',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            selected: true,
            selectedTileColor: primaryColor.withOpacity(0.1),
            selectedColor: primaryColor,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.trending_up),
            title: const Text('Portfolio'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to portfolio
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Prediction Analysis'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to prediction using sentimental analysis
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            trailing: _notifications.any((n) => !n.isRead)
                ? Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _notifications.where((n) => !n.isRead).length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationScreen(notifications: _notifications),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to help
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              // Show logout confirmation
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        // Implement logout functionality
                        Navigator.pop(context);
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showNewsDetailBottomSheet(BuildContext context, Map<String, String> news) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              alignment: Alignment.center,
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: news['image'] == 'placeholder'
                      ? const PlaceholderImage(width: 80, height: 80)
                      : Image.network(
                          news['image']!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const PlaceholderImage(width: 80, height: 80);
                          },
                        ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          news['source']!,
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          news['time']!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                news['title']!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Reliance Industries has announced its Q4 results, showing a significant increase in revenue and profits. The company reported a net profit of ₹10,000 crore, up 25% from the previous quarter. This growth is attributed to strong performance in the retail and telecom sectors.\n\n'
                  'In other news, TCS has signed a 1 billion deal with a UK-based firm, marking one of the largest contracts in the IT sector this year. The deal is expected to boost TCS\'s presence in the European market.\n\n'
                  'HDFC Bank has launched a new credit card with exclusive benefits for its customers. The card offers cashback on dining, travel, and shopping, along with a low-interest rate on balance transfers.',
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // Share news
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Open in browser
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('Read More'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                padding: const EdgeInsets.all(16),
                children: [
                  _buildQuickActionItem(
                    icon: Icons.add_chart,
                    label: 'Add Stock',
                    onTap: () {
                      Navigator.pop(context);
                      _tabController.animateTo(0);
                    },
                  ),
                  _buildQuickActionItem(
                    icon: Icons.compare_arrows,
                    label: 'Compare',
                    onTap: () {
                      Navigator.pop(context);
                      // Show compare stocks UI
                    },
                  ),
                  _buildQuickActionItem(
                    icon: Icons.notifications_active_outlined,
                    label: 'Set Alert',
                    onTap: () {
                      Navigator.pop(context);
                      // Show set alert UI
                    },
                  ),
                  _buildQuickActionItem(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    onTap: () {
                      Navigator.pop(context);
                      // Show share options
                    },
                  ),
                  _buildQuickActionItem(
                    icon: Icons.analytics_outlined,
                    label: 'Analysis',
                    onTap: () {
                      Navigator.pop(context);
                      // Show analysis UI
                    },
                  ),
                  _buildQuickActionItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to settings
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketTab() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          if (_selectedStockSymbol != null) _buildStockInfo(),
          if (_selectedStockSymbol != null) _buildChartSection(),
          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildWatchlistTab() {
    return _watchlist.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_border,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your watchlist is empty',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add stocks to track them here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    _tabController.animateTo(0);
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Find Stocks'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _watchlist.length,
            itemBuilder: (context, index) {
              final symbol = _watchlist[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: SizedBox(
                    width: 40, // Fixed width for leading widget
                    height: 40,
                    child: CircleAvatar(
                      backgroundColor: primaryColor.withOpacity(0.1),
                      child: Text(
                        symbol.substring(0, 1),
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    symbol,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text('Tap to view details'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      // Show confirmation dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Remove from Watchlist'),
                          content: Text('Are you sure you want to remove $symbol from your watchlist?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _watchlist.remove(symbol);
                                });
                                Navigator.pop(context);
                              },
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  onTap: () {
                    setState(() {
                      _selectedStockSymbol = symbol;
                    });
                    fetchStockData(symbol);
                    _tabController.animateTo(0);
                  },
                ),
              ).animate()
                .fadeIn(
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  curve: Curves.easeOut,
                )
                .slideX(
                  begin: 0.1,
                  end: 0,
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  curve: Curves.easeOut,
                );
            },
          );
  }

  Widget _buildNewsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _newsItems.length,
      itemBuilder: (context, index) {
        final news = _newsItems[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: SizedBox(
              width: 60,
              height: 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: news['image'] == 'placeholder' 
                  ? const PlaceholderImage(width: 60, height: 60)
                  : Image.network(
                      news['image']!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const PlaceholderImage(width: 60, height: 60);
                      },
                    ),
              ),
            ),
            title: Text(
              news['title']!,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  news['source']!,
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  news['time']!,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            onTap: () {
              // Open news detail
              _showNewsDetailBottomSheet(context, news);
            },
          ),
        ).animate()
          .fadeIn(
            duration: Duration(milliseconds: 300 + (index * 100)),
            curve: Curves.easeOut,
          )
          .slideY(
            begin: 0.1,
            end: 0,
            duration: Duration(milliseconds: 300 + (index * 100)),
            curve: Curves.easeOut,
          );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: primaryColor,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Theme.of(context).textTheme.bodyLarge?.color,
        tabs: const [
          Tab(text: 'Market'),
          Tab(text: 'Watchlist'),
          Tab(text: 'News'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _isDarkMode;
   
    return Theme(
      data: isDarkMode ? ThemeData.dark().copyWith(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: const Color(0xFF1E1E1E),
        ),
      ) : ThemeData.light().copyWith(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        drawer: _buildDrawer(context),
        body: SafeArea(
          child: RefreshIndicator(
            color: primaryColor,
            onRefresh: () async {
              if (_selectedStockSymbol != null) {
                await fetchStockData(_selectedStockSymbol!);
              }
              await fetchNews();
              _initializeMajorStocks();
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 120,
                  floating: true,
                  pinned: true,
                  snap: true,
                  backgroundColor: primaryColor,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryColor.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    title: const Text(
                      'Stock Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    centerTitle: false,
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                      HapticFeedback.lightImpact();
                    },
                  ),
                  actions: [
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NotificationScreen(notifications: _notifications),
                              ),
                            );
                          },
                        ),
                        if (_notifications.any((n) => !n.isRead))
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 14,
                                minHeight: 14,
                              ),
                              child: Text(
                                _notifications.where((n) => !n.isRead).length.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                        color: Colors.white,
                      ),
                      onPressed: _toggleTheme,
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: _buildSearchBar(),
                ),
                SliverToBoxAdapter(
                  child: SwipeableStockRow(
                    stocks: _majorStocks,
                    animationController: _stockCardAnimationController,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildTabBar(),
                ),
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMarketTab(),
                      _buildWatchlistTab(),
                      _buildNewsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            // Show quick actions
            _showQuickActionsBottomSheet(context);
          },
          backgroundColor: primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ).animate()
          .scale(
            begin: const Offset(0, 0),
            end: const Offset(1, 1),
            curve: Curves.elasticOut,
            duration: const Duration(milliseconds: 800),
          ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _chartAnimationController.dispose();
    _searchAnimationController.dispose();
    _stockCardAnimationController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}
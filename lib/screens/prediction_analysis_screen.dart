import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:trading_bot/models/sentiment_result.dart';
import 'package:trading_bot/providers/stock_prediction_provider.dart';

class PredictionAnalysisScreen extends StatefulWidget {
  const PredictionAnalysisScreen({Key? key}) : super(key: key);

  @override
  _PredictionAnalysisScreenState createState() => _PredictionAnalysisScreenState();
}

class _PredictionAnalysisScreenState extends State<PredictionAnalysisScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final List<String> _stockSymbols = [
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

  // Updated color scheme
  final Color _primaryColor = const Color(0xFF2C3E50); // Dark blue
  final Color _secondaryColor = const Color(0xFF3498DB); // Bright blue
  final Color _accentColor = const Color(0xFF1ABC9C); // Teal
  final Color _backgroundColor = const Color(0xFFECF0F1); // Light grey
  final Color _cardColor = Colors.white;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Color _getSentimentColor(String type) {
    switch (type) {
      case "strongly_bearish": return const Color(0xFFE74C3C); // Red
      case "bearish": return const Color(0xFFE67E22); // Orange
      case "neutral": return const Color(0xFF95A5A6); // Grey
      case "bullish": return const Color(0xFF2ECC71); // Green
      case "strongly_bullish": return const Color(0xFF27AE60); // Dark green
      default: return const Color(0xFF95A5A6); // Grey default
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StockPredictionProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: _backgroundColor,
          appBar: AppBar(
            title: const Text(
              'Stock Prediction Analysis',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            backgroundColor: _primaryColor,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSelectionForm(context, provider),
                  if (provider.isLoading)
                    _buildLoadingState(),
                  if (provider.error != null)
                    _buildErrorState(provider),
                  if (!provider.isLoading && provider.sentimentResult != null)
                    _buildResultsSection(context, provider),
                  const SizedBox(height: 24), // Bottom padding for scrolling
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectionForm(BuildContext context, StockPredictionProvider provider) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: _cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a Stock for Sentiment Analysis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Stock Symbol',
                  labelStyle: TextStyle(color: _secondaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _accentColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _primaryColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                value: provider.selectedStock,
                items: _stockSymbols.map((symbol) {
                  return DropdownMenuItem(
                    value: symbol,
                    child: Text(symbol),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    provider.setSelectedStock(value);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a stock';
                  }
                  return null;
                },
                icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
                dropdownColor: _cardColor,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Base Price (₹)',
                  labelStyle: TextStyle(color: _secondaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _accentColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _primaryColor, width: 2),
                  ),
                  prefixText: '₹',
                  prefixStyle: TextStyle(color: _primaryColor),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 16),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    provider.setBasePrice(double.parse(value));
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a base price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Hide keyboard before proceeding
                      FocusScope.of(context).unfocus();
                      provider.analyzeSentiment();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Analyze Sentiment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              'Analyzing sentiment data...',
              style: TextStyle(
                color: _primaryColor.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(StockPredictionProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDEDED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE57373)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFD32F2F),
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              provider.error!,
              style: const TextStyle(
                color: Color(0xFFD32F2F),
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(BuildContext context, StockPredictionProvider provider) {
    final result = provider.sentimentResult!;
    final sentimentColor = _getSentimentColor(result.sentimentColor);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Text(
            'Sentiment Analysis Results',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: _primaryColor,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: _cardColor,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        provider.selectedStock!,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _accentColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '₹${provider.basePrice!.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: sentimentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sentiment',
                            style: TextStyle(
                              color: _primaryColor.withOpacity(0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            result.interpretation,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                              color: sentimentColor,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Score',
                            style: TextStyle(
                              color: _primaryColor.withOpacity(0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            result.score.toStringAsFixed(2),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                              color: sentimentColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified,
                            size: 18,
                            color: _primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: _primaryColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM dd, yyyy • HH:mm').format(result.timestamp),
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
                const SizedBox(height: 28),
                _buildSectionHeader('Component Analysis'),
                const SizedBox(height: 12),
                _buildSentimentComponentsChart(result.components),
                const SizedBox(height: 28),
                _buildSectionHeader('What This Means'),
                const SizedBox(height: 12),
                Text(
                  _getInterpretationExplanation(result),
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    height: 1.6,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSuggestionContainer(result.interpretation),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: _primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: _primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionContainer(String sentiment) {
    String suggestion;
    Color bgColor;
    IconData iconData;
    
    if (sentiment.contains("Bullish") || sentiment.contains("Strongly Bullish")) {
      suggestion = "Consider including this stock in your watchlist for potential buying opportunities.";
      bgColor = const Color(0xFFE8F5E9);
      iconData = Icons.trending_up;
    } else if (sentiment.contains("Bearish") || sentiment.contains("Strongly Bearish")) {
      suggestion = "Exercise caution with this stock. Consider reviewing your position if you are currently holding.";
      bgColor = const Color(0xFFFDEDED);
      iconData = Icons.trending_down;
    } else {
      suggestion = "This stock shows balanced sentiment. Consider monitoring for clearer signals before making decisions.";
      bgColor = const Color(0xFFE3F2FD);
      iconData = Icons.trending_flat;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            iconData,
            color: _primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              suggestion,
              style: TextStyle(
                color: Colors.grey.shade800,
                height: 1.5,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentComponentsChart(List<SentimentComponent> components) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceBetween,
          maxY: 0.5,
          minY: -0.5,
          groupsSpace: 16,
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
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value >= components.length) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      components[value.toInt()].name,
                      style: TextStyle(
                        color: _primaryColor.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(
                      color: _primaryColor.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            horizontalInterval: 0.1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.15),
                strokeWidth: 1,
              );
            },
          ),
          barGroups: List.generate(components.length, (index) {
            final component = components[index];
            final isPositive = component.contribution >= 0;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: component.contribution,
                  fromY: 0,
                  color: isPositive 
                    ? const Color(0xFF2ECC71).withOpacity(0.9) // Green
                    : const Color(0xFFE74C3C).withOpacity(0.9), // Red
                  width: 18,
                  borderRadius: BorderRadius.vertical(
                    top: const Radius.circular(6),
                    bottom: const Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  String _getInterpretationExplanation(SentimentResult result) {
    final baseExplanation = 'Based on our sentiment analysis of recent news and social media discussions, ';
    
    if (result.interpretation == "Strongly Bearish") {
      return '$baseExplanation the market sentiment for this stock is extremely negative. This suggests potential downward pressure on the price in the near term. This analysis is based on ${(result.confidence * 100).toStringAsFixed(0)}% confidence from our sentiment models.';
    } else if (result.interpretation == "Bearish") {
      return '$baseExplanation the market sentiment for this stock is negative. Investors should exercise caution as this could indicate price weakness ahead. This analysis is based on ${(result.confidence * 100).toStringAsFixed(0)}% confidence from our sentiment models.';
    } else if (result.interpretation == "Neutral") {
      return '$baseExplanation the market sentiment for this stock is relatively balanced between positive and negative signals. This suggests a sideways movement or limited directional bias in the short term. This analysis is based on ${(result.confidence * 100).toStringAsFixed(0)}% confidence from our sentiment models.';
    } else if (result.interpretation == "Bullish") {
      return '$baseExplanation the market sentiment for this stock is positive. This suggests potential upward momentum in the near term. This analysis is based on ${(result.confidence * 100).toStringAsFixed(0)}% confidence from our sentiment models.';
    } else {
      return '$baseExplanation the market sentiment for this stock is extremely positive. This suggests strong upward potential for the price in the near term. This analysis is based on ${(result.confidence * 100).toStringAsFixed(0)}% confidence from our sentiment models.';
    }
  }
}
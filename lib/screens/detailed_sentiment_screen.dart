import 'package:flutter/material.dart';
import 'package:trading_bot/models/sentiment_result.dart';
import 'package:trading_bot/widgets/sentiment_trend_chart.dart';
import 'package:intl/intl.dart';

class DetailedSentimentScreen extends StatelessWidget {
  final SentimentResult sentimentResult;
  final String stockSymbol;
  final double basePrice;
  final List<SentimentResult> history;

  const DetailedSentimentScreen({
    Key? key,
    required this.sentimentResult,
    required this.stockSymbol,
    required this.basePrice,
    required this.history,
  }) : super(key: key);

  Color _getSentimentColor(String type) {
    switch (type) {
      case "strongly_bearish": return Colors.red.shade800;
      case "bearish": return Colors.red.shade400;
      case "neutral": return Colors.grey.shade500;
      case "bullish": return Colors.green.shade400;
      case "strongly_bullish": return Colors.green.shade800;
      default: return Colors.grey;
    }
  }

  String _getRecommendation(SentimentResult result) {
    final score = result.score;
    
    if (score <= -0.7) {
      return "Consider reducing exposure to this stock. The extremely negative sentiment suggests significant downside risk.";
    } else if (score <= -0.3) {
      return "Exercise caution with this stock. The negative sentiment indicates potential price weakness.";
    } else if (score < 0.1) {
      return "Hold position. The neutral sentiment suggests limited directional bias in the short term.";
    } else if (score < 0.5) {
      return "Consider increasing exposure to this stock. The positive sentiment indicates potential upward momentum.";
    } else {
      return "Consider a strong buy position. The extremely positive sentiment suggests significant upside potential.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final sentimentColor = _getSentimentColor(sentimentResult.sentimentColor);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Analysis for $stockSymbol'),
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          stockSymbol,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        Text(
                          '₹${basePrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: sentimentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            sentimentResult.interpretation,
                            style: TextStyle(
                              color: sentimentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Text(
                              'Score: ',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              sentimentResult.score.toStringAsFixed(2),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: sentimentColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Analysis from ${DateFormat('MMM dd, yyyy • HH:mm').format(sentimentResult.timestamp)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Sentiment Trend Chart
            if (history.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sentiment Trend',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        SentimentTrendChart(sentimentHistory: history),
                      ],
                    ),
                  ),
                ),
              ),
              
            // Component Analysis
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Component Analysis',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      ...sentimentResult.components.map((component) {
                        final isPositive = component.contribution >= 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    component.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    component.contribution.toStringAsFixed(3),
                                    style: TextStyle(
                                      color: isPositive ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: 0.5 + (component.contribution / 0.4),
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isPositive ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
            
            // Recommendation
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recommendation',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: sentimentColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: sentimentColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              sentimentResult.score >= 0 
                                ? Icons.trending_up 
                                : Icons.trending_down,
                              color: sentimentColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _getRecommendation(sentimentResult),
                                style: TextStyle(
                                  color: Colors.grey.shade800,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Disclaimer: This is not financial advice. Always conduct your own research before making investment decisions.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


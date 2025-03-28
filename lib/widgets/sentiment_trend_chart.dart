// lib/widgets/sentiment_trend_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:trading_bot/models/sentiment_result.dart';
import 'package:intl/intl.dart';

class SentimentTrendChart extends StatelessWidget {
  final List<SentimentResult> sentimentHistory;

  const SentimentTrendChart({
    Key? key,
    required this.sentimentHistory,
  }) : super(key: key);

  Color _getSentimentColor(double score) {
    if (score <= -0.7) return const Color(0xFFE74C3C); // Red
    if (score <= -0.3) return const Color(0xFFE67E22); // Orange
    if (score < 0.1) return const Color(0xFF95A5A6); // Grey
    if (score < 0.5) return const Color(0xFF2ECC71); // Green
    return const Color(0xFF27AE60); // Dark green
  }

  @override
  Widget build(BuildContext context) {
    if (sentimentHistory.isEmpty) {
      return const Center(
        child: Text("No sentiment history available"),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 0.25,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.15),
              strokeWidth: 1,
            );
          },
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
                if (value.toInt() >= sentimentHistory.length || value < 0) {
                  return const SizedBox();
                }

                if (sentimentHistory.length > 5 && value.toInt() % 2 != 0) {
                  return const SizedBox();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('HH:mm').format(
                      sentimentHistory[value.toInt()].timestamp,
                    ),
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
              interval: 0.25,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(2),
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
        minX: 0,
        maxX: sentimentHistory.length - 1.0,
        minY: -1,
        maxY: 1,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(sentimentHistory.length, (index) {
              return FlSpot(
                index.toDouble(),
                sentimentHistory[index].score,
              );
            }),
            isCurved: true,
            gradient: LinearGradient(
              colors: sentimentHistory.map((result) => 
                _getSentimentColor(result.score)
              ).toList(),
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: _getSentimentColor(
                    sentimentHistory[index].score
                  ),
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  _getSentimentColor(sentimentHistory.first.score)
                      .withOpacity(0.3),
                  _getSentimentColor(sentimentHistory.last.score)
                      .withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
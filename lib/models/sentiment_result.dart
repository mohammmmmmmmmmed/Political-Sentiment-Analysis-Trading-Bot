class SentimentComponent {
  final String name;
  final double contribution;
  final double value;

  SentimentComponent({
    required this.name,
    required this.contribution,
    required this.value,
  });

  factory SentimentComponent.fromJson(Map<String, dynamic> json) {
    return SentimentComponent(
      name: json['name'],
      contribution: json['contribution'],
      value: json['value'],
    );
  }
}

class SentimentResult {
  final double score;
  final String interpretation;
  final double confidence;
  final List<SentimentComponent> components;
  final DateTime timestamp;

  SentimentResult({
    required this.score, 
    required this.interpretation,
    required this.confidence,
    required this.components,
    required this.timestamp,
  });

  factory SentimentResult.fromNative(Map<String, dynamic> nativeResult) {
    final score = nativeResult['score'];
    
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
    
    return SentimentResult(
      score: score,
      interpretation: interpretation,
      confidence: nativeResult['confidence'],
      components: (nativeResult['components'] as List)
          .map((comp) => SentimentComponent.fromJson(comp))
          .toList(),
      timestamp: DateTime.now(),
    );
  }

  String get sentimentColor {
    if (score <= -0.7) return "strongly_bearish";
    if (score <= -0.3) return "bearish";
    if (score < 0.1) return "neutral";
    if (score < 0.5) return "bullish";
    return "strongly_bullish";
  }
}


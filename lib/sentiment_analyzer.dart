import 'dart:math';

// This is a Dart implementation of the sentiment analysis model
// It's a simplified version of the C++ model provided in sentiment-scoring-nlp.cpp
class SentimentAnalyzer {
  // Lexicons for sentiment analysis
  final Map<String, double> _vaderLexicon = {
    "bullish": 0.8, "buy": 0.7, "up": 0.6, "profit": 0.7, "growth": 0.7,
    "strong": 0.6, "outperform": 0.6, "gain": 0.6, "rise": 0.6, "optimistic": 0.7,
    "bearish": -0.8, "sell": -0.7, "down": -0.6, "loss": -0.7, "weak": -0.6,
    "underperform": -0.6, "decline": -0.6, "crash": -0.8, "pessimistic": -0.7, "risk": -0.5,
    "not": -1.0, "very": 1.5, "good": 0.6, "bad": -0.6, "great": 0.8, "terrible": -0.8,
    "happy": 0.7, "sad": -0.7, "inflation": -0.5, "downturn": -0.6, "volatile": -0.4,
    "momentum": 0.6, "indices": 0.4, "stabilizing": 0.5, "challenges": -0.4,
    "opinion": 0.0, "fact": 0.0, "think": 0.2, "believe": 0.2,
    "logistics": 0.4, "cybersecurity": 0.5, "cloud": 0.6, "computing": 0.5,
    "quantum": 0.7, "space": 0.6, "defense": 0.4, "rallying": 0.6,
    "revolutionizing": 0.8, "booming": 0.7, "critical": 0.5, "future": 0.6,
    "exciting": 0.7, "travel": 0.4, "stocks": 0.3, "companies": 0.3,
    "lol": 0.0, "meme": 0.2, "amc": 0.3, "gme": 0.3, "moon": 0.5
  };

  final Map<String, double> _polarityLexicon = {
    "bullish": 0.8, "buy": 0.7, "up": 0.6, "profit": 0.7, "growth": 0.7,
    "strong": 0.6, "outperform": 0.6, "gain": 0.6, "rise": 0.6, "optimistic": 0.7,
    "bearish": -0.8, "sell": -0.7, "down": -0.6, "loss": -0.7, "weak": -0.6,
    "underperform": -0.6, "decline": -0.6, "crash": -0.8, "pessimistic": -0.7, "risk": -0.5,
    "good": 0.6, "bad": -0.6, "great": 0.8, "terrible": -0.8, "happy": 0.7, "sad": -0.7,
    "inflation": -0.5, "downturn": -0.6, "volatile": -0.4,
    "momentum": 0.6, "indices": 0.4, "stabilizing": 0.5, "challenges": -0.4,
  };

  final Map<String, double> _subjectivityLexicon = {
    "opinion": 0.8, "fact": 0.2, "think": 0.7, "believe": 0.6,
    "bullish": 0.6, "bearish": 0.6, "buy": 0.5, "sell": 0.5,
    "profit": 0.4, "loss": 0.4, "growth": 0.5, "decline": 0.5,
    "crash": 0.6, "pessimistic": 0.7, "risk": 0.5, "inflation": 0.4, "volatile": 0.5,
  };

  // Model weights
  final Map<String, double> _modelWeights = {
    "vader": 0.35,
    "textblob": 0.15,
    "random_forest": 0.25,
    "lstm": 0.25,
  };

  // Analyze sentiment of a text
  Map<String, dynamic> analyzeSentiment(String text) {
    // Convert text to lowercase and split into words
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    
    // VADER-like sentiment analysis
    double positiveScore = 0.0;
    double negativeScore = 0.0;
    double neutralScore = 0.0;
    double amplifier = 1.0;
    
    for (final word in words) {
      if (word == "not") {
        amplifier = -1.0;
        continue;
      } else if (word == "very") {
        amplifier = 1.5;
        continue;
      }
      
      double score = 0.0;
      if (_vaderLexicon.containsKey(word)) {
        score = _vaderLexicon[word]! * amplifier;
      } else {
        score = amplifier * (word.length > 5 ? 0.1 : -0.1);
      }
      
      if (score > 0) {
        positiveScore += score;
      } else if (score < 0) {
        negativeScore += score;
      } else {
        neutralScore += 1.0;
      }
      
      amplifier = 1.0;
    }
    
    // Calculate VADER compound score
    final totalScore = positiveScore + negativeScore + neutralScore;
    final denominator = positiveScore.abs() + negativeScore.abs() + neutralScore + 1e-6;
    final vaderScore = tanh(totalScore / denominator);
    
    // TextBlob-like sentiment analysis
    double polarity = 0.0;
    double subjectivity = 0.0;
    
    for (final word in words) {
      if (_polarityLexicon.containsKey(word)) {
        polarity += _polarityLexicon[word]!;
      } else {
        polarity += (word.length > 5 ? 0.1 : -0.1);
      }
      
      if (_subjectivityLexicon.containsKey(word)) {
        subjectivity += _subjectivityLexicon[word]!;
      } else {
        subjectivity += 0.1;
      }
    }
    
    polarity /= words.length + 1e-6;
    subjectivity /= words.length + 1e-6;
    
    // Random Forest prediction
    final features = <String, int>{};
    for (final word in words) {
      features[word] = (features[word] ?? 0) + 1;
    }
    
    double rfPrediction = 0.0;
    for (final entry in features.entries) {
      if (_vaderLexicon.containsKey(entry.key)) {
        rfPrediction += _vaderLexicon[entry.key]! * entry.value * 0.8;
      }
    }
    rfPrediction /= words.length + 1e-6;
    
    // LSTM-like sequence processing
    final inputs = <double>[];
    for (final word in words) {
      if (_vaderLexicon.containsKey(word)) {
        inputs.add(_vaderLexicon[word]!);
      } else {
        inputs.add(0.0);
      }
    }
    
    double lstmOutput = 0.0;
    double hiddenState = 0.0;
    final weightInput = 0.5;
    final weightHidden = 0.5;
    
    for (final input in inputs) {
      hiddenState = tanh(weightInput * input + weightHidden * hiddenState);
    }
    lstmOutput = hiddenState;
    
    // Calculate weighted sentiment
    final adjustedVaderScore = 2.0 / (1.0 + exp(-vaderScore)) - 1.0;
    
    final maxRFValue = 1.0;
    final maxLSTMValue = 1.0;
    final normalizedRFPrediction = rfPrediction / maxRFValue;
    final normalizedLSTMOutput = lstmOutput / maxLSTMValue;
    
    final sentimentScore = (
      adjustedVaderScore * _modelWeights["vader"]! +
      polarity * _modelWeights["textblob"]! +
      normalizedRFPrediction * _modelWeights["random_forest"]! +
      normalizedLSTMOutput * _modelWeights["lstm"]!
    );
    
    final confidenceFactor = 1.0 - (subjectivity * 0.5) + adjustedVaderScore.abs() * 0.5;
    
    double finalScore = sentimentScore * confidenceFactor;
    finalScore = max(-1.0, min(finalScore, 1.0));
    
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
    
    final componentContributions = {
      "vader": adjustedVaderScore * _modelWeights["vader"]!,
      "textblob": polarity * _modelWeights["textblob"]!,
      "random_forest": normalizedRFPrediction * _modelWeights["random_forest"]!,
      "lstm": normalizedLSTMOutput * _modelWeights["lstm"]!,
    };
    
    return {
      "finalScore": finalScore,
      "interpretation": interpretation,
      "confidenceFactor": confidenceFactor,
      "componentContributions": componentContributions,
    };
  }
  
  // Helper function: hyperbolic tangent
  double tanh(double x) {
    final exp2x = exp(2 * x);
    return (exp2x - 1) / (exp2x + 1);
  }
}


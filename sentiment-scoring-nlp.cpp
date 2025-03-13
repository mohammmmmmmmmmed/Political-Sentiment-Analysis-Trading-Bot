#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <string>
#include <cmath>
#include <algorithm>
#include <cctype>
#include <map>

// Function to split a string by a delimiter
std::vector<std::string> split(const std::string& str, char delimiter) {
    std::vector<std::string> tokens;
    std::string token;
    std::istringstream tokenStream(str);
    while (std::getline(tokenStream, token, delimiter)) {
        tokens.push_back(token);
    }
    return tokens;
}

// Function to convert a string to lowercase
std::string toLowerCase(const std::string& str) {
    std::string lowerStr = str;
    std::transform(lowerStr.begin(), lowerStr.end(), lowerStr.begin(), ::tolower);
    return lowerStr;
}

// Function to extract the first quoted string from a line
std::string extractQuotedComment(const std::string& line) {
    size_t start = line.find('"'); // Find the first quote
    if (start == std::string::npos) {
        return line; // If no quotes, return the whole line
    }
    size_t end = line.find('"', start + 1); // Find the closing quote
    if (end == std::string::npos) {
        return line.substr(start + 1); // If no closing quote, return the rest of the line
    }
    return line.substr(start + 1, end - start - 1); // Extract the quoted text
}

// VADER-like sentiment scoring
struct VaderSentiment {
    double positiveScore = 0.0;
    double negativeScore = 0.0;
    double neutralScore = 0.0;

    void updateScores(const std::string& word, const std::map<std::string, double>& lexicon) {
        static double amplifier = 1.0; // Reset amplifier for each word
        if (word == "not") {
            amplifier = -1.0; // Negate the next word's score
            return;
        } else if (word == "very") {
            amplifier = 1.5; // Amplify the next word's score
            return;
        }

        double score = 0.0;
        if (lexicon.find(word) != lexicon.end()) {
            score = lexicon.at(word) * amplifier;
        } else {
            // Assign a small default score for unknown words
            score = amplifier * (word.size() > 5 ? 0.1 : -0.1); // Heuristic for unknown words
        }

        if (score > 0) {
            positiveScore += score;
        } else if (score < 0) {
            negativeScore += score;
        } else {
            neutralScore += 1.0;
        }
        amplifier = 1.0; // Reset amplifier after applying it
    }

    double computeCompoundScore() const {
        double totalScore = positiveScore + negativeScore + neutralScore;
        double denominator = fabs(positiveScore) + fabs(negativeScore) + neutralScore + 1e-6;
        return tanh(totalScore / denominator); // Use tanh to limit the range to [-1, 1]
    }
};

// TextBlob-like sentiment analysis
struct TextBlobSentiment {
    double polarity = 0.0;
    double subjectivity = 0.0;

    void analyze(const std::string& text, const std::map<std::string, double>& polarityLexicon,
                 const std::map<std::string, double>& subjectivityLexicon) {
        std::vector<std::string> words = split(toLowerCase(text), ' ');
        for (const auto& word : words) {
            if (polarityLexicon.find(word) != polarityLexicon.end()) {
                polarity += polarityLexicon.at(word);
            } else {
                polarity += (word.size() > 5 ? 0.1 : -0.1); // Default heuristic for unknown words
            }
            if (subjectivityLexicon.find(word) != subjectivityLexicon.end()) {
                subjectivity += subjectivityLexicon.at(word);
            } else {
                subjectivity += 0.1; // Default heuristic for unknown words
            }
        }
        polarity /= words.size() + 1e-6;
        subjectivity /= words.size() + 1e-6;
    }
};

// Random Forest-like predictive model with dynamic weight updates
class RandomForest {
private:
    struct DecisionTree {
        std::map<std::string, double> weights;

        // Predict sentiment score for given features
        double predict(const std::map<std::string, int>& features) const {
            double score = 0.0;
            for (const auto& [feature, value] : features) {
                if (weights.find(feature) != weights.end()) {
                    score += weights.at(feature) * value;
                }
            }
            return score;
        }

        // Update weights using gradient descent
        void updateWeights(const std::map<std::string, int>& features, double error, double learningRate) {
            for (const auto& [feature, value] : features) {
                if (weights.find(feature) != weights.end()) {
                    weights[feature] -= learningRate * error * value; // Adjust weight based on error
                }
            }
        }
    };

    std::vector<DecisionTree> trees;

public:
    explicit RandomForest(int numTrees) {
        trees.resize(numTrees);
    }

    // Initial training using lexicon
    void train(const std::map<std::string, double>& lexicon) {
        for (auto& tree : trees) {
            for (const auto& [word, score] : lexicon) {
                if (score > 0) {
                    tree.weights[word] = score * 0.8; // Positive weight
                } else if (score < 0) {
                    tree.weights[word] = score * 0.8; // Negative weight
                }
            }
        }
    }

    // Predict sentiment score
    double predict(const std::map<std::string, int>& features) const {
        double score = 0.0;
        for (const auto& tree : trees) {
            score += tree.predict(features);
        }
        return score / trees.size();
    }

    // Dynamically update weights based on feedback
    void updateWeights(const std::map<std::string, int>& features, double trueSentiment, double predictedSentiment, double learningRate) {
        double error = predictedSentiment - trueSentiment; // Calculate prediction error
        for (auto& tree : trees) {
            tree.updateWeights(features, error, learningRate); // Update weights for each tree
        }
    }
};

// LSTM-like recurrent neural network
class SimpleLSTM {
private:
    double hiddenState = 0.0;
    double weightInput = 0.5;
    double weightHidden = 0.5;

public:
    double processSequence(const std::vector<double>& inputs) {
        for (double input : inputs) {
            hiddenState = tanh(weightInput * input + weightHidden * hiddenState);
        }
        return hiddenState;
    }
};

// Struct to hold sentiment result
struct SentimentResult {
    double finalScore;
    std::string interpretation;
    double confidenceFactor;
    std::map<std::string, double> componentContributions;
};

// Function to calculate weighted sentiment
SentimentResult calculateWeightedSentiment(double vaderScore, double textblobPolarity,
                                           double textblobSubjectivity, double randomForestPred,
                                           double lstmOutput) {
    // Adjust VADER score to reduce dominance of extreme values
    double adjustedVaderScore = 2.0 / (1.0 + exp(-vaderScore)) - 1.0;

    // Normalize Random Forest and LSTM outputs to [-1, 1]
    double maxRFValue = 1.0; // Replace with actual max value from training
    double maxLSTMValue = 1.0; // Replace with actual max value from training
    double normalizedRFPrediction = randomForestPred / maxRFValue;
    double normalizedLSTMOutput = lstmOutput / maxLSTMValue;

    // Weights based on model strengths
    double vaderWeight = 0.35;
    double textblobPolWeight = 0.15;
    double rfWeight = 0.25;
    double lstmWeight = 0.25;

    // Calculate primary sentiment score
    double sentimentScore = (
        adjustedVaderScore * vaderWeight +
        textblobPolarity * textblobPolWeight +
        normalizedRFPrediction * rfWeight +
        normalizedLSTMOutput * lstmWeight
    );

    // Confidence factor (adjusted for subjectivity and sentiment strength)
    double confidenceFactor = 1.0 - (textblobSubjectivity * 0.5) + fabs(adjustedVaderScore) * 0.5;

    // Final weighted score
    double finalScore = sentimentScore * confidenceFactor;

    // Clamp to [-1, 1]
    finalScore = std::max(std::min(finalScore, 1.0), -1.0);

    // Interpretation categories (asymmetric thresholds)
    std::string interpretation;
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

    // Component contributions
    std::map<std::string, double> componentContributions = {
        {"vader", adjustedVaderScore * vaderWeight},
        {"textblob", textblobPolarity * textblobPolWeight},
        {"random_forest", normalizedRFPrediction * rfWeight},
        {"lstm", normalizedLSTMOutput * lstmWeight}
    };

    return SentimentResult{finalScore, interpretation, confidenceFactor, componentContributions};
}

int main() {
    // Define lexicons for VADER and TextBlob
    std::map<std::string, double> vaderLexicon = {
        {"bullish", 0.8}, {"buy", 0.7}, {"up", 0.6}, {"profit", 0.7}, {"growth", 0.7},
        {"strong", 0.6}, {"outperform", 0.6}, {"gain", 0.6}, {"rise", 0.6}, {"optimistic", 0.7},
        {"bearish", -0.8}, {"sell", -0.7}, {"down", -0.6}, {"loss", -0.7}, {"weak", -0.6},
        {"underperform", -0.6}, {"decline", -0.6}, {"crash", -0.8}, {"pessimistic", -0.7}, {"risk", -0.5},
        {"not", -1.0}, {"very", 1.5}, {"good", 0.6}, {"bad", -0.6}, {"great", 0.8}, {"terrible", -0.8},
        {"happy", 0.7}, {"sad", -0.7}, {"inflation", -0.5}, {"downturn", -0.6}, {"volatile", -0.4},
        {"momentum", 0.6}, {"indices", 0.4}, {"stabilizing", 0.5}, {"challenges", -0.4},
        {"opinion", 0.0}, {"fact", 0.0}, {"think", 0.2}, {"believe", 0.2},
        {"logistics", 0.4}, {"cybersecurity", 0.5}, {"cloud", 0.6}, {"computing", 0.5},
        {"quantum", 0.7}, {"space", 0.6}, {"defense", 0.4}, {"rallying", 0.6},
        {"revolutionizing", 0.8}, {"booming", 0.7}, {"critical", 0.5}, {"future", 0.6},
        {"exciting", 0.7}, {"travel", 0.4}, {"stocks", 0.3}, {"companies", 0.3},
        {"lol", 0.0}, {"meme", 0.2}, {"amc", 0.3}, {"gme", 0.3}, {"moon", 0.5}
    };

    std::map<std::string, double> polarityLexicon = {
        {"bullish", 0.8}, {"buy", 0.7}, {"up", 0.6}, {"profit", 0.7}, {"growth", 0.7},
        {"strong", 0.6}, {"outperform", 0.6}, {"gain", 0.6}, {"rise", 0.6}, {"optimistic", 0.7},
        {"bearish", -0.8}, {"sell", -0.7}, {"down", -0.6}, {"loss", -0.7}, {"weak", -0.6},
        {"underperform", -0.6}, {"decline", -0.6}, {"crash", -0.8}, {"pessimistic", -0.7}, {"risk", -0.5},
        {"good", 0.6}, {"bad", -0.6}, {"great", 0.8}, {"terrible", -0.8}, {"happy", 0.7}, {"sad", -0.7},
        {"inflation", -0.5}, {"downturn", -0.6}, {"volatile", -0.4},
        {"momentum", 0.6}, {"indices", 0.4}, {"stabilizing", 0.5}, {"challenges", -0.4},
        {"logistics", 0.4}, {"cybersecurity", 0.5}, {"cloud", 0.6}, {"computing", 0.5},
        {"quantum", 0.7}, {"space", 0.6}, {"defense", 0.4}, {"rallying", 0.6},
        {"revolutionizing", 0.8}, {"booming", 0.7}, {"critical", 0.5}, {"future", 0.6},
        {"exciting", 0.7}, {"travel", 0.4}, {"stocks", 0.3}, {"companies", 0.3},
        {"lol", 0.0}, {"meme", 0.2}, {"amc", 0.3}, {"gme", 0.3}, {"moon", 0.5}
    };

    std::map<std::string, double> subjectivityLexicon = {
        {"opinion", 0.8}, {"fact", 0.2}, {"think", 0.7}, {"believe", 0.6},
        {"bullish", 0.6}, {"bearish", 0.6}, {"buy", 0.5}, {"sell", 0.5},
        {"profit", 0.4}, {"loss", 0.4}, {"growth", 0.5}, {"decline", 0.5},
        {"crash", 0.6}, {"pessimistic", 0.7}, {"risk", 0.5}, {"inflation", 0.4}, {"volatile", 0.5},
        {"momentum", 0.5}, {"indices", 0.3}, {"stabilizing", 0.4}, {"challenges", 0.6},
        {"logistics", 0.4}, {"cybersecurity", 0.5}, {"cloud", 0.6}, {"computing", 0.5},
        {"quantum", 0.7}, {"space", 0.6}, {"defense", 0.4}, {"rallying", 0.6},
        {"revolutionizing", 0.8}, {"booming", 0.7}, {"critical", 0.5}, {"future", 0.6},
        {"exciting", 0.7}, {"travel", 0.4}, {"stocks", 0.3}, {"companies", 0.3},
        {"lol", 0.1}, {"meme", 0.3}, {"amc", 0.2}, {"gme", 0.2}, {"moon", 0.4}
    };

    // Open the CSV file containing Reddit comments
    std::ifstream file("reddit_comments.csv");
    if (!file.is_open()) {
        std::cerr << "Error: Could not open file. Ensure 'reddit_comments.csv' exists in the same directory.\n";
        return 1;
    }

    std::cout << "Processing Reddit comments for sentiment analysis...\n\n";

    // Initialize Random Forest
    RandomForest forest(5); // 5 trees
    forest.train(vaderLexicon); // Initial training using lexicon

    std::string line;
    while (std::getline(file, line)) {
        // Extract the comment using the new function
        std::string comment = extractQuotedComment(line);
        if (comment.empty()) {
            continue; // Skip empty lines
        }

        // VADER-like sentiment analysis
        VaderSentiment vader;
        std::vector<std::string> words = split(toLowerCase(comment), ' ');
        for (const auto& word : words) {
            vader.updateScores(word, vaderLexicon);
        }
        double vaderScore = vader.computeCompoundScore();

        // TextBlob-like sentiment analysis
        TextBlobSentiment textBlob;
        textBlob.analyze(comment, polarityLexicon, subjectivityLexicon);

        // Random Forest prediction
        std::map<std::string, int> features;
        for (const auto& word : words) {
            features[word]++;
        }
        double rfPrediction = forest.predict(features);

        // Simulate true sentiment for feedback (e.g., based on VADER score)
        double trueSentiment = vaderScore; // Use VADER score as ground truth for simplicity

        // Update weights dynamically based on prediction error
        forest.updateWeights(features, trueSentiment, rfPrediction, 0.01); // Learning rate = 0.01

        // LSTM-like sequence processing
        std::vector<double> inputs;
        for (const auto& word : words) {
            if (vaderLexicon.find(word) != vaderLexicon.end()) {
                inputs.push_back(vaderLexicon[word]); // Use sentiment score as input
            } else {
                inputs.push_back(0.0); // Neutral sentiment for unknown words
            }
        }
        SimpleLSTM lstm;
        double lstmOutput = lstm.processSequence(inputs);

        // Calculate weighted sentiment
        SentimentResult sentimentResult = calculateWeightedSentiment(
            vaderScore, textBlob.polarity, textBlob.subjectivity, rfPrediction, lstmOutput
        );

        // Output results
        std::cout << "Comment: " << comment << "\n";
        std::cout << "Final Score: " << sentimentResult.finalScore << "\n";
        std::cout << "Interpretation: " << sentimentResult.interpretation << "\n";
        std::cout << "Confidence Factor: " << sentimentResult.confidenceFactor << "\n";
        std::cout << "Component Contributions:\n";
        for (const auto& [model, contribution] : sentimentResult.componentContributions) {
            std::cout << "  " << model << ": " << contribution << "\n";
        }
        std::cout << "\n";
    }

    file.close();
    std::cout << "Sentiment analysis completed successfully.\n";
    return 0;
}

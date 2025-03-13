#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <string>
#include <cmath>
#include <algorithm>
#include <cctype>
#include <map>

// ... [rest of the code remains the same until the main function]

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

    // Prompt user for the CSV file name
    std::string filename;
    std::cout << "Enter the CSV file name from the 'csv_docs' folder (e.g., reddit_comments.csv): ";
    std::cin >> filename;

    // Construct the full file path
    std::string filePath = "csv_docs/" + filename;

    // Open the CSV file
    std::ifstream file(filePath);
    if (!file.is_open()) {
        std::cerr << "Error: Could not open file. Ensure the file exists in the 'csv_docs' folder.\n";
        return 1;
    }

    std::cout << "Processing comments from " << filename << " for sentiment analysis...\n\n";

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

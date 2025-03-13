// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class StockService {
//   static const String apiKey = 'NI4J64PJEKXNP1U8';
//   static const String baseUrl = 'https://www.alphavantage.co/query';

//   static Future<Map<String, dynamic>> fetchLiveStockData(String symbol) async {
//     print('Fetching data for symbol: $symbol');
    
//     final url = '$baseUrl?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$apiKey';
//     print('API URL: $url');

//     try {
//       final response = await http.get(Uri.parse(url));
//       print('Response status code: ${response.statusCode}');
//       print('Response body: ${response.body}');

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> data = json.decode(response.body);
        
//         // Check if we got an error message from the API
//         if (data.containsKey('Error Message')) {
//           throw Exception('API Error: ${data['Error Message']}');
//         }
        
//         // Check if we got empty data
//         if (data['Global Quote'] == null || (data['Global Quote'] as Map).isEmpty) {
//           throw Exception('No data found for symbol $symbol');
//         }

//         return data;
//       } else {
//         throw Exception('Failed to load stock data. Status code: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error in fetchLiveStockData: $e');
//       rethrow;
//     }
//   }
// }

import 'dart:convert';
import 'package:http/http.dart' as http;

class StockService {
  static const String apiKey = 'PJFG440YNQX1O28S'; // Replace with your Alpha Vantage API key
  static const String baseUrl = 'https://www.alphavantage.co/query';

  // Fetch live stock data
  static Future<Map<String, dynamic>> fetchLiveStockData(String symbol) async {
    print('Fetching data for symbol: $symbol');

    final url = '$baseUrl?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$apiKey';
    print('API URL: $url');

    try {
      final response = await http.get(Uri.parse(url));
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Check if we got an error message from the API
        if (data.containsKey('Error Message')) {
          throw Exception('API Error: ${data['Error Message']}');
        }

        // Check if we got empty data
        if (data['Global Quote'] == null || (data['Global Quote'] as Map).isEmpty) {
          throw Exception('No data found for symbol $symbol. Please check if the symbol is correct and supported by Alpha Vantage.');
        }

        return data;
      } else {
        throw Exception('Failed to load stock data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchLiveStockData: $e');
      rethrow;
    }
  }

  // Fetch historical stock data (intraday)
  static Future<List<Map<String, dynamic>>> fetchHistoricalStockData(String symbol) async {
    print('Fetching historical data for symbol: $symbol');

    final url = '$baseUrl?function=TIME_SERIES_INTRADAY&symbol=$symbol&interval=60min&apikey=$apiKey';
    print('API URL: $url');

    try {
      final response = await http.get(Uri.parse(url));
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Check if we got an error message from the API
        if (data.containsKey('Error Message')) {
          throw Exception('API Error: ${data['Error Message']}');
        }

        // Check if we got empty data
        if (data['Time Series (60min)'] == null || (data['Time Series (60min)'] as Map).isEmpty) {
          throw Exception('No historical data found for symbol $symbol. Please check if the symbol is correct and supported by Alpha Vantage.');
        }

        // Parse historical data into a list of candlestick values
        final timeSeries = data['Time Series (60min)'] as Map<String, dynamic>;
        final List<Map<String, dynamic>> historicalData = timeSeries.entries.map((entry) {
          return {
            'time': entry.key,
            'open': double.parse(entry.value['1. open']),
            'high': double.parse(entry.value['2. high']),
            'low': double.parse(entry.value['3. low']),
            'close': double.parse(entry.value['4. close']),
          };
        }).toList();

        return historicalData;
      } else {
        throw Exception('Failed to load historical data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchHistoricalStockData: $e');
      rethrow;
    }
  }
}
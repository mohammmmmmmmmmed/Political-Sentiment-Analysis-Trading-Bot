// lib/ffi/sentiment_bindings.dart
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'dart:math';

// Define the SentimentResult struct to match the C++ struct
class SentimentResult extends Struct {
  @Double()
  external double score;
  
  @Double()
  external double vader_component;
  
  @Double()
  external double textblob_component;
  
  @Double()
  external double random_forest_component;
  
  @Double()
  external double lstm_component;
  
  @Double()
  external double confidence;
}

// Define the function types for FFI
typedef AnalyzeSentimentNative = Pointer<SentimentResult> Function(
  Pointer<Utf8> stockSymbol,
  Double basePrice,
  Pointer<Utf8> textData,
);

typedef AnalyzeSentimentDart = Pointer<SentimentResult> Function(
  Pointer<Utf8> stockSymbol,
  double basePrice,
  Pointer<Utf8> textData,
);

typedef FreeSentimentResultNative = Void Function(Pointer<SentimentResult> result);
typedef FreeSentimentResultDart = void Function(Pointer<SentimentResult> result);

// Class to handle FFI calls
class SentimentAnalyzerFFI {
  DynamicLibrary? _nativeLib;
  AnalyzeSentimentDart? _analyzeSentiment;
  FreeSentimentResultDart? _freeSentimentResult;
  bool _initialized = false;
  
  static final SentimentAnalyzerFFI _instance = SentimentAnalyzerFFI._internal();
  
  factory SentimentAnalyzerFFI() {
    return _instance;
  }
  
  SentimentAnalyzerFFI._internal() {
    _tryLoadLibrary();
  }
  
  void _tryLoadLibrary() {
    try {
      if (Platform.isAndroid) {
        _nativeLib = DynamicLibrary.open('libsentiment_analyzer.so');
      } else if (Platform.isIOS) {
        _nativeLib = DynamicLibrary.process();
      } else if (Platform.isWindows) {
        _nativeLib = DynamicLibrary.open('sentiment_analyzer.dll');
      } else if (Platform.isLinux) {
        _nativeLib = DynamicLibrary.open('libsentiment_analyzer.so');
      } else if (Platform.isMacOS) {
        _nativeLib = DynamicLibrary.open('libsentiment_analyzer.dylib');
      } else {
        print("Unsupported platform for FFI");
        return;
      }
      
      _analyzeSentiment = _nativeLib!
          .lookup<NativeFunction<AnalyzeSentimentNative>>('analyze_sentiment')
          .asFunction<AnalyzeSentimentDart>();
      
      _freeSentimentResult = _nativeLib!
          .lookup<NativeFunction<FreeSentimentResultNative>>('free_sentiment_result')
          .asFunction<FreeSentimentResultDart>();
      
      _initialized = true;
      print("FFI library loaded successfully");
    } catch (e) {
      print("Error loading FFI library: $e");
      _initialized = false;
    }
  }
  
  // Method to analyze sentiment
  Map<String, dynamic> analyzeSentiment(String stockSymbol, double basePrice, String textData) {
    if (!_initialized) {
      throw Exception("FFI library not initialized");
    }
    
    final stockSymbolPointer = stockSymbol.toNativeUtf8();
    final textDataPointer = textData.toNativeUtf8();
    
    try {
      final resultPointer = _analyzeSentiment!(stockSymbolPointer, basePrice, textDataPointer);
      final result = resultPointer.ref;
      
      final Map<String, dynamic> sentimentData = {
        'score': result.score,
        'components': [
          {'name': 'VADER', 'value': result.vader_component / 0.35, 'contribution': result.vader_component},
          {'name': 'TextBlob', 'value': result.textblob_component / 0.15, 'contribution': result.textblob_component},
          {'name': 'Random Forest', 'value': result.random_forest_component / 0.25, 'contribution': result.random_forest_component},
          {'name': 'LSTM', 'value': result.lstm_component / 0.25, 'contribution': result.lstm_component},
        ],
        'confidence': result.confidence,
      };
      
      // Free the native memory
      _freeSentimentResult!(resultPointer);
      
      return sentimentData;
    } finally {
      // Free the string pointers
      calloc.free(stockSymbolPointer);
      calloc.free(textDataPointer);
    }
  }
}
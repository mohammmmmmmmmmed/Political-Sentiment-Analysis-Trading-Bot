// lib/ffi/sentiment_bridge.dart
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'package:ffi/ffi.dart';

// Rename to NativeSentimentResult to avoid conflict
class NativeSentimentResult extends Struct {
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

// Update function types to use the new name
typedef AnalyzeSentimentNative = Pointer<NativeSentimentResult> Function(
  Pointer<Utf8> stockSymbol,
  Double basePrice,
  Pointer<Utf8> textData,
);

typedef AnalyzeSentimentDart = Pointer<NativeSentimentResult> Function(
  Pointer<Utf8> stockSymbol,
  double basePrice,
  Pointer<Utf8> textData,
);

typedef FreeSentimentResultNative = Void Function(Pointer<NativeSentimentResult> result);
typedef FreeSentimentResultDart = void Function(Pointer<NativeSentimentResult> result);

// Class to handle FFI calls
class SentimentBridge {
  static final SentimentBridge _instance = SentimentBridge._internal();
  factory SentimentBridge() => _instance;
  
  late DynamicLibrary _nativeLib;
  late AnalyzeSentimentDart _analyzeSentiment;
  late FreeSentimentResultDart _freeSentimentResult;
  bool _isInitialized = false;
  
  SentimentBridge._internal() {
    _initializeLibrary();
  }
  
  bool get isInitialized => _isInitialized;
  
  void _initializeLibrary() {
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
      
      _analyzeSentiment = _nativeLib
          .lookup<NativeFunction<AnalyzeSentimentNative>>('analyze_sentiment')
          .asFunction<AnalyzeSentimentDart>();
      
      _freeSentimentResult = _nativeLib
          .lookup<NativeFunction<FreeSentimentResultNative>>('free_sentiment_result')
          .asFunction<FreeSentimentResultDart>();
      
      _isInitialized = true;
      print("FFI library loaded successfully");
    } catch (e) {
      print("Failed to load FFI library: $e");
      _isInitialized = false;
    }
  }
  
  // Method to analyze sentiment in a separate isolate for better performance
  Future<Map<String, dynamic>> analyzeSentimentAsync(
    String stockSymbol, 
    double basePrice, 
    String textData
  ) async {
    // Use Isolate.run for better performance with heavy processing
    return await Isolate.run(() => _analyzeSentimentSync(stockSymbol, basePrice, textData));
  }
  
  // Synchronous method to analyze sentiment (called from isolate)
  Map<String, dynamic> _analyzeSentimentSync(
    String stockSymbol, 
    double basePrice, 
    String textData
  ) {
    if (!_isInitialized) {
      throw Exception("FFI library not initialized");
    }
    
    final stockSymbolPointer = stockSymbol.toNativeUtf8();
    final textDataPointer = textData.toNativeUtf8();
    
    try {
      final resultPointer = _analyzeSentiment(stockSymbolPointer, basePrice, textDataPointer);
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
      _freeSentimentResult(resultPointer);
      
      return sentimentData;
    } finally {
      // Free the string pointers
      calloc.free(stockSymbolPointer);
      calloc.free(textDataPointer);
    }
  }
}
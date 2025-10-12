import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceSearchService {
  static final SpeechToText _speech = SpeechToText();
  static bool _isInitialized = false;
  static bool _isListening = false;

  /// Initialize the speech recognition service
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      debugPrint('Initializing voice search service...');
      
      // Check and request microphone permission
      final permissionStatus = await Permission.microphone.request();
      debugPrint('Microphone permission status: $permissionStatus');
      
      if (permissionStatus != PermissionStatus.granted) {
        debugPrint('Microphone permission denied');
        return false;
      }

      // Initialize speech recognition
      final available = await _speech.initialize(
        onError: (error) {
          debugPrint('Speech recognition error: ${error.errorMsg}');
        },
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
          _isListening = status == 'listening';
        },
      );

      debugPrint('Speech recognition available: $available');
      _isInitialized = available;
      return available;
    } catch (e) {
      debugPrint('Failed to initialize speech recognition: $e');
      return false;
    }
  }

  /// Check if speech recognition is available
  static Future<bool> isAvailable() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _speech.isAvailable;
  }

  /// Start listening for voice input
  static Future<String?> startListening({
    Duration timeout = const Duration(seconds: 10),
    String localeId = 'en_US',
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        throw Exception('Speech recognition not available');
      }
    }

    if (_isListening) {
      await stopListening();
    }

    try {
      String? result;
      final completer = Completer<String?>();
      
      await _speech.listen(
        onResult: (speechResult) {
          debugPrint('Speech result: ${speechResult.recognizedWords}');
          if (speechResult.finalResult) {
            result = speechResult.recognizedWords;
            if (!completer.isCompleted) {
              completer.complete(result);
            }
          }
        },
        listenFor: timeout,
        pauseFor: const Duration(seconds: 3),
        localeId: localeId,
        listenOptions: SpeechListenOptions(
          partialResults: true,
        ),
      );
      
      // Set listening state
      _isListening = true;

      // Wait for either completion or timeout
      try {
        result = await completer.future.timeout(timeout);
      } catch (e) {
        debugPrint('Voice recognition timeout or error: $e');
        // Get the last recognized words if available
        if (_speech.lastRecognizedWords.isNotEmpty) {
          result = _speech.lastRecognizedWords;
        }
      }

      return result;
    } catch (e) {
      debugPrint('Error during speech recognition: $e');
      return null;
    }
  }

  /// Stop listening for voice input
  static Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      debugPrint('Voice search stopped');
    }
  }

  /// Cancel current listening session
  static Future<void> cancelListening() async {
    if (_isListening) {
      await _speech.cancel();
      _isListening = false;
      debugPrint('Voice search cancelled');
    }
  }

  /// Check if currently listening
  static bool get isListening => _isListening;

  /// Get available locales for speech recognition
  static Future<List<LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _speech.locales();
  }

  /// Dispose of the speech recognition service
  static void dispose() {
    _speech.stop();
    _isInitialized = false;
    _isListening = false;
  }
}

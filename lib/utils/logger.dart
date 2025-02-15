import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart, // Updated this line
    ),
    level: kDebugMode ? Level.debug : Level.error,
  );

  static void debug(dynamic message, {Object? error}) {
    if (kDebugMode) {
      _logger.d(message, error: error);
    }
  }

  static void info(dynamic message) {
    if (kDebugMode) {
      _logger.i(message);
    }
  }

  static void warning(dynamic message) {
    _logger.w(message);
  }

  static void error(dynamic message, {StackTrace? stackTrace}) {
    _logger.e(message, error: stackTrace);
  }
}
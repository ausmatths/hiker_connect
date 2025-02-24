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
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: kDebugMode ? Level.debug : Level.error,
  );

  static void debug(dynamic message, [dynamic error]) {
    if (kDebugMode) {
      _logger.d(message, error: error);
    }
  }

  static void info(dynamic message) {
    if (kDebugMode) {
      _logger.i(message);
    }
  }

  static void warning(dynamic message, [dynamic error]) {
    _logger.w(message, error: error);
  }

  static void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      _logger.e('$message\nError: $error${stackTrace != null ? '\nStack trace: $stackTrace' : ''}');
    } else {
      _logger.e(message);
    }
  }
}
import 'package:firebase_performance/firebase_performance.dart';

class PerformanceMonitoringService {
  final FirebasePerformance _performance = FirebasePerformance.instance;

  PerformanceMonitoringService() {
    // Enable performance collection (can be toggled based on user preferences)
    _performance.setPerformanceCollectionEnabled(true);
  }

  // Create a trace for a specific operation
  Trace newTrace(String name) {
    return _performance.newTrace(name);
  }

  // Trace a network request
  HttpMetric newHttpMetric(String url, HttpMethod method) {
    return _performance.newHttpMetric(url, method);
  }

  // Helper method to trace event operation
  Future<T> traceEventOperation<T>({
    required String traceName,
    required Future<T> Function() operation,
    Map<String, String>? attributes,
  }) async {
    final trace = _performance.newTrace(traceName);
    await trace.start();

    try {
      final result = await operation();

      // Add success attribute
      trace.putAttribute('success', 'true');

      // Add custom attributes
      if (attributes != null) {
        attributes.forEach((key, value) {
          trace.putAttribute(key, value);
        });
      }

      return result;
    } catch (e) {
      // Record error
      trace.putAttribute('success', 'false');
      trace.putAttribute('error', e.toString().substring(0, min(100, e.toString().length)));
      rethrow;
    } finally {
      await trace.stop();
    }
  }

  int min(int a, int b) => a < b ? a : b;
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiker_connect/utils/transitions.dart'; // Update this path as needed

void main() {
  group('Custom Page Routes', () {
    // Just test that routes can be created without errors
    test('FadePageRoute initializes correctly', () {
      final testWidget = Container();
      final route = FadePageRoute(page: testWidget);

      expect(route.page, equals(testWidget));
      expect(route.barrierColor, isNull);
      expect(route, isA<PageRouteBuilder>());
    });

    test('SlideUpPageRoute initializes correctly', () {
      final testWidget = Container();
      final route = SlideUpPageRoute(page: testWidget);

      expect(route.page, equals(testWidget));
      expect(route.barrierColor, isNull);
      expect(route, isA<PageRouteBuilder>());
    });

    // Test the pageBuilder function directly
    test('FadePageRoute pageBuilder returns the correct widget', () {
      final testWidget = Container();
      final route = FadePageRoute(page: testWidget);

      // Extract the pageBuilder function
      final pageBuilderFunction = route.pageBuilder;

      // Call the pageBuilder function with dummy arguments
      final resultWidget = pageBuilderFunction(
          MaterialApp().createElement(),
          const AlwaysStoppedAnimation(0.0),
          const AlwaysStoppedAnimation(0.0)
      );

      // Verify it returns the original widget
      expect(resultWidget, equals(testWidget));
    });

    test('SlideUpPageRoute pageBuilder returns the correct widget', () {
      final testWidget = Container();
      final route = SlideUpPageRoute(page: testWidget);

      // Extract the pageBuilder function
      final pageBuilderFunction = route.pageBuilder;

      // Call the pageBuilder function with dummy arguments
      final resultWidget = pageBuilderFunction(
          MaterialApp().createElement(),
          const AlwaysStoppedAnimation(0.0),
          const AlwaysStoppedAnimation(0.0)
      );

      // Verify it returns the original widget
      expect(resultWidget, equals(testWidget));
    });
  });
}
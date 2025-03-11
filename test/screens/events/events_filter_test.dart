import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:hiker_connect/models/event_filter.dart';
import 'package:hiker_connect/screens/events/events_filter_screen.dart';

void main() {
  testWidgets('Initial State Test', (WidgetTester tester) async {
    final initialFilter = EventFilter();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventsFilterScreen(initialFilter: initialFilter),
        ),
      ),
    );

    // Verify initial state
    expect(find.text('Filter Events'), findsOneWidget); // AppBar title
    expect(find.text('Reset'), findsOneWidget); // Reset button
    expect(find.text('Select date & time'), findsNWidgets(2)); // Start and end date fields
    expect(find.text('Any Time'), findsOneWidget); // Default time period
    expect(find.text('Any difficulty level'), findsOneWidget); // Default difficulty level
    expect(find.text('Any distance'), findsOneWidget); // Default maximum distance
  });

  testWidgets('Select Start Date and Time', (WidgetTester tester) async {
    final initialFilter = EventFilter();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventsFilterScreen(initialFilter: initialFilter),
        ),
      ),
    );

    // Tap the start date field
    await tester.tap(find.text('Select date & time').first);
    await tester.pumpAndSettle();

    // Select a date
    await tester.tap(find.text('15'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Select a time
    await tester.tap(find.text('9:00 AM'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Verify the selected date and time
    expect(find.text('Nov 15, 2023 @ 9:00 AM'), findsOneWidget);
  });

  testWidgets('Select Time Period', (WidgetTester tester) async {
    final initialFilter = EventFilter();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventsFilterScreen(initialFilter: initialFilter),
        ),
      ),
    );

    // Tap the "Morning" time period
    await tester.tap(find.text('Morning'));
    await tester.pump();

    // Verify the selected time period
    expect(find.text('Morning'), findsOneWidget);
  });

  testWidgets('Select Category', (WidgetTester tester) async {
    final initialFilter = EventFilter();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventsFilterScreen(initialFilter: initialFilter),
        ),
      ),
    );

    // Tap the "Hiking" category
    await tester.tap(find.text('Hiking'));
    await tester.pump();

    // Verify the selected category
    expect(find.text('Hiking'), findsOneWidget);
  });

  testWidgets('Change Difficulty Level', (WidgetTester tester) async {
    final initialFilter = EventFilter();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventsFilterScreen(initialFilter: initialFilter),
        ),
      ),
    );

    // Drag the difficulty slider
    final slider = find.byType(Slider);
    await tester.drag(slider, const Offset(100, 0));
    await tester.pump();

    // Verify the selected difficulty level
    expect(find.text('Difficulty: Level 3'), findsOneWidget);
  });

  testWidgets('Enter Location Query', (WidgetTester tester) async {
    final initialFilter = EventFilter();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventsFilterScreen(initialFilter: initialFilter),
        ),
      ),
    );

    // Enter text in the location search field
    await tester.enterText(find.byType(TextField), 'Rocky Mountains');
    await tester.pump();

    // Verify the entered location query
    expect(find.text('Rocky Mountains'), findsOneWidget);
  });

  testWidgets('Toggle Show Only Favorites', (WidgetTester tester) async {
    final initialFilter = EventFilter();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventsFilterScreen(initialFilter: initialFilter),
        ),
      ),
    );

    // Tap the "Show only favorites" switch
    await tester.tap(find.byType(Switch).first);
    await tester.pump();

    // Verify the switch is toggled
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('Reset Filters', (WidgetTester tester) async {
    final initialFilter = EventFilter();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventsFilterScreen(initialFilter: initialFilter),
        ),
      ),
    );

    // Tap the reset button
    await tester.tap(find.text('Reset'));
    await tester.pump();

    // Verify all filters are reset
    expect(find.text('Select date & time'), findsNWidgets(2)); // Start and end date fields
    expect(find.text('Any Time'), findsOneWidget); // Default time period
    expect(find.text('Any difficulty level'), findsOneWidget); // Default difficulty level
    expect(find.text('Any distance'), findsOneWidget); // Default maximum distance
  });

  testWidgets('Apply Filters', (WidgetTester tester) async {
    final initialFilter = EventFilter();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventsFilterScreen(initialFilter: initialFilter),
        ),
      ),
    );

    // Tap the apply button
    await tester.tap(find.text('Apply Filters'));
    await tester.pump();

    // Verify the filter is applied
    expect(find.byType(EventsFilterScreen), findsNothing);
  });
}
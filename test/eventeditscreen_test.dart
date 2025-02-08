import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiker_connect/models/trail_data.dart';
import 'package:hiker_connect/screens/trails/event_edit_screen.dart';

void main() {
  late TrailData mockEvent;
  late bool onUpdateCalled;
  late bool onDeleteCalled;

  setUp(() {
    mockEvent = TrailData(
      name: 'Mountain Hike',
      description: 'A scenic mountain hike',
      difficulty: 'Moderate',
      notice: 'Bring water and snacks',
      images: [],
      date: DateTime.now().add(const Duration(days: 2)),
      location: 'Trailhead A',
      participants: 5,
      duration: const Duration(hours: 3, minutes: 0),
    );
    onUpdateCalled = false;
    onDeleteCalled = false;
  });

  testWidgets('EventEditScreen displays event details', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: EventEditScreen(
        event: mockEvent,
        onUpdate: (updatedEvent) => onUpdateCalled = true,
        onDelete: () => onDeleteCalled = true,
      ),
    ));

    expect(find.text('Edit Trail'), findsOneWidget);
    expect(find.text('A scenic mountain hike'), findsOneWidget);
    expect(find.text('Trailhead A'), findsOneWidget);
    expect(find.text('Bring water and snacks'), findsOneWidget);
    expect(find.text(mockEvent.participants.toString()), findsOneWidget);
  });

  testWidgets('Updates notice and participants field', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: EventEditScreen(
        event: mockEvent,
        onUpdate: (updatedEvent) => onUpdateCalled = true,
        onDelete: () => onDeleteCalled = true,
      ),
    ));

    await tester.enterText(find.byType(TextFormField).at(2), '10');
    await tester.enterText(find.byType(TextFormField).at(3), 'Updated Notice to - Wear boots');

    await tester.ensureVisible(find.widgetWithText(ElevatedButton, "Save Changes"));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, "Save Changes"));
    await tester.pump();

    expect(onUpdateCalled, isTrue);
  });

  testWidgets('Deletes event when delete button is pressed', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: EventEditScreen(
        event: mockEvent,
        onUpdate: (updatedEvent) => onUpdateCalled = true,
        onDelete: () => onDeleteCalled = true,
      ),
    ));

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pump();

    expect(onDeleteCalled, isTrue);
  });
}

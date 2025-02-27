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
      trailId: 1,
      trailName: 'Mountain Hike',
      trailDescription: 'A scenic mountain hike',
      trailDifficulty: 'Moderate',
      trailNotice: 'Bring water and snacks',
      trailImages: [],
      trailDate: DateTime.now().add(const Duration(days: 2)),
      trailLocation: 'Trailhead A',
      trailParticipantNumber: 5,
      trailDuration: const Duration(hours: 3, minutes: 0),
      trailType: 'Trail', // Add this line to fix the error
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
    expect(find.text(mockEvent.trailParticipantNumber.toString()), findsOneWidget);
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
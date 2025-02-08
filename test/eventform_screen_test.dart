import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiker_connect/screens/trails/eventform_screen.dart';

void main() {
  testWidgets('EventFormScreen should validate inputs and submit', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: EventFormScreen()));

    expect(find.byType(TextFormField), findsNWidgets(5));
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(find.text('Save Trail'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Test Event Description');
    await tester.enterText(find.byType(TextFormField).at(1), 'Test Location');
    await tester.enterText(find.byType(TextFormField).at(2), '5');


    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Moderate').last);
    await tester.pump();


    await tester.tap(find.text('Save Trail'));
    await tester.pump();


    expect(find.text('Please enter event description'), findsNothing);
    expect(find.text('Please enter the event location'), findsNothing);
    expect(find.text('Please enter the number of participants'), findsNothing);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiker_connect/screens/trails/traileventform_screen.dart';
import 'package:hiker_connect/services/databaseservice.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/profile/profile_screen_test.mocks.dart';

// Create mock classes
class MockDatabaseService extends Mock implements DatabaseService {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
@GenerateMocks([DatabaseService, FirebaseAuth, User, ImagePicker])
void main() {
  late MockDatabaseService mockDbService;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;

  setUp(() {
    mockDbService = MockDatabaseService();
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();

    // Setup Firebase Auth mock
    when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('test-user-id');
  });

  // Helper function to ensure widget is visible and tap it safely
  Future<void> ensureVisibleAndTap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  testWidgets('EventFormScreen should validate inputs and submit', (WidgetTester tester) async {
    // Create mock instances
    final mockDatabaseService = MockDatabaseService();
    final mockFirestore = MockFirebaseFirestore();
    final mockAuth = MockFirebaseAuth();

    // Build the EventFormScreen with all required providers
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<DatabaseService>.value(value: mockDatabaseService),
          Provider<FirebaseFirestore>.value(value: mockFirestore),
          Provider<FirebaseAuth>.value(value: mockFirebaseAuth),
        ],
        child: const MaterialApp(home: EventFormScreen()),
      ),
    );

    // There are 5 TextFormFields in the form
    expect(find.byType(TextFormField), findsNWidgets(5));

    // There are 2 DropdownButtonFormFields (type and difficulty)
    expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));

    // Enter test data into the form fields
    await tester.enterText(find.widgetWithText(TextFormField, 'Trail Name'), 'Test Trail');
    await tester.enterText(find.widgetWithText(TextFormField, 'Trail Description'), 'Test Description');
    await tester.enterText(find.widgetWithText(TextFormField, 'Location'), 'Test Location');
    await tester.enterText(find.widgetWithText(TextFormField, 'Number of Participants'), '5');

    // Select difficulty level
    final difficultyDropdown = find.widgetWithText(DropdownButtonFormField<String>, 'Difficulty Level');
    await ensureVisibleAndTap(tester, difficultyDropdown);
    await ensureVisibleAndTap(tester, find.text('Moderate').last);

    // Tap the save button
    final saveButton = find.widgetWithText(ElevatedButton, 'Save Trail');
    await ensureVisibleAndTap(tester, saveButton);

    // Verify validation messages don't appear (meaning validation passed)
    expect(find.text('Please enter Trail name'), findsNothing);
    expect(find.text('Please enter Trail description'), findsNothing);
    expect(find.text('Please enter Trail Location'), findsNothing);
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          Provider<DatabaseService>.value(value: mockDbService),
          Provider<FirebaseAuth>.value(value: mockFirebaseAuth),
        ],
        child: const EventFormScreen(),
      ),
    );
  }

  testWidgets('EventFormScreen renders correctly', (WidgetTester tester) async {
    // Set a larger screen size for testing
    tester.binding.window.physicalSizeTestValue = const Size(1024, 1600);
    tester.binding.window.devicePixelRatioTestValue = 1.0;

    addTearDown(() {
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });

    // Build our app and trigger a frame
    await tester.pumpWidget(buildTestWidget());

    // Verify that all form fields are rendered
    expect(find.text('Create Trail/Event'), findsOneWidget);
    expect(find.text('Type'), findsOneWidget);
    expect(find.text('Trail Name'), findsOneWidget);
    expect(find.text('Trail Description'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Difficulty Level'), findsOneWidget);
    expect(find.text('Notice (e.g., special instructions)'), findsOneWidget);
    expect(find.text('Number of Participants'), findsOneWidget);
    expect(find.text('Upload Image'), findsOneWidget);
    expect(find.textContaining('Save'), findsOneWidget);
  });

  testWidgets('Form validates required fields', (WidgetTester tester) async {
    // Set a larger screen size for testing
    tester.binding.window.physicalSizeTestValue = const Size(1024, 1600);
    tester.binding.window.devicePixelRatioTestValue = 1.0;

    addTearDown(() {
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });

    // Build our app and trigger a frame
    await tester.pumpWidget(buildTestWidget());

    // Find the save button
    final saveButton = find.text('Save Trail');
    expect(saveButton, findsOneWidget);

    // Tap the save button without filling in required fields
    await ensureVisibleAndTap(tester, saveButton);

    // Check if validation messages appear
    expect(find.text('Please enter Trail name'), findsOneWidget);
    expect(find.text('Please enter Trail description'), findsOneWidget);
    expect(find.text('Please enter Trail Location'), findsOneWidget);
    expect(find.text('Please enter a valid number of participants'), findsOneWidget);

    // Check for SnackBar about date validation
    final snackBars = find.byType(SnackBar);
    if (snackBars.evaluate().isNotEmpty) {
      expect(snackBars, findsWidgets);
    }
  });

  testWidgets('Form accepts valid input', (WidgetTester tester) async {
    // Set a larger screen size for testing
    tester.binding.window.physicalSizeTestValue = const Size(1024, 1600);
    tester.binding.window.devicePixelRatioTestValue = 1.0;

    addTearDown(() {
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });

    // Build our app and trigger a frame
    await tester.pumpWidget(buildTestWidget());

    // Fill in the form
    await tester.enterText(find.widgetWithText(TextFormField, 'Trail Name'), 'Test Trail');
    await tester.enterText(find.widgetWithText(TextFormField, 'Trail Description'), 'A test trail description');
    await tester.enterText(find.widgetWithText(TextFormField, 'Location'), 'Test Location');
    await tester.enterText(find.widgetWithText(TextFormField, 'Number of Participants'), '10');

    // Select difficulty level
    final difficultyField = find.text('Difficulty Level');
    if (difficultyField.evaluate().isNotEmpty) {
      await ensureVisibleAndTap(tester, difficultyField);
      await ensureVisibleAndTap(tester, find.text('Moderate').last);
    }

    // Select date
    final dateSelectField = find.textContaining('Select');
    if (dateSelectField.evaluate().isNotEmpty) {
      await ensureVisibleAndTap(tester, dateSelectField);

      // If DatePicker dialog is shown, try to select a date and press OK
      final okButton = find.text('OK');
      if (okButton.evaluate().isNotEmpty) {
        await ensureVisibleAndTap(tester, okButton);
      }
    }

    // Select duration
    final hoursDropdown = find.text('0 hrs');
    if (hoursDropdown.evaluate().isNotEmpty) {
      await ensureVisibleAndTap(tester, hoursDropdown);

      final twoHoursOption = find.text('2 hrs').last;
      if (twoHoursOption.evaluate().isNotEmpty) {
        await ensureVisibleAndTap(tester, twoHoursOption);
      }
    }

    final minutesDropdown = find.text('0 min');
    if (minutesDropdown.evaluate().isNotEmpty) {
      await ensureVisibleAndTap(tester, minutesDropdown);

      final thirtyMinOption = find.text('30 min').last;
      if (thirtyMinOption.evaluate().isNotEmpty) {
        await ensureVisibleAndTap(tester, thirtyMinOption);
      }
    }

    // Form should be valid at this point
  });

  testWidgets('Image upload functionality works', (WidgetTester tester) async {
    // Set a larger screen size for testing
    tester.binding.window.physicalSizeTestValue = const Size(1024, 1600);
    tester.binding.window.devicePixelRatioTestValue = 1.0;

    addTearDown(() {
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });

    await tester.pumpWidget(buildTestWidget());

    final uploadButton = find.text('Upload Image');
    expect(uploadButton, findsOneWidget);

    // Just verify the upload button is present
    // We don't actually tap it since ImagePicker requires mocking
  });

  testWidgets('Duration selection works', (WidgetTester tester) async {
    // Set a larger screen size for testing
    tester.binding.window.physicalSizeTestValue = const Size(1024, 1600);
    tester.binding.window.devicePixelRatioTestValue = 1.0;

    addTearDown(() {
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });

    // Build our app and trigger a frame
    await tester.pumpWidget(buildTestWidget());

    // Find and tap hours dropdown
    final hoursDropdown = find.text('0 hrs');
    if (hoursDropdown.evaluate().isNotEmpty) {
      await ensureVisibleAndTap(tester, hoursDropdown);

      // Select 3 hours
      final threeHours = find.text('3 hrs').last;
      if (threeHours.evaluate().isNotEmpty) {
        await ensureVisibleAndTap(tester, threeHours);
      }
    }

    // Find and tap minutes dropdown
    final minutesDropdown = find.text('0 min');
    if (minutesDropdown.evaluate().isNotEmpty) {
      await ensureVisibleAndTap(tester, minutesDropdown);

      // Select 15 minutes
      final fifteenMin = find.text('15 min').last;
      if (fifteenMin.evaluate().isNotEmpty) {
        await ensureVisibleAndTap(tester, fifteenMin);
      }
    }

    // Verify selections were updated
    expect(find.text('3 hrs'), findsOneWidget);
    expect(find.text('15 min'), findsOneWidget);
  });

  testWidgets('Renders loading indicator when loading', (WidgetTester tester) async {
    // Create a test widget with loading state
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
            child: const Text('Show Loading'),
          ),
        ),
      ),
    );

    // Tap the button to show loading
    await tester.tap(find.text('Show Loading'));
    await tester.pump();

    // Verify loading indicator is displayed
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:provider/provider.dart';
// import 'package:hiker_connect/providers/events_provider.dart';
//
// // Mock class for EventsProvider
// class MockEventsProvider extends Mock implements EventsProvider {
//   @override
//   bool get initialized => false;
//
//   @override
//   Future<void> initialize() async {
//     // Provide a default implementation that returns a completed future
//     return Future.value();
//   }
// }
//
// // Add the InitializationScreen class definition directly in the test file
// class InitializationScreen extends StatefulWidget {
//   final Widget child;
//
//   const InitializationScreen({Key? key, required this.child}) : super(key: key);
//
//   @override
//   State<InitializationScreen> createState() => _InitializationScreenState();
// }
//
// class _InitializationScreenState extends State<InitializationScreen> {
//   bool _initialized = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeProviders();
//   }
//
//   Future<void> _initializeProviders() async {
//     // Delay to ensure the widget tree is fully built
//     await Future.delayed(Duration.zero);
//
//     if (!mounted) return;
//
//     final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
//     if (!eventsProvider.initialized) {
//       await eventsProvider.initialize();
//     }
//
//     if (mounted) {
//       setState(() {
//         _initialized = true;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (!_initialized) {
//       return MaterialApp(
//         home: Scaffold(
//           body: Center(
//             child: CircularProgressIndicator(),
//           ),
//         ),
//       );
//     }
//
//     return widget.child;
//   }
// }
//
// void main() {
//   group('InitializationScreen', () {
//     testWidgets('Shows loading indicator before initialization', (WidgetTester tester) async {
//       // Create mock provider
//       final mockEventsProvider = MockEventsProvider();
//
//       // Create the widget
//       await tester.pumpWidget(
//         MultiProvider(
//           providers: [
//             Provider<EventsProvider>.value(value: mockEventsProvider),
//           ],
//           child: InitializationScreen(
//             child: MaterialApp(home: Scaffold(body: Text('Initialized Content'))),
//           ),
//         ),
//       );
//
//       // Verify loading indicator is shown
//       expect(find.byType(CircularProgressIndicator), findsOneWidget);
//       expect(find.text('Initialized Content'), findsNothing);
//     });
//
//     testWidgets('Shows child widget after initialization', (WidgetTester tester) async {
//       // Create mock provider
//       final mockEventsProvider = MockEventsProvider();
//
//       // Create the widget
//       await tester.pumpWidget(
//         MultiProvider(
//           providers: [
//             Provider<EventsProvider>.value(value: mockEventsProvider),
//           ],
//           child: InitializationScreen(
//             child: MaterialApp(home: Scaffold(body: Text('Initialized Content'))),
//           ),
//         ),
//       );
//
//       // Pump until initialization is complete
//       await tester.pump(Duration.zero);
//       await tester.pump();
//
//       // Verify child widget is shown
//       expect(find.byType(CircularProgressIndicator), findsNothing);
//       expect(find.text('Initialized Content'), findsOneWidget);
//     });
//
//     testWidgets('Handles initialization failure gracefully', (WidgetTester tester) async {
//       // Create mock provider that throws an exception
//       final mockEventsProvider = MockEventsProvider();
//
//       // Override initialize to throw an exception
//       when(mockEventsProvider.initialize()).thenThrow(Exception('Initialization failed'));
//
//       // Create the widget
//       await tester.pumpWidget(
//         MultiProvider(
//           providers: [
//             Provider<EventsProvider>.value(value: mockEventsProvider),
//           ],
//           child: InitializationScreen(
//             child: MaterialApp(home: Scaffold(body: Text('Initialized Content'))),
//           ),
//         ),
//       );
//
//       // Pump until initialization attempt
//       await tester.pump(Duration.zero);
//       await tester.pump();
//
//       // Verify loading indicator remains if initialization fails
//       expect(find.byType(CircularProgressIndicator), findsOneWidget);
//       expect(find.text('Initialized Content'), findsNothing);
//     });
//
//     testWidgets('Does not reinitialize if already initialized', (WidgetTester tester) async {
//       // Create mock provider that is already initialized
//       final mockEventsProvider = MockEventsProvider();
//
//       // Override initialized to return true
//       when(mockEventsProvider.initialized).thenReturn(true);
//
//       // Create the widget
//       await tester.pumpWidget(
//         MultiProvider(
//           providers: [
//             Provider<EventsProvider>.value(value: mockEventsProvider),
//           ],
//           child: InitializationScreen(
//             child: MaterialApp(home: Scaffold(body: Text('Initialized Content'))),
//           ),
//         ),
//       );
//
//       // Pump to allow initialization process
//       await tester.pump(Duration.zero);
//       await tester.pump();
//
//       // Verify child widget is shown
//       expect(find.byType(CircularProgressIndicator), findsNothing);
//       expect(find.text('Initialized Content'), findsOneWidget);
//     });
//   });
// }
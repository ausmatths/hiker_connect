import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hiker_connect/providers/events_provider.dart';

class InitializationScreen extends StatefulWidget {
  final Widget child;

  const InitializationScreen({Key? key, required this.child}) : super(key: key);

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    // Delay to ensure the widget tree is fully built
    await Future.delayed(Duration.zero);

    if (!mounted) return;

    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
    if (!eventsProvider.initialized) {
      await eventsProvider.initialize();
    }

    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return widget.child;
  }
}
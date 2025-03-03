import 'package:flutter/material.dart';
import 'package:hiker_connect/screens/profile/profile_screen.dart';
import 'package:hiker_connect/screens/trails/trail_list_screen.dart';
import 'package:hiker_connect/screens/trails/events_list_screen.dart';
import 'dart:developer' as developer;

// Import our new EventBrite feed screen
import 'eventbrite_feed_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Update to use our new EventBriteFeedScreen instead of the placeholder
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    developer.log('Initializing HomeScreen with EventBrite feed', name: 'HomeScreen');
    _screens = [
      const EventBriteFeedScreen(),
      const TrailListScreen(),
      const EventsListScreen(),
      const ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      developer.log('Navigation tab changed to index: $index', name: 'HomeScreen');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Feed',
            tooltip: 'Discover hiking events',
          ),
          NavigationDestination(
            icon: Icon(Icons.terrain_outlined),
            selectedIcon: Icon(Icons.terrain),
            label: 'Trail',
            tooltip: 'Browse trails',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Events',
            tooltip: 'My hiking events',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
            tooltip: 'View profile',
          ),
        ],
      ),
    );
  }
}
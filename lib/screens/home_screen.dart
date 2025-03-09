import 'package:flutter/material.dart';
import 'package:hiker_connect/screens/profile/profile_screen.dart';
import 'package:hiker_connect/screens/trails/trail_list_screen.dart';
import 'package:hiker_connect/screens/events/events_browsing_screen.dart';
import 'package:provider/provider.dart';
import 'package:hiker_connect/providers/events_provider.dart';
import 'package:hiker_connect/models/events_view_type.dart';
import 'dart:developer' as developer;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    developer.log('Initializing HomeScreen with Google Events integration', name: 'HomeScreen');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize the events provider if not already initialized
    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
    if (!eventsProvider.initialized) {
      eventsProvider.initialize();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      developer.log('Navigation tab changed to index: $index', name: 'HomeScreen');

      // Refresh events data when navigating to events tab
      if (index == 0 || index == 2) {
        final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
        eventsProvider.refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Initialize screens here instead of initState to avoid constant issues
    if (!_initialized) {
      _screens = [
        // Home/Discover tab - Grid view
        EventsBrowsingScreen(
          initialViewType: EventsViewType.grid,
          showAppBar: false,
          showFAB: false, // Don't show FAB on Discover tab
        ),
        // Trails tab
        const TrailListScreen(),
        // Events tab - List view
        EventsBrowsingScreen(
          initialViewType: EventsViewType.list,
          showFAB: false, // Don't show FAB on Events screen itself
        ),
        // Profile tab
        const ProfileScreen(),
      ];
      _initialized = true;
    }

    // Use a Theme override to customize the bottom navigation appearance
    return Theme(
      data: Theme.of(context).copyWith(
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.7),
          indicatorColor: Theme.of(context).colorScheme.primaryContainer,
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              );
            }
            return const TextStyle(fontSize: 12);
          }),
        ),
      ),
      child: Scaffold(
        extendBody: true, // Makes bottom nav bar transparent
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        // Show FAB on Events tab (index 2) and Trails tab (index 1)
        floatingActionButton: (_selectedIndex == 1 || _selectedIndex == 2)
            ? Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 90, // Increased padding to avoid overlap
          ),
          child: FloatingActionButton(
            heroTag: _selectedIndex == 1 ? 'trailFAB' : 'eventFAB',
            onPressed: () {
              // For Trails tab (index 1), navigate to trail form
              // For Events tab (index 2), navigate to event form
              Navigator.of(context).pushNamed('/event-form');
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            elevation: 4,
            tooltip: _selectedIndex == 1 ? 'Create New Trail' : 'Create New Event',
            child: const Icon(Icons.add),
          ),
        )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          height: 65, // Slightly reduced height
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Discover',
              tooltip: 'Discover hiking events',
            ),
            NavigationDestination(
              icon: Icon(Icons.terrain_outlined),
              selectedIcon: Icon(Icons.terrain),
              label: 'Trails',
              tooltip: 'Browse trails',
            ),
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Events',
              tooltip: 'Browse hiking events',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
              tooltip: 'View profile',
            ),
          ],
        ),
      ),
    );
  }
}
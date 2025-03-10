import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_filter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../widgets/location_picker.dart';

class EventsFilterScreen extends StatefulWidget {
  final EventFilter initialFilter;

  const EventsFilterScreen({
    Key? key,
    required this.initialFilter,
  }) : super(key: key);

  @override
  State<EventsFilterScreen> createState() => _EventsFilterScreenState();
}

class _EventsFilterScreenState extends State<EventsFilterScreen> {
  late EventFilter _currentFilter;
  final TextEditingController _locationController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  final DateFormat _timeFormat = DateFormat('h:mm a');

  // Sample categories - replace with actual data from your database
  final List<String> _categories = [
    'Hiking',
    'Camping',
    'Trail Running',
    'Backpacking',
    'Bird Watching',
    'Photography',
    'Cycling',
    'Cleanup',
    'Educational',
    'Social',
  ];

  // Time periods for filtering
  final List<String> _timePeriods = [
    'Morning',
    'Afternoon',
    'Evening',
    'Any Time'
  ];

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;

    if (_currentFilter.locationQuery != null) {
      _locationController.text = _currentFilter.locationQuery!;
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _currentFilter.startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      // After selecting date, prompt for time
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _currentFilter.startTime ?? TimeOfDay.now(),
      );

      setState(() {
        _currentFilter = _currentFilter.copyWith(startDate: picked);

        if (pickedTime != null) {
          _currentFilter = _currentFilter.copyWith(startTime: pickedTime);
        }

        // If end date is before start date, adjust it
        if (_currentFilter.endDate != null &&
            _currentFilter.endDate!.isBefore(picked)) {
          _currentFilter = _currentFilter.copyWith(
            endDate: picked.add(const Duration(days: 7)),
          );
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _currentFilter.endDate ??
          (_currentFilter.startDate != null ?
          _currentFilter.startDate!.add(const Duration(days: 7)) :
          DateTime.now().add(const Duration(days: 7))),
      firstDate: _currentFilter.startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      // After selecting date, prompt for time
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _currentFilter.endTime ?? TimeOfDay.now(),
      );

      setState(() {
        _currentFilter = _currentFilter.copyWith(endDate: picked);

        if (pickedTime != null) {
          _currentFilter = _currentFilter.copyWith(endTime: pickedTime);
        }
      });
    }
  }

  void _clearDateRange() {
    setState(() {
      _currentFilter = _currentFilter.copyWith(
        startDate: null,
        endDate: null,
        startTime: null,
        endTime: null,
      );
    });
  }

  void _selectTimePeriod(String period) {
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    switch(period) {
      case 'Morning':
        startTime = const TimeOfDay(hour: 6, minute: 0);
        endTime = const TimeOfDay(hour: 12, minute: 0);
        break;
      case 'Afternoon':
        startTime = const TimeOfDay(hour: 12, minute: 0);
        endTime = const TimeOfDay(hour: 17, minute: 0);
        break;
      case 'Evening':
        startTime = const TimeOfDay(hour: 17, minute: 0);
        endTime = const TimeOfDay(hour: 23, minute: 0);
        break;
      case 'Any Time':
        startTime = null;
        endTime = null;
        break;
    }

    setState(() {
      _currentFilter = _currentFilter.copyWith(
        timePeriod: period != 'Any Time' ? period : null,
        startTime: startTime,
        endTime: endTime,
      );
    });
  }

  void _selectLocation(LatLng location, double radius) {
    setState(() {
      _currentFilter = _currentFilter.copyWith(
        searchLocation: location,
        searchRadius: radius,
      );
    });
  }

  void _openLocationPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPicker(
          initialLocation: _currentFilter.searchLocation,
          initialRadius: _currentFilter.searchRadius ?? 10.0,
        ),
      ),
    );

    if (result != null) {
      _selectLocation(
        result['location'] as LatLng,
        result['radius'] as double,
      );
    }
  }

  void _applyFilters() {
    // Update location from text field
    _currentFilter = _currentFilter.copyWith(
      locationQuery: _locationController.text.isEmpty ? null : _locationController.text,
    );

    Navigator.of(context).pop(_currentFilter);
  }

  void _resetFilters() {
    setState(() {
      _currentFilter = EventFilter();
      _locationController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter Events'),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: const Text('Reset'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date range section
              _buildSectionTitle('Date Range'),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectStartDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date & Time',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                        ),
                        child: Text(
                          _currentFilter.startDate != null
                              ? '${_dateFormat.format(_currentFilter.startDate!)} ${_currentFilter.startTime != null ? "@ ${_currentFilter.startTime!.format(context)}" : ""}'
                              : 'Select date & time',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectEndDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date & Time',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                        ),
                        child: Text(
                          _currentFilter.endDate != null
                              ? '${_dateFormat.format(_currentFilter.endDate!)} ${_currentFilter.endTime != null ? "@ ${_currentFilter.endTime!.format(context)}" : ""}'
                              : 'Select date & time',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_currentFilter.startDate != null || _currentFilter.endDate != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _clearDateRange,
                    child: const Text('Clear Dates'),
                  ),
                ),

              const SizedBox(height: 16.0),

              // Time period section
              _buildSectionTitle('Time of Day'),
              const SizedBox(height: 8.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _timePeriods.map((period) {
                  final isSelected = _currentFilter.timePeriod == period ||
                      (period == 'Any Time' && _currentFilter.timePeriod == null);
                  return FilterChip(
                    label: Text(period),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        _selectTimePeriod(period);
                      }
                    },
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  );
                }).toList(),
              ),

              const SizedBox(height: 16.0),

              // Categories section
              _buildSectionTitle('Category'),
              const SizedBox(height: 8.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _categories.map((category) {
                  final isSelected = _currentFilter.category == category;
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _currentFilter = _currentFilter.copyWith(
                          category: selected ? category : null,
                        );
                      });
                    },
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  );
                }).toList(),
              ),

              const SizedBox(height: 16.0),

              // Difficulty level section
              _buildSectionTitle('Difficulty Level'),
              const SizedBox(height: 8.0),
              Slider(
                value: _currentFilter.difficultyLevel?.toDouble() ?? 0,
                min: 0,
                max: 5,
                divisions: 5,
                label: _currentFilter.difficultyLevel != null
                    ? 'Level ${_currentFilter.difficultyLevel}'
                    : 'Any',
                onChanged: (value) {
                  setState(() {
                    _currentFilter = _currentFilter.copyWith(
                      difficultyLevel: value > 0 ? value.round() : null,
                    );
                  });
                },
              ),
              Center(
                child: Text(
                  _currentFilter.difficultyLevel != null
                      ? 'Difficulty: Level ${_currentFilter.difficultyLevel}'
                      : 'Any difficulty level',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),

              const SizedBox(height: 16.0),

              // Location search section
              _buildSectionTitle('Location'),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Search by location',
                        hintText: 'City, park, trail name...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  IconButton(
                    onPressed: _openLocationPicker,
                    icon: const Icon(Icons.map),
                    tooltip: 'Select on map',
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    ),
                  ),
                ],
              ),

              if (_currentFilter.searchLocation != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Chip(
                    label: Text(
                      'Area selected: ${_currentFilter.searchRadius?.toStringAsFixed(1)} km radius',
                    ),
                    onDeleted: () {
                      setState(() {
                        _currentFilter = _currentFilter.copyWith(
                          searchLocation: null,
                          searchRadius: null,
                        );
                      });
                    },
                  ),
                ),

              const SizedBox(height: 16.0),

              // Distance section
              _buildSectionTitle('Maximum Distance'),
              const SizedBox(height: 8.0),
              Slider(
                value: _currentFilter.maxDistance ?? 0,
                min: 0,
                max: 100,
                divisions: 10,
                label: _currentFilter.maxDistance != null
                    ? '${_currentFilter.maxDistance!.round()} km'
                    : 'Any',
                onChanged: (value) {
                  setState(() {
                    _currentFilter = _currentFilter.copyWith(
                      maxDistance: value > 0 ? value : null,
                    );
                  });
                },
              ),
              Center(
                child: Text(
                  _currentFilter.maxDistance != null
                      ? 'Within ${_currentFilter.maxDistance!.round()} km'
                      : 'Any distance',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),

              const SizedBox(height: 16.0),

              // Additional filters
              SwitchListTile(
                title: const Text('Show only favorites'),
                value: _currentFilter.showOnlyFavorites,
                onChanged: (value) {
                  setState(() {
                    _currentFilter = _currentFilter.copyWith(
                      showOnlyFavorites: value,
                    );
                  });
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),

              SwitchListTile(
                title: const Text('Include Google events'),
                value: _currentFilter.includeGoogleEvents,
                onChanged: (value) {
                  setState(() {
                    _currentFilter = _currentFilter.copyWith(
                      includeGoogleEvents: value,
                    );
                  });
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),

              SwitchListTile(
                title: const Text('Include past events'),
                value: _currentFilter.includePastEvents,
                onChanged: (value) {
                  setState(() {
                    _currentFilter = _currentFilter.copyWith(
                      includePastEvents: value,
                    );
                  });
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),

              const SizedBox(height: 24.0),

              // Apply button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium!.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
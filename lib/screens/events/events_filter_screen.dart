import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_filter.dart';

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
      setState(() {
        _currentFilter = _currentFilter.copyWith(startDate: picked);

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
      setState(() {
        _currentFilter = _currentFilter.copyWith(endDate: picked);
      });
    }
  }

  void _clearDateRange() {
    setState(() {
      _currentFilter = _currentFilter.copyWith(
        startDate: null,
        endDate: null,
      );
    });
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
                          labelText: 'Start Date',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                        ),
                        child: Text(
                          _currentFilter.startDate != null
                              ? _dateFormat.format(_currentFilter.startDate!)
                              : 'Select date',
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
                          labelText: 'End Date',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                        ),
                        child: Text(
                          _currentFilter.endDate != null
                              ? _dateFormat.format(_currentFilter.endDate!)
                              : 'Select date',
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
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Search by location',
                  hintText: 'City, park, trail name...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined),
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

              // Favorites only section
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
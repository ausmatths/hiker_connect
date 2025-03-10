import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Create a simple test widget that mimics features of your EditProfileScreen
// but doesn't require Firebase initialization
class SimpleProfileWidget extends StatefulWidget {
  final String initialName;
  final Function(String) onSave;

  const SimpleProfileWidget({
    Key? key,
    required this.initialName,
    required this.onSave,
  }) : super(key: key);

  @override
  State<SimpleProfileWidget> createState() => _SimpleProfileWidgetState();
}

class _SimpleProfileWidgetState extends State<SimpleProfileWidget> {
  late TextEditingController _nameController;
  String? _selectedGender;
  final List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];
  final List<String> _selectedInterests = [];
  final List<String> _availableInterests = [
    'Mountain Climbing', 'Trail Running', 'Hiking', 'Camping'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              widget.onSave(_nameController.text);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Display Name'),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Enter your name',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Gender'),
            DropdownButton<String>(
              hint: const Text('Select gender'),
              value: _selectedGender,
              items: _genderOptions.map((gender) {
                return DropdownMenuItem(
                  value: gender,
                  child: Text(gender),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text('Interests'),
            Wrap(
              spacing: 8,
              children: _availableInterests.map((interest) {
                final isSelected = _selectedInterests.contains(interest);
                return FilterChip(
                  label: Text(interest),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedInterests.add(interest);
                      } else {
                        _selectedInterests.remove(interest);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  group('SimpleProfileWidget Tests', () {
    testWidgets('renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SimpleProfileWidget(
          initialName: 'Test User',
          onSave: (_) {},
        ),
      ));

      // Check if title is rendered
      expect(find.text('Edit Profile'), findsOneWidget);

      // Check if name field is rendered with correct initial value
      expect(find.text('Display Name'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);

      // Check if gender dropdown is rendered
      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Select gender'), findsOneWidget);

      // Check if interests section is rendered
      expect(find.text('Interests'), findsOneWidget);
      expect(find.text('Hiking'), findsOneWidget);
      expect(find.text('Camping'), findsOneWidget);
    });

    testWidgets('can edit name and save', (WidgetTester tester) async {
      String? savedName;

      await tester.pumpWidget(MaterialApp(
        home: SimpleProfileWidget(
          initialName: 'Test User',
          onSave: (name) {
            savedName = name;
          },
        ),
      ));

      // Edit the name
      await tester.enterText(find.byType(TextField), 'New Name');

      // Tap save button
      await tester.tap(find.byIcon(Icons.save));
      await tester.pump();

      // Verify save callback was called with new name
      expect(savedName, 'New Name');
    });

    testWidgets('can select interest chips', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SimpleProfileWidget(
          initialName: 'Test User',
          onSave: (_) {},
        ),
      ));

      // Initially no interests are selected
      final hikingChip = find.widgetWithText(FilterChip, 'Hiking');
      FilterChip chip = tester.widget(hikingChip) as FilterChip;
      expect(chip.selected, false);

      // Select Hiking
      await tester.tap(hikingChip);
      await tester.pump();

      // Verify Hiking is now selected
      chip = tester.widget(hikingChip) as FilterChip;
      expect(chip.selected, true);

      // Deselect Hiking
      await tester.tap(hikingChip);
      await tester.pump();

      // Verify Hiking is now deselected
      chip = tester.widget(hikingChip) as FilterChip;
      expect(chip.selected, false);
    });
  });
}
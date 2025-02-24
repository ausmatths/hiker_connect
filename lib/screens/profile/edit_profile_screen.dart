import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hiker_connect/services/firebase_auth.dart';
import 'package:hiker_connect/models/user_model.dart';
import 'package:hiker_connect/utils/async_context_handler.dart';
import 'package:hiker_connect/utils/logger.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // Basic Info Controllers
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  DateTime? _selectedDateOfBirth;
  String? _selectedGender;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _languageController;

  // Medical Info Controllers
  late TextEditingController _bloodTypeController;
  late TextEditingController _allergiesController;
  late TextEditingController _insuranceInfoController;


  // Interests
  bool _isLoading = false;
  String _errorMessage = '';

  List<String> _medicalConditions = [];
  List<String> _medications = [];
  List<EmergencyContact> _emergencyContacts = [];
  List<String> _selectedInterests = [];
  Map<String, TextEditingController> _socialLinksControllers = {};

  final List<String> _availableInterests = [
    'Mountain Climbing',
    'Trail Running',
    'Hiking',
    'Camping',
    'Bird Watching',
    'Nature Photography',
    'Rock Climbing',
    'Backpacking'
  ];

  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say'
  ];

  final List<String> _availableSocialPlatforms = [
    'Facebook',
    'Instagram',
    'Twitter',
    'LinkedIn'
  ];

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('User data in initState: ${widget.user.toMap()}');
    }

    try {
      if (kDebugMode) {
        print('Initializing controllers...');
      }
      _initializeControllers();
      if (kDebugMode) {
        print('Controllers initialized successfully');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error initializing controllers: $e');
      }
      if (kDebugMode) {
        print('Stack trace: $stackTrace');
      }
    }
  }

  void _initializeControllers() {
    try {
      if (kDebugMode) {
        print('Initializing with user data: ${widget.user.toMap()}');
      }

      // Basic Info with null safety
      _displayNameController = TextEditingController(text: widget.user.displayName);
      _bioController = TextEditingController(text: widget.user.bio ?? '');
      _phoneController = TextEditingController(text: widget.user.phoneNumber ?? '');
      _addressController = TextEditingController(text: widget.user.location?.address ?? '');
      _heightController = TextEditingController(text: widget.user.height?.toString() ?? '');
      _weightController = TextEditingController(text: widget.user.weight?.toString() ?? '');
      _languageController = TextEditingController(text: widget.user.preferredLanguage ?? '');

      // Medical Info with null safety
      _bloodTypeController = TextEditingController(text: widget.user.bloodType ?? '');
      _allergiesController = TextEditingController(text: widget.user.allergies ?? '');
      _insuranceInfoController = TextEditingController(text: widget.user.insuranceInfo ?? '');

      // Initialize lists with empty defaults if null
      _medicalConditions = widget.user.medicalConditions ?? [];
      _medications = widget.user.medications ?? [];
      _emergencyContacts = widget.user.emergencyContacts ?? [];
      _selectedInterests = widget.user.interests ?? [];

      // Initialize other fields with null safety
      _selectedGender = widget.user.gender;
      _selectedDateOfBirth = widget.user.dateOfBirth;

      // Initialize social links controllers with empty map if null
      _socialLinksControllers = {};
      for (final platform in _availableSocialPlatforms) {
        _socialLinksControllers[platform] = TextEditingController(
            text: widget.user.socialLinks?[platform] ?? ''
        );
      }

      if (kDebugMode) {
        print('Controllers initialized successfully');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in _initializeControllers: $e');
      }
      if (kDebugMode) {
        print('Stack trace: $stackTrace');
      }
      // Re-initialize with defaults if there's an error
      _initializeWithDefaults();
    }
  }

// Fallback initialization with defaults
  void _initializeWithDefaults() {
    _displayNameController = TextEditingController(text: '');
    _bioController = TextEditingController(text: '');
    _phoneController = TextEditingController(text: '');
    _addressController = TextEditingController(text: '');
    _heightController = TextEditingController(text: '');
    _weightController = TextEditingController(text: '');
    _languageController = TextEditingController(text: '');
    _bloodTypeController = TextEditingController(text: '');
    _allergiesController = TextEditingController(text: '');
    _insuranceInfoController = TextEditingController(text: '');

    _medicalConditions = [];
    _medications = [];
    _emergencyContacts = [];
    _selectedInterests = [];

    _socialLinksControllers = Map.fromEntries(
        _availableSocialPlatforms.map((platform) => MapEntry(
            platform,
            TextEditingController(text: '')
        ))
    );
  }

  @override
  void dispose() {
    // Dispose all controllers
    _displayNameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _languageController.dispose();
    _bloodTypeController.dispose();
    _allergiesController.dispose();
    _insuranceInfoController.dispose();

    // Dispose social links controllers
    for (var controller in _socialLinksControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    AsyncContextHandler.safeAsyncOperation(
      context,
          () async {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });

        await _authService.updateUserProfile(
          displayName: _displayNameController.text,
          bio: _bioController.text,
          interests: _selectedInterests,
          phoneNumber: _phoneController.text,
          location: _addressController.text.isEmpty ? null : UserLocation(
            geoPoint: widget.user.location?.geoPoint ?? const GeoPoint(0, 0),
            address: _addressController.text,
          ),
          dateOfBirth: _selectedDateOfBirth,
          gender: _selectedGender,
          height: _heightController.text.isEmpty ? null : double.tryParse(_heightController.text),
          weight: _weightController.text.isEmpty ? null : double.tryParse(_weightController.text),
          preferredLanguage: _languageController.text,
          bloodType: _bloodTypeController.text,
          allergies: _allergiesController.text,
          insuranceInfo: _insuranceInfoController.text,
          medicalConditions: _medicalConditions,
          medications: _medications,
          emergencyContacts: _emergencyContacts,
          socialLinks: Map.fromEntries(
              _socialLinksControllers.entries
                  .where((e) => e.value.text.isNotEmpty)
                  .map((e) => MapEntry(e.key, e.value.text))
          ),
        );

        AppLogger.info('Profile updated successfully');
      },
      onSuccess: () {
        Navigator.pop(context, true);
      },
      onError: (error) {
        // Updated error logging to match the new AppLogger implementation
        AppLogger.error('Error saving profile: ${error.toString()}');
        setState(() => _errorMessage = error.toString());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Edit Profile', style: TextStyle(color: Colors.black)),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.save_outlined, color: Colors.black),
                  onPressed: _isLoading ? null : _saveProfile,
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Basic'),
                  Tab(text: 'Medical'),
                  Tab(text: 'Emergency'),
                  Tab(text: 'Social'),
                ],
                labelColor: Colors.black,
                indicatorColor: Colors.deepPurple,
              ),
            ),
            body: Form(
              key: _formKey,
              child: TabBarView(
                children: [
                  _buildBasicInfoTab(),
                  _buildMedicalInfoTab(),
                  _buildEmergencyContactsTab(),
                  _buildSocialLinksTab(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Display Name'),
          _buildTextField(
            controller: _displayNameController,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Please enter your display name';
              return null;
            },
          ),
          const SizedBox(height: 24),

          _buildLabel('Bio'),
          _buildTextField(
            controller: _bioController,
            maxLines: 4,
            hintText: "I'm a adventurer 👟⛰️🏃",
          ),
          const SizedBox(height: 24),

          _buildLabel('Date of Birth'),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDateOfBirth ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _selectedDateOfBirth = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedDateOfBirth != null
                        ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                        : 'Select date',
                    style: TextStyle(
                      color: _selectedDateOfBirth != null
                          ? Colors.black
                          : Colors.grey.shade600,
                    ),
                  ),
                  const Icon(Icons.calendar_today),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          _buildLabel('Gender'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedGender,
                hint: const Text('Select gender'),
                items: _genderOptions.map((String gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() => _selectedGender = value);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          _buildLabel('Interests'),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: _availableInterests.map((interest) {
              final isSelected = _selectedInterests.contains(interest);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedInterests.remove(interest);
                    } else {
                      _selectedInterests.add(interest);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.deepPurple.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? Colors.deepPurple.shade100
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        Icon(
                          Icons.check,
                          size: 18,
                          color: Colors.deepPurple.shade400,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        interest,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.deepPurple.shade400
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Blood Type'),
          _buildTextField(
            controller: _bloodTypeController,
            hintText: 'e.g., A+, B-, O+',
          ),
          const SizedBox(height: 24),

          _buildLabel('Allergies'),
          _buildTextField(
            controller: _allergiesController,
            maxLines: 3,
            hintText: 'List any allergies...',
          ),
          const SizedBox(height: 24),

          _buildLabel('Medical Conditions'),
          _buildChipList(
            items: _medicalConditions,
            onAdd: (condition) {
              setState(() => _medicalConditions.add(condition));
            },
            onRemove: (condition) {
              setState(() => _medicalConditions.remove(condition));
            },
            hintText: 'Add medical condition',
          ),
          const SizedBox(height: 24),

          _buildLabel('Medications'),
          _buildChipList(
            items: _medications,
            onAdd: (medication) {
              setState(() => _medications.add(medication));
            },
            onRemove: (medication) {
              setState(() => _medications.remove(medication));
            },
            hintText: 'Add medication',
          ),
          const SizedBox(height: 24),

          _buildLabel('Insurance Information'),
          _buildTextField(
            controller: _insuranceInfoController,
            maxLines: 3,
            hintText: 'Enter insurance details...',
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _emergencyContacts.length + 1,
      itemBuilder: (context, index) {
        if (index == _emergencyContacts.length) {
          return TextButton.icon(
            onPressed: () => _showAddEmergencyContactDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Emergency Contact'),
          );
        }

        final contact = _emergencyContacts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            title: Text(contact.name),
            subtitle: Text('${contact.relationship}\n${contact.phoneNumber}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                setState(() => _emergencyContacts.removeAt(index));
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSocialLinksTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _availableSocialPlatforms.map((platform) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(platform),
            _buildTextField(
              controller: _socialLinksControllers[platform]!,
              hintText: 'Enter your $platform profile URL',
              prefixIcon: const Icon(Icons.link),
            ),
            const SizedBox(height: 24),
          ],
        );
      }).toList(),
    );
  }

  // Helper methods
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hintText,
    int maxLines = 1,
    Widget? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          prefixIcon: prefixIcon,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildChipList({
    required List<String> items,
    required Function(String) onAdd,
    required Function(String) onRemove,
    required String hintText,
  }) {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            return Chip(
              label: Text(item),
              onDeleted: () => onRemove(item),
              backgroundColor: Colors.deepPurple.shade50,
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _showAddItemDialog(
            title: hintText,
            onAdd: onAdd,
          ),
          icon: const Icon(Icons.add),
          label: Text(hintText),
        ),
      ],
    );
  }

  Future<void> _showAddItemDialog({
    required String title,
    required Function(String) onAdd,
  }) async {
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter item',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onAdd(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddEmergencyContactDialog() async {
    final nameController = TextEditingController();
    final relationshipController = TextEditingController();
    final phoneController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
            ),
            TextField(
              controller: relationshipController,
              decoration: const InputDecoration(
                labelText: 'Relationship',
              ),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  relationshipController.text.isNotEmpty &&
                  phoneController.text.isNotEmpty) {
                setState(() {
                  _emergencyContacts.add(EmergencyContact(
                    name: nameController.text.trim(),
                    relationship: relationshipController.text.trim(),
                    phoneNumber: phoneController.text.trim(),
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
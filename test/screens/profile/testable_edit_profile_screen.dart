import 'package:flutter/material.dart';
import 'package:hiker_connect/models/user_model.dart';
import 'package:hiker_connect/services/firebase_auth.dart';

/// A completely testable version of EditProfileScreen
/// This class removes Firebase dependencies for testing purposes
class TestableEditProfileScreen extends StatefulWidget {
  final UserModel user;
  final AuthService authService;

  const TestableEditProfileScreen({
    Key? key,
    required this.user,
    required this.authService,
  }) : super(key: key);

  @override
  State<TestableEditProfileScreen> createState() => _TestableEditProfileScreenState();
}

class _TestableEditProfileScreenState extends State<TestableEditProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  // User data fields
  late String _displayName;
  late String? _bio;
  late List<String> _interests;
  late String? _phoneNumber;
  late UserLocation? _location;
  late DateTime? _dateOfBirth;
  late String? _gender;
  late double? _height;
  late double? _weight;
  late String? _preferredLanguage;
  late String? _bloodType;
  late String? _allergies;
  late String? _insuranceInfo;
  late List<String> _medicalConditions;
  late List<String> _medications;
  late List<EmergencyContact> _emergencyContacts;
  late Map<String, String> _socialLinks;

  // Available options
  final List<String> _availableInterests = [
    'Hiking',
    'Mountain Climbing',
    'Trail Running',
    'Camping',
    'Backpacking',
    'Nature Photography'
  ];

  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Other',
    'Prefer not to say'
  ];

  final List<String> _bloodTypeOptions = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  final List<String> _languageOptions = [
    'English', 'Spanish', 'French', 'German', 'Chinese', 'Japanese', 'Other'
  ];

  final List<String> _socialPlatforms = [
    'Instagram', 'Twitter', 'Facebook', 'LinkedIn', 'Strava'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initUserData();
  }

  void _initUserData() {
    // Initialize all fields from the user model
    final user = widget.user;
    _displayName = user.displayName;
    _bio = user.bio;
    _interests = List<String>.from(user.interests ?? []);
    _phoneNumber = user.phoneNumber;
    _location = user.location;
    _dateOfBirth = user.dateOfBirth;
    _gender = user.gender;
    _height = user.height;
    _weight = user.weight;
    _preferredLanguage = user.preferredLanguage;
    _bloodType = user.bloodType;
    _allergies = user.allergies;
    _insuranceInfo = user.insuranceInfo;
    _medicalConditions = List<String>.from(user.medicalConditions ?? []);
    _medications = List<String>.from(user.medications ?? []);
    _emergencyContacts = List<EmergencyContact>.from(user.emergencyContacts ?? []);
    _socialLinks = Map<String, String>.from(user.socialLinks ?? {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      await widget.authService.updateUserProfile(
        displayName: _displayName,
        bio: _bio,
        interests: _interests,
        phoneNumber: _phoneNumber,
        location: _location,
        dateOfBirth: _dateOfBirth,
        gender: _gender,
        height: _height,
        weight: _weight,
        preferredLanguage: _preferredLanguage,
        bloodType: _bloodType,
        allergies: _allergies,
        insuranceInfo: _insuranceInfo,
        medicalConditions: _medicalConditions,
        medications: _medications,
        emergencyContacts: _emergencyContacts,
        socialLinks: _socialLinks,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to update profile: ${e.toString()}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage ?? 'An error occurred')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            key: const Key('save_button'),
            icon: const Icon(Icons.save_outlined),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Basic'),
            Tab(text: 'Medical'),
            Tab(text: 'Emergency'),
            Tab(text: 'Social'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBasicInfoTab(),
            _buildMedicalTab(),
            _buildEmergencyTab(),
            _buildSocialTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            key: const Key('display_name_field'),
            initialValue: _displayName,
            decoration: const InputDecoration(
              labelText: 'Display Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your display name';
              }
              return null;
            },
            onSaved: (value) {
              _displayName = value!;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('bio_field'),
            initialValue: _bio,
            decoration: const InputDecoration(
              labelText: 'Bio',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onSaved: (value) {
              _bio = value;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('phone_field'),
            initialValue: _phoneNumber,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            onSaved: (value) {
              _phoneNumber = value;
            },
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _selectDate(context),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date of Birth',
                border: OutlineInputBorder(),
              ),
              child: Text(
                _dateOfBirth != null
                    ? '${_dateOfBirth!.month}/${_dateOfBirth!.day}/${_dateOfBirth!.year}'
                    : 'Select date',
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Gender',
              border: OutlineInputBorder(),
            ),
            value: _gender,
            items: _genderOptions.map((String gender) {
              return DropdownMenuItem<String>(
                value: gender,
                child: Text(gender),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _gender = newValue;
              });
            },
            onSaved: (value) {
              _gender = value;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('height_field'),
            initialValue: _height?.toString() ?? '',
            decoration: const InputDecoration(
              labelText: 'Height (cm)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onSaved: (value) {
              _height = value != null && value.isNotEmpty
                  ? double.tryParse(value)
                  : null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('weight_field'),
            initialValue: _weight?.toString() ?? '',
            decoration: const InputDecoration(
              labelText: 'Weight (kg)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onSaved: (value) {
              _weight = value != null && value.isNotEmpty
                  ? double.tryParse(value)
                  : null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Preferred Language',
              border: OutlineInputBorder(),
            ),
            value: _preferredLanguage,
            items: _languageOptions.map((String language) {
              return DropdownMenuItem<String>(
                value: language,
                child: Text(language),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _preferredLanguage = newValue;
              });
            },
            onSaved: (value) {
              _preferredLanguage = value;
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Interests',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _availableInterests.map((interest) {
              final isSelected = _interests.contains(interest);
              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _interests.remove(interest);
                    } else {
                      _interests.add(interest);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        interest,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                      if (isSelected)
                        const Padding(
                          padding: EdgeInsets.only(left: 4.0),
                          child: Icon(
                            Icons.check,
                            size: 16.0,
                            color: Colors.white,
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

  Widget _buildMedicalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Blood Type',
              border: OutlineInputBorder(),
            ),
            value: _bloodType,
            items: _bloodTypeOptions.map((String bloodType) {
              return DropdownMenuItem<String>(
                value: bloodType,
                child: Text(bloodType),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _bloodType = newValue;
              });
            },
            onSaved: (value) {
              _bloodType = value;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _allergies,
            decoration: const InputDecoration(
              labelText: 'Allergies',
              border: OutlineInputBorder(),
            ),
            onSaved: (value) {
              _allergies = value;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _insuranceInfo,
            decoration: const InputDecoration(
              labelText: 'Insurance Information',
              border: OutlineInputBorder(),
            ),
            onSaved: (value) {
              _insuranceInfo = value;
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Medical Conditions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: [
              ..._medicalConditions.map((condition) {
                return Chip(
                  label: Text(condition),
                  deleteIcon: const Icon(Icons.cancel),
                  onDeleted: () {
                    setState(() {
                      _medicalConditions.remove(condition);
                    });
                  },
                );
              }).toList(),
              ActionChip(
                avatar: const Icon(Icons.add),
                label: const Text('Add medical condition'),
                onPressed: () => _addMedicalCondition(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Medications',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: [
              ..._medications.map((medication) {
                return Chip(
                  label: Text(medication),
                  deleteIcon: const Icon(Icons.cancel),
                  onDeleted: () {
                    setState(() {
                      _medications.remove(medication);
                    });
                  },
                );
              }).toList(),
              ActionChip(
                avatar: const Icon(Icons.add),
                label: const Text('Add medication'),
                onPressed: () => _addMedication(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Emergency Contacts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._emergencyContacts.map((contact) {
            return Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          contact.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              _emergencyContacts.remove(contact);
                            });
                          },
                        ),
                      ],
                    ),
                    Text(contact.relationship),
                    Text(contact.phoneNumber),
                  ],
                ),
              ),
            );
          }).toList(),
          if (_emergencyContacts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text('No emergency contacts added yet'),
            ),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Emergency Contact'),
            onPressed: () => _addEmergencyContact(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Social Media Links',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._socialPlatforms.map((platform) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: TextFormField(
                initialValue: _socialLinks[platform] ?? '',
                decoration: InputDecoration(
                  labelText: platform,
                  hintText: 'Username',
                  border: const OutlineInputBorder(),
                  prefixIcon: _getIconForPlatform(platform),
                ),
                onSaved: (value) {
                  if (value != null && value.isNotEmpty) {
                    _socialLinks[platform] = value;
                  } else {
                    _socialLinks.remove(platform);
                  }
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  Future<void> _addMedicalCondition(BuildContext context) async {
    String? newCondition;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Medical Condition'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter condition',
            ),
            onChanged: (value) {
              newCondition = value;
            },
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );

    if (newCondition != null && newCondition!.isNotEmpty) {
      setState(() {
        _medicalConditions.add(newCondition!);
      });
    }
  }

  Future<void> _addMedication(BuildContext context) async {
    String? newMedication;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Medication'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter medication',
            ),
            onChanged: (value) {
              newMedication = value;
            },
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );

    if (newMedication != null && newMedication!.isNotEmpty) {
      setState(() {
        _medications.add(newMedication!);
      });
    }
  }

  Future<void> _addEmergencyContact(BuildContext context) async {
    String? name;
    String? relationship;
    String? phoneNumber;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Emergency Contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Name',
                ),
                onChanged: (value) {
                  name = value;
                },
              ),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Relationship',
                ),
                onChanged: (value) {
                  relationship = value;
                },
              ),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                ),
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  phoneNumber = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );

    if (name != null && name!.isNotEmpty &&
        relationship != null && relationship!.isNotEmpty &&
        phoneNumber != null && phoneNumber!.isNotEmpty) {
      setState(() {
        _emergencyContacts.add(
          EmergencyContact(
            name: name!,
            relationship: relationship!,
            phoneNumber: phoneNumber!,
          ),
        );
      });
    }
  }

  Icon? _getIconForPlatform(String platform) {
    switch (platform) {
      case 'Instagram':
        return const Icon(Icons.camera_alt);
      case 'Twitter':
        return const Icon(Icons.chat);
      case 'Facebook':
        return const Icon(Icons.facebook);
      case 'LinkedIn':
        return const Icon(Icons.work);
      case 'Strava':
        return const Icon(Icons.directions_run);
      default:
        return const Icon(Icons.link);
    }
  }
}
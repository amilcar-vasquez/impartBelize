import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/application_service.dart';
import '../../widgets/education_form_widget.dart';
import '../../widgets/document_upload_widget.dart';

class TeacherApplicationScreen extends StatefulWidget {
  const TeacherApplicationScreen({super.key});

  @override
  State<TeacherApplicationScreen> createState() =>
      _TeacherApplicationScreenState();
}

class _TeacherApplicationScreenState extends State<TeacherApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _applicationService = ApplicationService();

  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ssnController = TextEditingController();
  final _addressController = TextEditingController();

  // Form state
  String? _selectedGender;
  String? _selectedMaritalStatus;
  int? _selectedDistrictId;
  DateTime? _dateOfBirth;
  bool _isSubmitting = false;

  // Education and Documents
  List<Map<String, dynamic>> _educationList = [];
  List<Map<String, dynamic>> _documentList = [];

  // Options
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _maritalStatusOptions = [
    'Single',
    'Married',
    'Divorced',
    'Widowed',
  ];

  // Mock districts - In production, fetch from API
  final List<Map<String, dynamic>> _districts = [
    {'id': 1, 'name': 'Belize District'},
    {'id': 2, 'name': 'Cayo District'},
    {'id': 3, 'name': 'Corozal District'},
    {'id': 4, 'name': 'Orange Walk District'},
    {'id': 5, 'name': 'Stann Creek District'},
    {'id': 6, 'name': 'Toledo District'},
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ssnController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      helpText: 'Select Date of Birth',
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields correctly'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate that at least one education record is provided
    if (_educationList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one education record'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Step 1: Create teacher profile
      String? dobString;
      if (_dateOfBirth != null) {
        dobString = DateFormat('yyyy-MM-dd').format(_dateOfBirth!);
      }

      final teacherData = <String, dynamic>{
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
      };

      if (_phoneController.text.trim().isNotEmpty) {
        teacherData['phone'] = _phoneController.text.trim();
      }
      if (_selectedGender != null) {
        teacherData['gender'] = _selectedGender;
      }
      if (dobString != null) {
        teacherData['dob'] = dobString;
      }
      if (_ssnController.text.trim().isNotEmpty) {
        teacherData['ssn'] = _ssnController.text.trim();
      }
      if (_selectedMaritalStatus != null) {
        teacherData['marital_status'] = _selectedMaritalStatus;
      }
      if (_addressController.text.trim().isNotEmpty) {
        teacherData['address'] = _addressController.text.trim();
      }
      if (_selectedDistrictId != null) {
        teacherData['district_id'] = _selectedDistrictId;
      }

      teacherData['profile_status'] = 'pending';

      final teacher = await _apiService.createTeacher(teacherData);
      final teacherId = teacher.id;

      // Step 2: Create education records
      for (var education in _educationList) {
        education['teacher_id'] = teacherId;
        await _applicationService.createEducation(education);
      }

      // Step 3: Upload documents and create document records
      for (var document in _documentList) {
        // Mock upload to Supabase (simulate uploading the file)
        final mockFilePath = document['file_path'];
        final fileName = mockFilePath.split('/').last;

        // In production, this would upload the actual file
        final uploadedUrl = await _applicationService.uploadFileToSupabase(
          mockFilePath,
          'teacher-documents',
          '${teacherId}_$fileName',
        );

        // Create document record with the uploaded URL
        final documentData = {
          'teacher_id': teacherId,
          'doc_type': document['doc_type'],
          'file_path': uploadedUrl,
          if (document['remarks'] != null) 'remarks': document['remarks'],
        };

        await _applicationService.createDocument(documentData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('License application submitted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Clear form
        _formKey.currentState!.reset();
        _firstNameController.clear();
        _lastNameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _ssnController.clear();
        _addressController.clear();
        setState(() {
          _selectedGender = null;
          _selectedMaritalStatus = null;
          _selectedDistrictId = null;
          _dateOfBirth = null;
          _educationList = [];
          _documentList = [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting application: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher License Application'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.school,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Teacher License Application',
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please fill in all required information to apply for your teaching license',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Personal Information Section
                  Text(
                    'Personal Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'First Name *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'First name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Last Name *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Last name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedGender,
                            decoration: const InputDecoration(
                              labelText: 'Gender',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.wc),
                            ),
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
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date of Birth',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _dateOfBirth == null
                                    ? 'Select date'
                                    : DateFormat(
                                        'MMM dd, yyyy',
                                      ).format(_dateOfBirth!),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _ssnController,
                            decoration: const InputDecoration(
                              labelText: 'Social Security Number',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.badge),
                              hintText: '000-00-0000',
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9-]'),
                              ),
                              LengthLimitingTextInputFormatter(11),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedMaritalStatus,
                            decoration: const InputDecoration(
                              labelText: 'Marital Status',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.family_restroom),
                            ),
                            items: _maritalStatusOptions.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedMaritalStatus = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Contact Information Section
                  Text(
                    'Contact Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email Address *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email),
                              hintText: 'example@email.com',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                              hintText: '000-0000',
                            ),
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9-]'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: 'Address',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.home),
                              hintText: 'Street, City, Country',
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            value: _selectedDistrictId,
                            decoration: const InputDecoration(
                              labelText: 'District',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                            ),
                            items: _districts.map((district) {
                              return DropdownMenuItem<int>(
                                value: district['id'] as int,
                                child: Text(district['name'] as String),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedDistrictId = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Education Section
                  Text(
                    'Education',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  EducationFormWidget(
                    educationList: _educationList,
                    onAdd: (education) {
                      setState(() {
                        _educationList.add(education);
                      });
                    },
                    onRemove: (index) {
                      setState(() {
                        _educationList.removeAt(index);
                      });
                    },
                  ),
                  const SizedBox(height: 32),

                  // Documents Section
                  Text(
                    'Supporting Documents',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload required documents such as diplomas, certificates, ID, etc.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DocumentUploadWidget(
                    documentList: _documentList,
                    onAdd: (document) {
                      setState(() {
                        _documentList.add(document);
                      });
                    },
                    onRemove: (index) {
                      setState(() {
                        _documentList.removeAt(index);
                      });
                    },
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submitApplication,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(
                      _isSubmitting ? 'Submitting...' : 'Submit Application',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Helper text
                  Text(
                    '* Required fields',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

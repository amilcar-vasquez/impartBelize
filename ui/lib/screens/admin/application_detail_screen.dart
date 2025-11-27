import 'package:flutter/material.dart';
import '../../models/application.dart';
import '../../models/teacher.dart';
import '../../models/education.dart';
import '../../models/qualification.dart';
import '../../models/document.dart';
import '../../services/api_service.dart';
import '../../services/application_service.dart';
import 'package:intl/intl.dart';

class ApplicationDetailScreen extends StatefulWidget {
  final int applicationId;
  final int teacherId;

  const ApplicationDetailScreen({
    super.key,
    required this.applicationId,
    required this.teacherId,
  });

  @override
  State<ApplicationDetailScreen> createState() =>
      _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  final ApplicationService _applicationService = ApplicationService();
  final ApiService _apiService = ApiService();

  Application? _application;
  Teacher? _teacher;
  List<Education> _education = [];
  List<Qualification> _qualifications = [];
  List<Document> _documents = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);

    try {
      // Fetch all application and teacher-related data
      final teachers = await _apiService.fetchTeachers();
      final teacher = teachers.firstWhere((t) => t.id == widget.teacherId);

      final applications = await _applicationService.getApplicationsByTeacher(
        widget.teacherId,
      );
      final application = applications.firstWhere(
        (app) => app['application_id'] == widget.applicationId,
      );

      final education = await _applicationService.getEducationByTeacher(
        widget.teacherId,
      );
      final qualifications = await _applicationService
          .getQualificationsByTeacher(widget.teacherId);
      final documents = await _applicationService.getDocumentsByTeacher(
        widget.teacherId,
      );

      setState(() {
        _teacher = teacher;
        _application = Application.fromJson(application);
        _education = education;
        _qualifications = qualifications;
        _documents = documents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading details: $e')));
      }
    }
  }

  Future<void> _approveApplication() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Application'),
        content: const Text(
          'Are you sure you want to approve this application? This will also approve the teacher profile and verify all documents.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      // 1. Update application status to approved
      await _applicationService.updateApplication(widget.applicationId, {
        'status': 'approved',
      });

      // 2. Update teacher profile status to approved
      await _apiService.updateTeacher(widget.teacherId, {
        'profile_status': 'approved',
      });

      // 3. Mark all documents as verified
      for (final document in _documents) {
        if (document.id != null) {
          await _applicationService.updateDocument(document.id!, {
            'verified': true,
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Application, teacher profile, and documents approved successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate update
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving application: $e')),
        );
      }
    }
  }

  Future<void> _rejectApplication() async {
    final TextEditingController reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Application'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a reason for rejection:'),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a reason';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      reasonController.dispose();
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await _applicationService.updateApplication(widget.applicationId, {
        'status': 'rejected',
        'rejection_reason': reasonController.text.trim(),
      });

      reasonController.dispose();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application rejected'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate update
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      reasonController.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting application: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'under_review':
        return Colors.blue;
      case 'incomplete':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final teacher = _teacher;
    final application = _application;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDetails,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : teacher == null || application == null
          ? const Center(child: Text('Application not found'))
          : Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primaryContainer,
                              Theme.of(context).colorScheme.secondaryContainer,
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              child: Text(
                                teacher.firstName[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              teacher.fullName,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  application.status,
                                ).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                application.status.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(application.status),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Type: ${application.applicationType}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Submitted: ${dateFormat.format(application.submittedAt)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Application Info
                            if (application.notes != null &&
                                application.notes!.isNotEmpty)
                              _buildSectionCard(
                                context,
                                'Application Notes',
                                Icons.note,
                                [
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(application.notes!),
                                  ),
                                ],
                              ),
                            if (application.rejectionReason != null &&
                                application.rejectionReason!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildSectionCard(
                                context,
                                'Rejection Reason',
                                Icons.warning,
                                [
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      application.rejectionReason!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),

                            // Contact Information
                            _buildSectionCard(
                              context,
                              'Contact Information',
                              Icons.contact_mail,
                              [
                                _buildInfoTile(
                                  'Email',
                                  teacher.email,
                                  Icons.email,
                                ),
                                _buildInfoTile(
                                  'Phone',
                                  teacher.phoneNumber ?? 'N/A',
                                  Icons.phone,
                                ),
                                _buildInfoTile(
                                  'Address',
                                  teacher.address ?? 'N/A',
                                  Icons.location_on,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Personal Information
                            _buildSectionCard(
                              context,
                              'Personal Information',
                              Icons.person,
                              [
                                _buildInfoTile(
                                  'Gender',
                                  teacher.gender ?? 'N/A',
                                  Icons.wc,
                                ),
                                _buildInfoTile(
                                  'Date of Birth',
                                  teacher.dateOfBirth != null
                                      ? dateFormat.format(teacher.dateOfBirth!)
                                      : 'N/A',
                                  Icons.cake,
                                ),
                                _buildInfoTile(
                                  'Marital Status',
                                  teacher.maritalStatus ?? 'N/A',
                                  Icons.family_restroom,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Education
                            _buildSectionCard(
                              context,
                              'Education (${_education.length})',
                              Icons.school,
                              _education.isEmpty
                                  ? [
                                      const ListTile(
                                        title: Text('No education records'),
                                      ),
                                    ]
                                  : _education
                                        .map(
                                          (edu) => Card(
                                            margin: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    edu.institution,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  ),
                                                  if (edu.degree != null) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Degree: ${edu.degree}',
                                                    ),
                                                  ],
                                                  if (edu.level != null) ...[
                                                    const SizedBox(height: 2),
                                                    Text('Level: ${edu.level}'),
                                                  ],
                                                  if (edu.program != null) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Program: ${edu.program}',
                                                    ),
                                                  ],
                                                  if (edu.yearObtained !=
                                                      null) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Year: ${edu.yearObtained}',
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                            ),
                            const SizedBox(height: 16),

                            // Qualifications
                            _buildSectionCard(
                              context,
                              'Qualifications (${_qualifications.length})',
                              Icons.verified,
                              _qualifications.isEmpty
                                  ? [
                                      const ListTile(
                                        title: Text('No qualifications'),
                                      ),
                                    ]
                                  : _qualifications
                                        .map(
                                          (qual) => Card(
                                            margin: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    qual.certification ??
                                                        'Certification',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  ),
                                                  if (qual.institution !=
                                                      null) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Institution: ${qual.institution}',
                                                    ),
                                                  ],
                                                  if (qual.specialization !=
                                                      null) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Specialization: ${qual.specialization}',
                                                    ),
                                                  ],
                                                  if (qual.yearObtained !=
                                                      null) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Year: ${qual.yearObtained}',
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                            ),
                            const SizedBox(height: 16),

                            // Documents
                            _buildSectionCard(
                              context,
                              'Documents (${_documents.length})',
                              Icons.description,
                              _documents.isEmpty
                                  ? [
                                      const ListTile(
                                        title: Text('No documents uploaded'),
                                      ),
                                    ]
                                  : _documents
                                        .map(
                                          (doc) => Card(
                                            margin: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: ListTile(
                                              leading: Icon(
                                                doc.verified
                                                    ? Icons.check_circle
                                                    : Icons
                                                          .description_outlined,
                                                color: doc.verified
                                                    ? Colors.green
                                                    : Colors.grey,
                                                size: 32,
                                              ),
                                              title: Text(
                                                doc.docType,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              subtitle: doc.remarks != null
                                                  ? Text(doc.remarks!)
                                                  : null,
                                              trailing: doc.verified
                                                  ? const Chip(
                                                      label: Text('Verified'),
                                                      backgroundColor:
                                                          Colors.green,
                                                      labelStyle: TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  : const Chip(
                                                      label: Text('Pending'),
                                                      backgroundColor:
                                                          Colors.orange,
                                                      labelStyle: TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                            ),
                            const SizedBox(
                              height: 100,
                            ), // Space for action buttons
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Action Buttons (only show for pending/under_review status)
                if (application.status == 'pending' ||
                    application.status == 'under_review')
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isProcessing
                                  ? null
                                  : _rejectApplication,
                              icon: const Icon(Icons.cancel),
                              label: const Text('Reject'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _isProcessing
                                  ? null
                                  : _approveApplication,
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Approve'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_isProcessing)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

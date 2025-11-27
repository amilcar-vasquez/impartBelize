import 'package:flutter/material.dart';
import '../../models/teacher.dart';
import '../../models/district.dart';
import '../../models/education.dart';
import '../../models/qualification.dart';
import '../../models/document.dart';
import '../../services/api_service.dart';
import '../../services/district_service.dart';
import '../../services/application_service.dart';
import 'package:intl/intl.dart';

class AdminApplicationsScreen extends StatefulWidget {
  const AdminApplicationsScreen({super.key});

  @override
  State<AdminApplicationsScreen> createState() =>
      _AdminApplicationsScreenState();
}

class _AdminApplicationsScreenState extends State<AdminApplicationsScreen> {
  final ApiService _apiService = ApiService();
  final DistrictService _districtService = DistrictService();

  List<Teacher> _teachers = [];
  List<District> _districts = [];
  bool _isLoading = true;
  String? _error;

  // Filters
  String? _filterStatus;
  int? _filterDistrictId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final teachers = await _apiService.fetchTeachers();
      final districtsResult = await _districtService.fetchDistricts();

      setState(() {
        _teachers = teachers;
        _districts = districtsResult['districts'] as List<District>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Teacher> get _filteredTeachers {
    var filtered = _teachers;

    // Apply status filter
    if (_filterStatus != null && _filterStatus!.isNotEmpty) {
      filtered = filtered
          .where((teacher) => teacher.profileStatus == _filterStatus)
          .toList();
    }

    // Apply district filter
    if (_filterDistrictId != null) {
      filtered = filtered
          .where((teacher) => teacher.districtId == _filterDistrictId)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((teacher) {
        final query = _searchQuery.toLowerCase();
        return teacher.firstName.toLowerCase().contains(query) ||
            teacher.lastName.toLowerCase().contains(query) ||
            teacher.email.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  String _getDistrictName(int? districtId) {
    if (districtId == null) return 'N/A';
    final district = _districts.where((d) => d.id == districtId).firstOrNull;
    return district?.name ?? 'Unknown';
  }

  void _showApplicationDetails(Teacher teacher) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ApplicationDetailScreen(teacher: teacher),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'pending':
        return Icons.hourglass_empty;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Map<String, int> get _statusCounts {
    final counts = {'pending': 0, 'approved': 0, 'rejected': 0};
    for (var teacher in _teachers) {
      final status = teacher.profileStatus?.toLowerCase() ?? 'pending';
      if (counts.containsKey(status)) {
        counts[status] = counts[status]! + 1;
      }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final filteredTeachers = _filteredTeachers;
    final statusCounts = _statusCounts;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.description,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Teacher License Applications',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Review and manage teacher applications',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search and Filter Bar
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search applications...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _filterStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'pending',
                            child: Text('Pending'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'approved',
                            child: Text('Approved'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'rejected',
                            child: Text('Rejected'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _filterStatus = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: _filterDistrictId,
                        decoration: const InputDecoration(
                          labelText: 'District',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('All'),
                          ),
                          ..._districts.map((district) {
                            return DropdownMenuItem<int?>(
                              value: district.id,
                              child: Text(district.name),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() => _filterDistrictId = value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading applications',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _loadData,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filteredTeachers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  size: 64,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _teachers.isEmpty
                                      ? 'No applications found'
                                      : 'No matching applications',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _teachers.isEmpty
                                      ? 'Applications will appear here when teachers apply'
                                      : 'Try adjusting your filters',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            child: ListView(
                              padding: const EdgeInsets.all(24),
                              children: [
                                // Status Stats Cards
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        context,
                                        'Pending',
                                        statusCounts['pending']!,
                                        Icons.hourglass_empty,
                                        Colors.orange,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        context,
                                        'Approved',
                                        statusCounts['approved']!,
                                        Icons.check_circle,
                                        Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        context,
                                        'Rejected',
                                        statusCounts['rejected']!,
                                        Icons.cancel,
                                        Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Applications List
                                ...filteredTeachers.map((teacher) {
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: InkWell(
                                      onTap: () =>
                                          _showApplicationDetails(teacher),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            // Avatar
                                            CircleAvatar(
                                              radius: 28,
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .primaryContainer,
                                              child: Text(
                                                teacher.firstName[0]
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onPrimaryContainer,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),

                                            // Details
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    teacher.fullName,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.email,
                                                        size: 14,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        teacher.email,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall,
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.location_city,
                                                        size: 14,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        _getDistrictName(
                                                            teacher.districtId),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Icon(
                                                        Icons.calendar_today,
                                                        size: 14,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        DateFormat('MMM dd, yyyy')
                                                            .format(teacher
                                                                .createdAt),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Status Badge
                                            Column(
                                              children: [
                                                Icon(
                                                  _getStatusIcon(
                                                      teacher.profileStatus),
                                                  color: _getStatusColor(
                                                      teacher.profileStatus),
                                                  size: 32,
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 12,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(
                                                            teacher
                                                                .profileStatus)
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Text(
                                                    (teacher.profileStatus ??
                                                            'pending')
                                                        .toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: _getStatusColor(
                                                          teacher
                                                              .profileStatus),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                                Icons.chevron_right),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    int count,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// Application Detail Screen
class ApplicationDetailScreen extends StatefulWidget {
  final Teacher teacher;

  const ApplicationDetailScreen({super.key, required this.teacher});

  @override
  State<ApplicationDetailScreen> createState() =>
      _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  final ApplicationService _applicationService = ApplicationService();
  List<Education> _education = [];
  List<Qualification> _qualifications = [];
  List<Document> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);

    try {
      final education =
          await _applicationService.getEducationByTeacher(widget.teacher.id);
      final qualifications = await _applicationService
          .getQualificationsByTeacher(widget.teacher.id);
      final documents =
          await _applicationService.getDocumentsByTeacher(widget.teacher.id);

      setState(() {
        _education = education;
        _qualifications = qualifications;
        _documents = documents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final teacher = widget.teacher;
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
          : SingleChildScrollView(
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
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          child: Text(
                            teacher.firstName[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          teacher.fullName,
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(teacher.profileStatus)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (teacher.profileStatus ?? 'pending').toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(teacher.profileStatus),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Applied: ${dateFormat.format(teacher.createdAt)}',
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
                        // Contact Information
                        _buildSectionCard(
                          context,
                          'Contact Information',
                          Icons.contact_mail,
                          [
                            _buildInfoTile('Email', teacher.email,
                                Icons.email),
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
                                  )
                                ]
                              : _education
                                  .map((edu) => Card(
                                        margin: const EdgeInsets.only(
                                            bottom: 12),
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
                                                Text('Degree: ${edu.degree}'),
                                              ],
                                              if (edu.level != null) ...[
                                                const SizedBox(height: 2),
                                                Text('Level: ${edu.level}'),
                                              ],
                                              if (edu.program != null) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                    'Program: ${edu.program}'),
                                              ],
                                              if (edu.yearObtained !=
                                                  null) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                    'Year: ${edu.yearObtained}'),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ))
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
                                  )
                                ]
                              : _qualifications
                                  .map((qual) => Card(
                                        margin: const EdgeInsets.only(
                                            bottom: 12),
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
                                                    'Institution: ${qual.institution}'),
                                              ],
                                              if (qual.specialization !=
                                                  null) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                    'Specialization: ${qual.specialization}'),
                                              ],
                                              if (qual.yearObtained !=
                                                  null) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                    'Year: ${qual.yearObtained}'),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ))
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
                                  )
                                ]
                              : _documents
                                  .map((doc) => Card(
                                        margin: const EdgeInsets.only(
                                            bottom: 12),
                                        child: ListTile(
                                          leading: Icon(
                                            doc.verified
                                                ? Icons.check_circle
                                                : Icons.description_outlined,
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
                                                      color: Colors.white),
                                                )
                                              : const Chip(
                                                  label: Text('Pending'),
                                                  backgroundColor:
                                                      Colors.orange,
                                                  labelStyle: TextStyle(
                                                      color: Colors.white),
                                                ),
                                        ),
                                      ))
                                  .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
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
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

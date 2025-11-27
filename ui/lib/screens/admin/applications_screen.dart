import 'package:flutter/material.dart';
import '../../models/application.dart';
import '../../models/district.dart';
import '../../services/district_service.dart';
import '../../services/application_service.dart';
import 'application_detail_screen.dart';

class AdminApplicationsScreen extends StatefulWidget {
  const AdminApplicationsScreen({super.key});

  @override
  State<AdminApplicationsScreen> createState() =>
      _AdminApplicationsScreenState();
}

class _AdminApplicationsScreenState extends State<AdminApplicationsScreen> {
  final DistrictService _districtService = DistrictService();
  final ApplicationService _applicationService = ApplicationService();

  List<Application> _applications = [];
  List<District> _districts = [];
  bool _isLoading = true;
  String? _error;

  // Filters
  String? _filterStatus;
  String? _filterApplicationType;
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
      final applicationsResult = await _applicationService.getAllApplications();
      final districtsResult = await _districtService.fetchDistricts();

      setState(() {
        _applications = applicationsResult['applications'] as List<Application>;
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

  List<Application> get _filteredApplications {
    var filtered = _applications;

    // Apply status filter
    if (_filterStatus != null && _filterStatus!.isNotEmpty) {
      filtered = filtered.where((app) => app.status == _filterStatus).toList();
    }

    // Apply application type filter
    if (_filterApplicationType != null && _filterApplicationType!.isNotEmpty) {
      filtered = filtered
          .where((app) => app.applicationType == _filterApplicationType)
          .toList();
    }

    // Apply district filter
    if (_filterDistrictId != null) {
      filtered = filtered
          .where((app) => app.teacherDistrictId == _filterDistrictId)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((app) {
        final query = _searchQuery.toLowerCase();
        return (app.teacherFirstName?.toLowerCase().contains(query) ?? false) ||
            (app.teacherLastName?.toLowerCase().contains(query) ?? false) ||
            (app.teacherEmail?.toLowerCase().contains(query) ?? false) ||
            (app.licenseNumber?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return filtered;
  }

  String _getDistrictName(int? districtId) {
    if (districtId == null) return 'N/A';
    final district = _districts.where((d) => d.id == districtId).firstOrNull;
    return district?.name ?? 'Unknown';
  }

  void _showApplicationDetails(Application application) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ApplicationDetailScreen(
          applicationId: application.applicationId,
          teacherId: application.teacherId,
        ),
      ),
    );

    // Refresh the list if the application was updated
    if (result == true) {
      _loadData();
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

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'pending':
        return Icons.hourglass_empty;
      case 'rejected':
        return Icons.cancel;
      case 'under_review':
        return Icons.rate_review;
      case 'incomplete':
        return Icons.warning;
      default:
        return Icons.help_outline;
    }
  }

  Map<String, int> get _statusCounts {
    final counts = {'pending': 0, 'approved': 0, 'rejected': 0};
    for (var app in _applications) {
      final status = app.status.toLowerCase();
      if (counts.containsKey(status)) {
        counts[status] = counts[status]! + 1;
      }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final filteredApplications = _filteredApplications;
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
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search and Filter Bar
                Column(
                  children: [
                    TextField(
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
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
                : filteredApplications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _applications.isEmpty
                              ? 'No applications found'
                              : 'No matching applications',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _applications.isEmpty
                              ? 'Applications will appear here when teachers apply'
                              : 'Try adjusting your filters',
                          style: Theme.of(context).textTheme.bodyMedium,
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
                        ...filteredApplications.map((application) {
                          final teacherName = application.teacherFullName;
                          final teacherEmail =
                              application.teacherEmail ?? 'N/A';
                          final districtName = _getDistrictName(
                            application.teacherDistrictId,
                          );
                          final statusColor = _getStatusColor(
                            application.status,
                          );
                          final statusIcon = _getStatusIcon(application.status);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => _showApplicationDetails(application),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Avatar
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                      child: Text(
                                        teacherName[0].toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
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
                                            teacherName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.email,
                                                size: 14,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  teacherEmail,
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_city,
                                                size: 14,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  districtName,
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today,
                                                size: 14,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Type: ${application.applicationType}',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
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
                                          statusIcon,
                                          color: statusColor,
                                          size: 32,
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            application.status.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: statusColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.chevron_right),
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
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

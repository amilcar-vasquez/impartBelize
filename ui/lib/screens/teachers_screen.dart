import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/teacher.dart';
import '../services/api_service.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  final ApiService _apiService = ApiService();
  List<Teacher> _teachers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final teachers = await _apiService.fetchTeachers();
      setState(() {
        _teachers = teachers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teachers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTeachers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to add teacher screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add teacher feature coming soon')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Teacher'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
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
              'Error loading teachers',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadTeachers,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_teachers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No teachers found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Add a teacher to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive layout: use cards on larger screens, list on smaller
        if (constraints.maxWidth > 840) {
          return _buildGridView();
        } else {
          return _buildListView();
        }
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _teachers.length,
      itemBuilder: (context, index) {
        return _buildTeacherCard(_teachers[index]);
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisExtent: 280,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _teachers.length,
      itemBuilder: (context, index) {
        return _buildTeacherCard(_teachers[index]);
      },
    );
  }

  Widget _buildTeacherCard(Teacher teacher) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showTeacherDetails(teacher),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      teacher.firstName[0] + teacher.lastName[0],
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teacher.fullName,
                          style: theme.textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          teacher.email,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              if (teacher.phoneNumber != null)
                _buildInfoRow(
                  Icons.phone_outlined,
                  'Phone',
                  teacher.phoneNumber!,
                  theme,
                ),
              if (teacher.phoneNumber != null) const SizedBox(height: 8),
              if (teacher.gender != null)
                _buildInfoRow(
                  Icons.person_outline,
                  'Gender',
                  teacher.gender!,
                  theme,
                ),
              if (teacher.gender != null) const SizedBox(height: 8),
              if (teacher.profileStatus != null)
                _buildInfoRow(
                  Icons.work_outline,
                  'Status',
                  teacher.profileStatus!,
                  theme,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showTeacherDetails(Teacher teacher) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return TeacherDetailsSheet(
            teacher: teacher,
            scrollController: scrollController,
          );
        },
      ),
    );
  }
}

class TeacherDetailsSheet extends StatelessWidget {
  final Teacher teacher;
  final ScrollController scrollController;

  const TeacherDetailsSheet({
    super.key,
    required this.teacher,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat.yMMMd();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      teacher.firstName[0] + teacher.lastName[0],
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  teacher.fullName,
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  teacher.email,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _buildSection(
                  context,
                  'Contact Information',
                  [
                    if (teacher.phoneNumber != null)
                      _DetailItem(
                        icon: Icons.phone,
                        label: 'Phone',
                        value: teacher.phoneNumber!,
                      ),
                    _DetailItem(
                      icon: Icons.email,
                      label: 'Email',
                      value: teacher.email,
                    ),
                    if (teacher.address != null)
                      _DetailItem(
                        icon: Icons.location_on,
                        label: 'Address',
                        value: teacher.address!,
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  'Profile Details',
                  [
                    if (teacher.gender != null)
                      _DetailItem(
                        icon: Icons.person,
                        label: 'Gender',
                        value: teacher.gender!,
                      ),
                    if (teacher.profileStatus != null)
                      _DetailItem(
                        icon: Icons.work,
                        label: 'Profile Status',
                        value: teacher.profileStatus!,
                      ),
                    if (teacher.districtId != null)
                      _DetailItem(
                        icon: Icons.place,
                        label: 'District ID',
                        value: teacher.districtId.toString(),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                if (teacher.dateOfBirth != null)
                  _buildSection(
                    context,
                    'Personal Information',
                    [
                      _DetailItem(
                        icon: Icons.cake,
                        label: 'Date of Birth',
                        value: dateFormat.format(teacher.dateOfBirth!),
                      ),
                    ],
                  ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Edit feature coming soon'),
                            ),
                          );
                        },
                        child: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<_DetailItem> items,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    item.icon,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.value,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;

  _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

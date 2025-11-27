import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/user_service.dart';
import '../../services/institution_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  final UserService _userService = UserService();
  final InstitutionService _institutionService = InstitutionService();

  int _totalUsers = 0;
  int _totalTeachers = 0;
  int _pendingApplications = 0;
  int _totalInstitutions = 0;
  bool _isLoading = true;
  String? _error;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    // Wait for the widget tree to be built before loading data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Add a retry mechanism with exponential backoff
      await Future.delayed(Duration(milliseconds: 100 * (_retryCount + 1)));
      
      // Fetch all data sequentially to avoid race conditions
      final usersResult = await _userService.fetchUsers(page: 1, pageSize: 100);
      
      if (!mounted) return;
      
      final teachers = await _apiService.fetchTeachers();
      
      if (!mounted) return;
      
      final institutionsResult = await _institutionService.fetchInstitutions();

      if (!mounted) return;

      final users = usersResult['users'] as List;
      final institutions = institutionsResult['institutions'] as List;

      // Get total count from metadata if available, otherwise use list length
      final usersMetadata = usersResult['metadata'];
      final totalUsers = usersMetadata != null && usersMetadata.totalRecords != null
          ? usersMetadata.totalRecords
          : users.length;

      // Count pending applications (teachers with pending status)
      final pendingCount = teachers.where((teacher) {
        final status = teacher.profileStatus?.toLowerCase();
        return status == 'pending' || status == null;
      }).length;

      setState(() {
        _totalUsers = totalUsers;
        _totalTeachers = teachers.length;
        _pendingApplications = pendingCount;
        _totalInstitutions = institutions.length;
        _isLoading = false;
        _retryCount = 0; // Reset retry count on success
      });
    } catch (e) {
      if (!mounted) return;
      
      // Auto-retry once if it's the first attempt
      if (_retryCount == 0) {
        _retryCount++;
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _loadDashboardData();
        }
        return;
      }
      
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: CustomScrollView(
        slivers: [
          const SliverAppBar(floating: true, title: Text('Admin Dashboard')),
          
          // Stats Cards
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _error != null
                      ? Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error loading dashboard',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: _loadDashboardData,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _StatCard(
                              title: 'Total Users',
                              value: '$_totalUsers',
                              icon: Icons.people,
                              color: Colors.blue,
                            ),
                            _StatCard(
                              title: 'Total Teachers',
                              value: '$_totalTeachers',
                              icon: Icons.person,
                              color: Colors.green,
                            ),
                            _StatCard(
                              title: 'Pending Applications',
                              value: '$_pendingApplications',
                              icon: Icons.pending_actions,
                              color: Colors.orange,
                            ),
                            _StatCard(
                              title: 'Active Institutions',
                              value: '$_totalInstitutions',
                              icon: Icons.school,
                              color: Colors.purple,
                            ),
                          ],
                        ),
            ),
          ),

          // Quick Stats
          if (!_isLoading && _error == null) ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Quick Overview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _QuickStatRow(
                          label: 'Approved Applications',
                          value: '${_totalTeachers - _pendingApplications}',
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                        const Divider(),
                        _QuickStatRow(
                          label: 'Pending Review',
                          value: '$_pendingApplications',
                          icon: Icons.hourglass_empty,
                          color: Colors.orange,
                        ),
                        const Divider(),
                        _QuickStatRow(
                          label: 'Total Institutions',
                          value: '$_totalInstitutions',
                          icon: Icons.school,
                          color: Colors.purple,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Recent Activity placeholder
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.info_outline,
                            color:
                                Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: const Text('Recent activity coming soon'),
                        subtitle:
                            const Text('User activities will be tracked here'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 32),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: color.withOpacity(0.2),
                    child: Icon(Icons.trending_up, color: color, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickStatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _QuickStatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

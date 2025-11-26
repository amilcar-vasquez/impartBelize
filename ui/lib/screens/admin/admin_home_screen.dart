import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _authService.getUser();
    setState(() {
      _currentUser = user;
      _isLoading = false;
    });

    // Verify user has admin role
    if (user == null || !user.isAdmin) {
      if (mounted) {
        // Redirect non-admin users to regular home screen
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  static const List<_AdminSection> _sections = [
    _AdminSection(
      icon: Icons.dashboard,
      label: 'Dashboard',
      selectedIcon: Icons.dashboard_rounded,
    ),
    _AdminSection(
      icon: Icons.people_outline,
      label: 'Users',
      selectedIcon: Icons.people,
    ),
    _AdminSection(
      icon: Icons.person_outline,
      label: 'Teachers',
      selectedIcon: Icons.person,
    ),
    _AdminSection(
      icon: Icons.description_outlined,
      label: 'Applications',
      selectedIcon: Icons.description,
    ),
    _AdminSection(
      icon: Icons.location_city_outlined,
      label: 'Districts',
      selectedIcon: Icons.location_city,
    ),
    _AdminSection(
      icon: Icons.school_outlined,
      label: 'Institutions',
      selectedIcon: Icons.school,
    ),
    _AdminSection(
      icon: Icons.notifications_outlined,
      label: 'Notifications',
      selectedIcon: Icons.notifications,
    ),
    _AdminSection(
      icon: Icons.settings_outlined,
      label: 'Settings',
      selectedIcon: Icons.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 640 && screenWidth < 1024;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar navigation (desktop and tablet)
          if (isDesktop || isTablet)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: isDesktop
                  ? NavigationRailLabelType.selected
                  : NavigationRailLabelType.all,
              extended: isDesktop,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: isDesktop ? 32 : 20,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.admin_panel_settings,
                        size: isDesktop ? 32 : 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    if (isDesktop) ...[
                      const SizedBox(height: 8),
                      Text(
                        _currentUser?.username ?? 'Admin',
                        style: Theme.of(context).textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Administrator',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: _handleLogout,
                      tooltip: 'Logout',
                    ),
                  ),
                ),
              ),
              destinations: _sections
                  .map(
                    (section) => NavigationRailDestination(
                      icon: Icon(section.icon),
                      selectedIcon: Icon(section.selectedIcon),
                      label: Text(section.label),
                    ),
                  )
                  .toList(),
            ),
          if (isDesktop || isTablet)
            const VerticalDivider(thickness: 1, width: 1),

          // Main content area
          Expanded(child: _buildContent(_sections[_selectedIndex].label)),
        ],
      ),

      // Bottom navigation (mobile)
      bottomNavigationBar: (!isDesktop && !isTablet)
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: _sections
                  .take(5) // Show only first 5 items on mobile
                  .map(
                    (section) => NavigationDestination(
                      icon: Icon(section.icon),
                      selectedIcon: Icon(section.selectedIcon),
                      label: section.label,
                    ),
                  )
                  .toList(),
            )
          : null,
    );
  }

  Widget _buildContent(String sectionLabel) {
    switch (sectionLabel) {
      case 'Dashboard':
        return _buildDashboard();
      case 'Users':
        return _buildPlaceholder('Users Management', Icons.people);
      case 'Teachers':
        return _buildPlaceholder('Teachers Management', Icons.person);
      case 'Applications':
        return _buildPlaceholder('License Applications', Icons.description);
      case 'Districts':
        return _buildPlaceholder('Districts Management', Icons.location_city);
      case 'Institutions':
        return _buildPlaceholder('Institutions Management', Icons.school);
      case 'Notifications':
        return _buildPlaceholder('Notifications', Icons.notifications);
      case 'Settings':
        return _buildPlaceholder('System Settings', Icons.settings);
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          title: const Text('Admin Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                // Handle notifications
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _handleLogout,
            ),
            const SizedBox(width: 8),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _StatCard(
                  title: 'Total Users',
                  value: '0',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
                _StatCard(
                  title: 'Total Teachers',
                  value: '0',
                  icon: Icons.person,
                  color: Colors.green,
                ),
                _StatCard(
                  title: 'Pending Applications',
                  value: '0',
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                ),
                _StatCard(
                  title: 'Active Institutions',
                  value: '0',
                  icon: Icons.school,
                  color: Colors.purple,
                ),
              ],
            ),
          ),
        ),
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
                      leading: const CircleAvatar(
                        child: Icon(Icons.info_outline),
                      ),
                      title: const Text('No recent activity'),
                      subtitle: const Text('Activity will appear here'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(String title, IconData icon) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Coming soon...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminSection {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _AdminSection({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
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
                    child: Icon(Icons.arrow_upward, color: color, size: 16),
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

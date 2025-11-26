import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import 'dashboard_screen.dart';
import 'users_screen.dart';
import 'teachers_screen.dart';
import 'applications_screen.dart';
import 'districts_screen.dart';
import 'institutions_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';

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
      screen: AdminDashboardScreen(),
    ),
    _AdminSection(
      icon: Icons.people_outline,
      label: 'Users',
      selectedIcon: Icons.people,
      screen: AdminUsersScreen(),
    ),
    _AdminSection(
      icon: Icons.person_outline,
      label: 'Teachers',
      selectedIcon: Icons.person,
      screen: AdminTeachersScreen(),
    ),
    _AdminSection(
      icon: Icons.description_outlined,
      label: 'Applications',
      selectedIcon: Icons.description,
      screen: AdminApplicationsScreen(),
    ),
    _AdminSection(
      icon: Icons.location_city_outlined,
      label: 'Districts',
      selectedIcon: Icons.location_city,
      screen: AdminDistrictsScreen(),
    ),
    _AdminSection(
      icon: Icons.school_outlined,
      label: 'Institutions',
      selectedIcon: Icons.school,
      screen: AdminInstitutionsScreen(),
    ),
    _AdminSection(
      icon: Icons.notifications_outlined,
      label: 'Notifications',
      selectedIcon: Icons.notifications,
      screen: AdminNotificationsScreen(),
    ),
    _AdminSection(
      icon: Icons.settings_outlined,
      label: 'Settings',
      selectedIcon: Icons.settings,
      screen: AdminSettingsScreen(),
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
    final isMobile = !isDesktop && !isTablet;

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              title: Text(_sections[_selectedIndex].label),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _handleLogout,
                  tooltip: 'Logout',
                ),
              ],
            )
          : null,
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
          Expanded(child: _sections[_selectedIndex].screen),
        ],
      ),

      // Bottom navigation (mobile)
      bottomNavigationBar: isMobile
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
}

class _AdminSection {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget screen;

  const _AdminSection({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.screen,
  });
}

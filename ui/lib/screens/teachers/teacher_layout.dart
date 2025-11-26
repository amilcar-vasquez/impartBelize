import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'application_screen.dart';
import 'settings_screen.dart';

class TeacherLayout extends StatefulWidget {
  const TeacherLayout({super.key});

  @override
  State<TeacherLayout> createState() => _TeacherLayoutState();
}

class _TeacherLayoutState extends State<TeacherLayout> {
  int _selectedIndex = 0;

  void _navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<_TeacherSection> get _sections => [
    _TeacherSection(
      icon: Icons.home_outlined,
      label: 'Home',
      selectedIcon: Icons.home,
      screen: TeacherHomeScreen(
        onNavigateToApplication: () => _navigateToTab(1),
      ),
    ),
    _TeacherSection(
      icon: Icons.description_outlined,
      label: 'Apply',
      selectedIcon: Icons.description,
      screen: const TeacherApplicationScreen(),
    ),
    _TeacherSection(
      icon: Icons.settings_outlined,
      label: 'Settings',
      selectedIcon: Icons.settings,
      screen: const TeacherSettingsScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 640;

    return Scaffold(
      body: Row(
        children: [
          if (!isMobile)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
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
          if (!isMobile) const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _sections[_selectedIndex].screen),
        ],
      ),
      bottomNavigationBar: isMobile
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: _sections
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

class _TeacherSection {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget screen;

  const _TeacherSection({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.screen,
  });
}

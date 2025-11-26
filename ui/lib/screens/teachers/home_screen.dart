import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';

class TeacherHomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToApplication;

  const TeacherHomeScreen({super.key, this.onNavigateToApplication});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  User? _currentUser;
  bool _isLoading = true;
  bool _hasTeacherProfile = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.getUser();
      if (user != null) {
        // Check if teacher profile exists
        final teacher = await _apiService.fetchTeacherByUserId(user.userId);
        setState(() {
          _currentUser = user;
          _hasTeacherProfile = teacher != null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text('Welcome, ${_currentUser?.username ?? 'Teacher'}'),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: _hasTeacherProfile
                    ? _buildExistingTeacherView()
                    : _buildNewTeacherView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // View for teachers who already have a profile
  Widget _buildExistingTeacherView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // License Status Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.card_membership,
                      color: Theme.of(context).colorScheme.primary,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Teaching License',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            'Active • Expires: Dec 31, 2025',
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    // Navigate to renewal application
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Renew License'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Quick Actions
        Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _QuickActionCard(
              icon: Icons.person,
              label: 'View Profile',
              color: Colors.blue,
              onTap: () {
                // Navigate to profile
              },
            ),
            _QuickActionCard(
              icon: Icons.school,
              label: 'Qualifications',
              color: Colors.purple,
              onTap: () {
                // Navigate to qualifications
              },
            ),
            _QuickActionCard(
              icon: Icons.work,
              label: 'Employment',
              color: Colors.orange,
              onTap: () {
                // Navigate to employment history
              },
            ),
            _QuickActionCard(
              icon: Icons.description,
              label: 'Documents',
              color: Colors.teal,
              onTap: () {
                // Navigate to documents
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Recent Activity
        Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: const Text('Profile Updated'),
                subtitle: const Text('Your profile was successfully updated'),
                trailing: const Text('2 days ago'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.upload_file,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: const Text('Document Uploaded'),
                subtitle: const Text('Teaching certificate uploaded'),
                trailing: const Text('1 week ago'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // View for new teachers without a profile
  Widget _buildNewTeacherView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Card
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.school,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Welcome to Impart Belize',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start your journey to becoming a licensed teacher in Belize',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: widget.onNavigateToApplication,
                  icon: const Icon(Icons.add_circle),
                  label: const Text('Apply for Teaching License'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Application Process Steps
        Text(
          'Application Process',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ProcessStep(
                  number: 1,
                  title: 'Personal Information',
                  description: 'Provide your basic details and contact info',
                  isCompleted: false,
                ),
                _ProcessStep(
                  number: 2,
                  title: 'Educational Qualifications',
                  description: 'Add your degrees and certifications',
                  isCompleted: false,
                ),
                _ProcessStep(
                  number: 3,
                  title: 'Upload Documents',
                  description: 'Submit required certificates and ID',
                  isCompleted: false,
                ),
                _ProcessStep(
                  number: 4,
                  title: 'Review & Submit',
                  description: 'Verify information and submit application',
                  isCompleted: false,
                  isLast: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Requirements Card
        Text(
          'What You\'ll Need',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RequirementItem(
                  icon: Icons.badge,
                  text: 'Valid government-issued ID',
                ),
                _RequirementItem(
                  icon: Icons.school,
                  text: 'Educational certificates and transcripts',
                ),
                _RequirementItem(
                  icon: Icons.description,
                  text: 'Teaching credentials or certifications',
                ),
                _RequirementItem(
                  icon: Icons.work,
                  text: 'Work experience documentation (if applicable)',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Help Card
        Card(
          child: ListTile(
            leading: Icon(
              Icons.help_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Need Help?'),
            subtitle: const Text('Contact support for assistance'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to help/support
            },
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProcessStep extends StatelessWidget {
  final int number;
  final String title;
  final String description;
  final bool isCompleted;
  final bool isLast;

  const _ProcessStep({
    required this.number,
    required this.title,
    required this.description,
    required this.isCompleted,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isCompleted
                      ? Colors.green
                      : Theme.of(context).colorScheme.primaryContainer,
                  child: isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text(
                          '$number',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: Theme.of(context).colorScheme.outlineVariant,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (!isLast) const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RequirementItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RequirementItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

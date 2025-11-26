import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/pagination_metadata.dart';
import '../../services/user_service.dart';
import '../../widgets/users_table.dart';
import '../../widgets/pagination_controls.dart';
import '../../widgets/user_edit_modal.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final UserService _userService = UserService();

  List<User> _users = [];
  PaginationMetadata? _metadata;
  bool _isLoading = true;
  String? _error;

  // Filter and pagination state
  int _currentPage = 1;
  final int _pageSize = 10;
  String _sortBy = '-created_at';
  bool? _filterIsActive;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _userService.fetchUsers(
        page: _currentPage,
        pageSize: _pageSize,
        sort: _sortBy,
        isActive: _filterIsActive,
        username: _searchController.text.trim().isNotEmpty
            ? _searchController.text.trim()
            : null,
      );

      setState(() {
        _users = result['users'] as List<User>;
        _metadata = result['metadata'] as PaginationMetadata?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _handlePageChange(int page) {
    setState(() => _currentPage = page);
    _loadUsers();
  }

  void _handleSortChange(String? sort) {
    if (sort != null) {
      setState(() => _sortBy = sort);
      _loadUsers();
    }
  }

  void _handleFilterChange(bool? isActive) {
    setState(() {
      _filterIsActive = isActive;
      _currentPage = 1; // Reset to first page
    });
    _loadUsers();
  }

  void _handleSearch() {
    setState(() => _currentPage = 1);
    _loadUsers();
  }

  void _openUserEditModal(User user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            UserEditModal(user: user, onUserUpdated: _loadUsers),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Filters section
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search username',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _handleSearch();
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _handleSearch(),
                ),
                const SizedBox(height: 8),

                // Filter and Sort row
                Row(
                  children: [
                    // Filter by status
                    Expanded(
                      child: DropdownButtonFormField<bool?>(
                        value: _filterIsActive,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All')),
                          DropdownMenuItem(value: true, child: Text('Active')),
                          DropdownMenuItem(
                            value: false,
                            child: Text('Inactive'),
                          ),
                        ],
                        onChanged: _handleFilterChange,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Sort dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _sortBy,
                        decoration: const InputDecoration(
                          labelText: 'Sort',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: '-created_at',
                            child: Text('Newest'),
                          ),
                          DropdownMenuItem(
                            value: 'created_at',
                            child: Text('Oldest'),
                          ),
                          DropdownMenuItem(
                            value: 'username',
                            child: Text('A-Z'),
                          ),
                          DropdownMenuItem(
                            value: '-username',
                            child: Text('Z-A'),
                          ),
                        ],
                        onChanged: _handleSortChange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
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
              'Error loading users',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(_error!),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Table
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: UsersTable(users: _users, onUserTap: _openUserEditModal),
          ),
        ),

        // Pagination
        if (_metadata != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: PaginationControls(
              metadata: _metadata!,
              onPageChanged: _handlePageChange,
            ),
          ),
      ],
    );
  }
}

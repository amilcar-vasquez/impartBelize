import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/role.dart';
import '../services/user_service.dart';
import '../services/role_service.dart';

class UserEditModal extends StatefulWidget {
  final User user;
  final VoidCallback onUserUpdated;

  const UserEditModal({
    super.key,
    required this.user,
    required this.onUserUpdated,
  });

  @override
  State<UserEditModal> createState() => _UserEditModalState();
}

class _UserEditModalState extends State<UserEditModal> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();
  final RoleService _roleService = RoleService();

  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late bool _isActive;
  late bool _isActivated;
  late int _roleId;

  bool _isLoading = false;
  bool _showPassword = false;
  List<Role> _roles = [];
  bool _isLoadingRoles = true;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _emailController = TextEditingController(text: widget.user.email);
    _passwordController = TextEditingController();
    _isActive = widget.user.isActive;
    _isActivated = widget.user.isActivated;
    _roleId = widget.user.roleId;
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    try {
      final roles = await _roleService.fetchRoles();
      setState(() {
        _roles = roles;
        _isLoadingRoles = false;
      });
    } catch (e) {
      setState(() => _isLoadingRoles = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading roles: $e')));
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updates = <String, dynamic>{
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'role_id': _roleId,
        'is_active': _isActive,
        'is_activated': _isActivated,
      };

      // Only include password if it was changed
      if (_passwordController.text.isNotEmpty) {
        updates['password'] = _passwordController.text;
      }

      await _userService.updateUser(widget.user.userId, updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully')),
        );
        widget.onUserUpdated();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete user "${widget.user.username}"? This action will deactivate their account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await _userService.deleteUser(widget.user.userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
        widget.onUserUpdated();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit User'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Username
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Username is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!value.contains('@')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password (optional)
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'New Password (optional)',
                hintText: 'Leave blank to keep current',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                ),
              ),
              obscureText: !_showPassword,
              validator: (value) {
                if (value != null && value.isNotEmpty && value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Role
            _isLoadingRoles
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<int>(
                    value: _roleId,
                    decoration: const InputDecoration(
                      labelText: 'Role *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.admin_panel_settings),
                    ),
                    items: _roles.map((role) {
                      return DropdownMenuItem<int>(
                        value: role.roleId,
                        child: Text(role.roleName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _roleId = value);
                      }
                    },
                  ),
            const SizedBox(height: 24),

            // Active status
            Card(
              child: SwitchListTile(
                title: const Text('Active'),
                subtitle: const Text('User can log in'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
            ),
            const SizedBox(height: 8),

            // Activated status
            Card(
              child: SwitchListTile(
                title: const Text('Activated'),
                subtitle: const Text('Email has been verified'),
                value: _isActivated,
                onChanged: (value) => setState(() => _isActivated = value),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            FilledButton.icon(
              onPressed: _isLoading ? null : _updateUser,
              icon: const Icon(Icons.save),
              label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
            const SizedBox(height: 12),

            // Delete button
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _deleteUser,
              icon: const Icon(Icons.delete),
              label: const Text('Delete User'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

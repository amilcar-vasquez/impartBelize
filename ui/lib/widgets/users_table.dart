import 'package:flutter/material.dart';
import '../models/user.dart';

class UsersTable extends StatelessWidget {
  final List<User> users;
  final Function(User) onUserTap;

  const UsersTable({super.key, required this.users, required this.onUserTap});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'No users found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mobile-friendly list view
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            onTap: () => onUserTap(user),
            leading: CircleAvatar(
              backgroundColor: user.isAdmin
                  ? Colors.purple.withOpacity(0.3)
                  : Colors.blue.withOpacity(0.3),
              child: Text(
                user.username[0].toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              user.username,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    Chip(
                      label: Text(
                        user.roleName ?? 'Unknown',
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: user.isAdmin
                          ? Colors.purple.withOpacity(0.2)
                          : Colors.blue.withOpacity(0.2),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    Chip(
                      label: Text(
                        user.isActive ? 'Active' : 'Inactive',
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: user.isActive
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
            trailing: Icon(
              user.isActive ? Icons.check_circle : Icons.pending,
              color: user.isActive ? Colors.green : Colors.orange,
              size: 20,
            ),
          ),
        );
      },
    );
  }
}

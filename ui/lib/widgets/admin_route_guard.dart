import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

/// Route guard that checks if user has admin role before allowing access
class AdminRouteGuard extends StatelessWidget {
  final Widget child;

  const AdminRouteGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: AuthService().getUser(),
      builder: (context, snapshot) {
        // Show loading while checking auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        // Redirect to login if not authenticated
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Redirect to regular home if not admin
        if (!user.isAdmin) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/home');
          });
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Access Denied'),
                  SizedBox(height: 8),
                  Text('You do not have admin privileges'),
                ],
              ),
            ),
          );
        }

        // User is admin, allow access
        return child;
      },
    );
  }
}

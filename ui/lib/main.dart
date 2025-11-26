import 'package:flutter/material.dart';
import 'package:ui/screens/auth/register_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/activation_screen.dart';
import 'screens/teachers/teacher_layout.dart';
import 'screens/admin/admin_layout.dart';
import 'services/auth_service.dart';
import 'services/supabase_storage_service.dart';
import 'widgets/admin_route_guard.dart';
import 'models/user.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseStorageService.initialize();

  runApp(const ImpartBelizeApp());
}

class ImpartBelizeApp extends StatelessWidget {
  const ImpartBelizeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Impart Belize',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      ),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/activate': (context) => const ActivationScreen(),
        '/home': (context) => const TeacherLayout(),
        '/admin/home': (context) =>
            const AdminRouteGuard(child: AdminHomeScreen()),
      },
    );
  }
}

/// Wrapper to check authentication status and redirect accordingly
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: AuthService().getUser(),
      builder: (context, snapshot) {
        // Show loading indicator while checking auth status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        // Navigate based on authentication status and role
        if (user != null) {
          // Redirect based on user role
          if (user.isAdmin) {
            return const AdminRouteGuard(child: AdminHomeScreen());
          } else {
            return const TeacherLayout();
          }
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

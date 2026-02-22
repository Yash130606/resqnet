import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/citizen_dashboard.dart';
import '../screens/dashboard/ngo_dashboard.dart';
import '../screens/dashboard/sos_report_screen.dart';
import '../screens/auth/role_redirect_screen.dart';
import '../screens/volunteer/volunteer_dashboard.dart';
import '../screens/admin/admin_dashboard.dart';
import 'package:resqnetpro/screens/volunteer/volunteer_dashboard.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/citizen-dashboard',
        builder: (context, state) => const CitizenDashboard(),
      ),
      GoRoute(
        path: '/volunteer-dashboard',
        builder: (context, state) => const VolunteerDashboard(),
      ),
      GoRoute(
        path: '/admin-dashboard',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/ngo-dashboard',
        builder: (context, state) => const NgoDashboard(),
      ),
      GoRoute(
        path: '/sos-report',
        builder: (context, state) => const SosReportScreen(),
      ),
      GoRoute(
        path: '/role-redirect',
        builder: (context, state) => const RoleRedirectScreen(),
      ),
    ],
  );
}

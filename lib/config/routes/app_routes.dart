import 'package:flutter/material.dart';
import 'package:carrental_app/features/auth/presentation/pages/login_page.dart';
import 'package:carrental_app/features/auth/presentation/pages/register_page.dart';
import 'package:carrental_app/features/home/presentation/pages/home_page.dart';
import 'package:carrental_app/features/car_details/presentation/pages/car_details_page.dart';
import 'package:carrental_app/features/booking/presentation/pages/booking_page.dart';
import 'package:carrental_app/features/profile/presentation/pages/profile_page.dart';
import 'package:carrental_app/features/admin/presentation/pages/admin_dashboard_page.dart';

class AppRoutes {
  static const String initial = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String carDetails = '/car-details';
  static const String booking = '/booking';
  static const String profile = '/profile';
  static const String adminDashboard = '/admin-dashboard';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case initial:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case carDetails:
        final carId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => CarDetailsPage(carId: carId));
      case booking:
        final carId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => BookingPage(carId: carId));
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardPage());
      default:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Text('No route defined for ${settings.name}'),
                ),
              ),
        );
    }
  }
}

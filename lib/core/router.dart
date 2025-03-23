import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rentapp/presentation/bloc/booking_bloc.dart';
import 'package:rentapp/injection_container.dart';
import 'package:rentapp/presentation/pages/MapsDetailsPage.dart';
import 'package:rentapp/presentation/pages/car_details_page.dart';
import 'package:rentapp/presentation/pages/car_list_screen.dart';
import 'package:rentapp/presentation/pages/checkout_page.dart';
import 'package:rentapp/presentation/pages/onboarding_page.dart';
import 'package:rentapp/presentation/pages/profile/profile_page.dart';
import 'package:rentapp/data/models/car.dart';
import 'package:rentapp/data/models/booking.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const OnboardingPage());
      case '/car-list':
        return MaterialPageRoute(builder: (_) => CarListScreen());
      case '/car-details':
        final car = settings.arguments as Car;
        return MaterialPageRoute(
          builder: (_) => CarDetailsPage(car: car),
        );
      case '/maps-details':
        final car = settings.arguments as Car;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => getIt<BookingBloc>(),
            child: MapsDetailsPage(car: car),
          ),
        );
      case '/checkout':
        final data = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => getIt<BookingBloc>(),
            child: CheckoutPage(
              car: data['car'] as Car,
              booking: data['booking'] as Booking,
            ),
          ),
        );
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}

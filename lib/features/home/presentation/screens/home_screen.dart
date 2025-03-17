import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../car/presentation/screens/car_listing_screen.dart';
import '../../../booking/presentation/screens/bookings_list_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../admin/presentation/screens/admin_dashboard_screen.dart';
import '../../../admin/presentation/bloc/admin_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const CarListingScreen(),
    const BookingsListScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(CheckAdminStatus());
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        if (state is AdminAuthenticated) {
          return const AdminDashboardScreen();
        }

        return Scaffold(
          body: _screens[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.directions_car),
                label: 'Cars',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: 'Bookings',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
          floatingActionButton:
              _selectedIndex == 0
                  ? FloatingActionButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/car-management');
                    },
                    child: const Icon(Icons.add),
                  )
                  : null,
        );
      },
    );
  }
}

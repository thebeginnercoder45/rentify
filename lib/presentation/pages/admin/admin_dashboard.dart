import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rentapp/data/models/app_user.dart';
import 'package:rentapp/presentation/bloc/auth_bloc.dart';
import 'package:rentapp/presentation/bloc/auth_state.dart';
import 'package:rentapp/presentation/pages/admin/car_management.dart';
import 'package:rentapp/presentation/pages/admin/booking_management.dart';
import 'package:rentapp/presentation/pages/admin/user_management.dart';
import 'package:rentapp/presentation/pages/car_list_screen.dart';
import 'package:rentapp/presentation/widgets/admin_bottom_navigation.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Theme colors
  static const Color primaryGold = Color(0xFFDAA520);
  static const Color primaryBlack = Color(0xFF121212);
  static const Color darkGrey = Color(0xFF2D2D2D);
  static const Color lightGrey = Color(0xFFF5F5F5);

  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          final appUser = state.appUser;

          // Only admin users can access this dashboard
          if (!appUser.isAdmin) {
            // Redirect non-admin users
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const CarListScreen()),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('You do not have admin privileges'),
                  backgroundColor: Colors.red,
                ),
              );
            });
            return const SizedBox.shrink();
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Admin Dashboard',
                style: TextStyle(color: primaryGold),
              ),
              backgroundColor: primaryBlack,
              actions: [
                IconButton(
                  icon: const Icon(Icons.exit_to_app, color: primaryGold),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (context) => const CarListScreen()),
                    );
                  },
                  tooltip: 'Exit to User View',
                ),
              ],
            ),
            body: _getScreenForIndex(_currentNavIndex),
            bottomNavigationBar: AdminBottomNavigation(
              currentIndex: _currentNavIndex,
              onTap: (index) {
                setState(() {
                  _currentNavIndex = index;
                });
              },
            ),
          );
        } else {
          // Redirect non-authenticated users
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const CarListScreen()),
            );
          });
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _getScreenForIndex(int index) {
    switch (index) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return const CarManagementScreen();
      case 2:
        return const BookingManagementScreen();
      case 3:
        return const UserManagementScreen();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            const SizedBox(height: 20),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is Authenticated) {
                  final user = state.appUser;
                  return Text(
                    'Welcome, ${user.displayName ?? 'Admin'}!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
                return const Text(
                  'Welcome, Admin!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage your rental fleet and operations',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),

            // Stats overview
            const Text(
              'Quick Stats',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatsGrid(),
            const SizedBox(height: 30),

            // Admin Actions
            const Text(
              'Admin Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildAdminCard(
                  context,
                  'Car Management',
                  Icons.directions_car,
                  Colors.blue,
                  () {
                    setState(() {
                      _currentNavIndex = 1;
                    });
                  },
                ),
                _buildAdminCard(
                  context,
                  'Booking Management',
                  Icons.calendar_today,
                  Colors.green,
                  () {
                    setState(() {
                      _currentNavIndex = 2;
                    });
                  },
                ),
                _buildAdminCard(
                  context,
                  'User Management',
                  Icons.people,
                  Colors.orange,
                  () {
                    setState(() {
                      _currentNavIndex = 3;
                    });
                  },
                ),
                _buildAdminCard(
                  context,
                  'Analytics',
                  Icons.bar_chart,
                  Colors.purple,
                  () {
                    // Show coming soon message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Analytics feature coming soon!'),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Recent activity section
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  return _buildActivityItem(
                    getActivityIcon(index),
                    getActivityTitle(index),
                    getActivityDescription(index),
                    getActivityTime(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard('Total Cars', '24', Icons.directions_car, Colors.blue),
        _buildStatCard(
            'Active Bookings', '12', Icons.calendar_today, Colors.green),
        _buildStatCard('Total Users', '45', Icons.people, Colors.orange),
        _buildStatCard(
            'Revenue', '₹45,000', Icons.currency_rupee, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryBlack,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryBlack,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    IconData icon,
    String title,
    String description,
    String time,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: primaryGold.withOpacity(0.2),
        child: Icon(icon, color: primaryGold),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(description),
      trailing: Text(
        time,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
    );
  }

  IconData getActivityIcon(int index) {
    switch (index) {
      case 0:
        return Icons.directions_car;
      case 1:
        return Icons.calendar_today;
      case 2:
        return Icons.person;
      default:
        return Icons.event_note;
    }
  }

  String getActivityTitle(int index) {
    switch (index) {
      case 0:
        return 'New Car Added';
      case 1:
        return 'Booking Confirmed';
      case 2:
        return 'New User Registered';
      default:
        return 'System Update';
    }
  }

  String getActivityDescription(int index) {
    switch (index) {
      case 0:
        return 'BMW X5 was added to the fleet';
      case 1:
        return 'Booking #1234 was confirmed';
      case 2:
        return 'John Doe created a new account';
      default:
        return 'System was updated';
    }
  }

  String getActivityTime(int index) {
    switch (index) {
      case 0:
        return '10 mins ago';
      case 1:
        return '45 mins ago';
      case 2:
        return '2 hours ago';
      default:
        return 'Today';
    }
  }
}

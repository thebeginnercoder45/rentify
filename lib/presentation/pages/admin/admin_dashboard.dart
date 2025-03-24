import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rentapp/data/models/app_user.dart';
import 'package:rentapp/data/models/activity_log.dart';
import 'package:rentapp/data/services/analytics_service.dart';
import 'package:rentapp/presentation/bloc/auth_bloc.dart';
import 'package:rentapp/presentation/bloc/auth_state.dart';
import 'package:rentapp/presentation/pages/admin/car_management.dart';
import 'package:rentapp/presentation/pages/admin/booking_management.dart';
import 'package:rentapp/presentation/pages/admin/user_management.dart';
import 'package:rentapp/presentation/pages/car_list_screen.dart';
import 'package:rentapp/presentation/widgets/admin_bottom_navigation.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

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

  // Analytics and activity data
  final AnalyticsService _analyticsService = AnalyticsService();
  AdminAnalytics? _analytics;
  List<ActivityLog> _recentActivities = [];
  bool _isLoadingAnalytics = false;
  bool _isLoadingActivities = false;

  // Format numbers for display
  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 0,
  );

  int _currentNavIndex = 0;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
    _loadRecentActivities();

    // Set up timer to auto-refresh data every 30 seconds
    _setupAutoRefresh();
  }

  void _setupAutoRefresh() {
    // Cancel any existing timer
    _refreshTimer?.cancel();

    // Create a new timer that refreshes activity data every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadRecentActivities(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Load analytics data
  Future<void> _loadAnalytics() async {
    if (mounted) {
      setState(() {
        _isLoadingAnalytics = true;
      });
    }

    try {
      final analytics = await _analyticsService.getAdminAnalytics();

      if (mounted) {
        setState(() {
          _analytics = analytics;
          _isLoadingAnalytics = false;
        });
      }
    } catch (e) {
      print('Error loading analytics: $e');
      if (mounted) {
        setState(() {
          _isLoadingAnalytics = false;
        });
      }
    }
  }

  // Load recent activities
  Future<void> _loadRecentActivities({bool silent = false}) async {
    if (mounted && !silent) {
      setState(() {
        _isLoadingActivities = true;
      });
    }

    try {
      debugPrint('Fetching recent activities...');
      final activities = await ActivityLogger.getRecentActivities(limit: 5);
      debugPrint('Fetched ${activities.length} activities');

      if (mounted) {
        setState(() {
          _recentActivities = activities;
          _isLoadingActivities = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading activities: $e');
      if (mounted && !silent) {
        setState(() {
          _isLoadingActivities = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error loading activities: ${e.toString().split('\n').first}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Refresh all data
  Future<void> _refreshData() async {
    await Future.wait([
      _loadAnalytics(),
      _loadRecentActivities(),
    ]);
  }

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
                // Refresh button
                IconButton(
                  icon: const Icon(Icons.refresh, color: primaryGold),
                  onPressed: _refreshData,
                  tooltip: 'Refresh Data',
                ),
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
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
              _isLoadingAnalytics
                  ? const Center(child: CircularProgressIndicator())
                  : _buildStatsGrid(),
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
                      _showAnalyticsDetails();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Recent activity section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _loadRecentActivities,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _isLoadingActivities
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _recentActivities.isEmpty
                      ? Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(36.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.notifications_off,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No recent activities found',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Activities will appear here as users interact with the system',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _buildActivityList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final analytics = _analytics ??
        AdminAnalytics(
          totalCars: 0,
          activeBookings: 0,
          totalUsers: 0,
          totalRevenue: 0,
        );

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          'Total Cars',
          analytics.totalCars.toString(),
          Icons.directions_car,
          Colors.blue,
        ),
        _buildStatCard(
          'Active Bookings',
          analytics.activeBookings.toString(),
          Icons.calendar_today,
          Colors.green,
        ),
        _buildStatCard(
          'Total Users',
          analytics.totalUsers.toString(),
          Icons.people,
          Colors.orange,
        ),
        _buildStatCard(
          'Revenue',
          _currencyFormat.format(analytics.totalRevenue),
          Icons.currency_rupee,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildActivityList() {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Latest Activities',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Auto-refreshes every 30 seconds',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentActivities.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final activity = _recentActivities[index];

              // Calculate if this activity is new (less than 2 minutes old)
              final isNew =
                  DateTime.now().difference(activity.timestamp).inMinutes < 2;

              return _buildActivityItem(
                activity.icon,
                activity.title,
                activity.description,
                activity.getTimeAgo(),
                isNew: isNew,
                timestamp: activity.timestamp,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    IconData icon,
    String title,
    String description,
    String time, {
    bool isNew = false,
    DateTime? timestamp,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isNew
            ? Colors.green.withOpacity(0.2)
            : primaryGold.withOpacity(0.2),
        child: Icon(icon, color: isNew ? Colors.green : primaryGold),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (isNew)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'NEW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(description),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                time,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              if (timestamp != null)
                Text(
                  DateFormat('MMM d, h:mm a').format(timestamp),
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
            ],
          ),
        ],
      ),
      isThreeLine: true,
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

  void _showAnalyticsDetails() {
    // Get current analytics data
    final analytics = _analytics ??
        AdminAnalytics(
          totalCars: 0,
          activeBookings: 0,
          totalUsers: 0,
          totalRevenue: 0,
        );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Analytics Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Car statistics
                _buildAnalyticsSection(
                  'Car Statistics',
                  [
                    _buildAnalyticsItem(
                        'Total Cars', analytics.totalCars.toString()),
                    _buildAnalyticsItem('Available Cars',
                        '${analytics.totalCars - analytics.activeBookings}'),
                    _buildAnalyticsItem(
                        'Booked Cars', analytics.activeBookings.toString()),
                  ],
                ),

                const SizedBox(height: 20),

                // Booking statistics
                _buildAnalyticsSection(
                  'Booking Statistics',
                  [
                    _buildAnalyticsItem(
                        'Active Bookings', analytics.activeBookings.toString()),
                    _buildAnalyticsItem(
                        'Average Booking Value',
                        analytics.activeBookings > 0
                            ? _currencyFormat.format(analytics.totalRevenue /
                                analytics.activeBookings)
                            : _currencyFormat.format(0)),
                    _buildAnalyticsItem('Total Revenue',
                        _currencyFormat.format(analytics.totalRevenue)),
                  ],
                ),

                const SizedBox(height: 20),

                // User statistics
                _buildAnalyticsSection(
                  'User Statistics',
                  [
                    _buildAnalyticsItem(
                        'Total Users', analytics.totalUsers.toString()),
                    _buildAnalyticsItem(
                        'Users Per Car',
                        analytics.totalCars > 0
                            ? (analytics.totalUsers / analytics.totalCars)
                                .toStringAsFixed(1)
                            : '0'),
                    _buildAnalyticsItem('Conversion Rate',
                        '${analytics.activeBookings > 0 && analytics.totalUsers > 0 ? ((analytics.activeBookings / analytics.totalUsers) * 100).toStringAsFixed(1) : '0'}%'),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              await _refreshData();
              Navigator.of(context).pop();
              _showAnalyticsDetails(); // Reopen with fresh data
            },
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...items,
      ],
    );
  }

  Widget _buildAnalyticsItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

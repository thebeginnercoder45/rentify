import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rentapp/presentation/bloc/auth_bloc.dart';
import 'package:rentapp/presentation/bloc/auth_event.dart';
import 'package:rentapp/presentation/bloc/auth_state.dart';
import 'package:rentapp/presentation/widgets/bottom_navigation.dart';
import 'package:rentapp/presentation/pages/my_bookings_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rentapp/data/models/booking.dart';
import 'package:rentapp/presentation/bloc/booking_bloc.dart';
import 'package:rentapp/presentation/bloc/booking_event.dart';
import 'package:rentapp/presentation/bloc/booking_state.dart';
import 'package:rentapp/presentation/pages/booking_details_page.dart';
import 'package:rentapp/presentation/pages/admin/admin_dashboard.dart';
import 'package:rentapp/data/models/app_user_simple.dart' as app_model;

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  // Theme colors
  static const Color primaryGold = Color(0xFFDAA520);
  static const Color primaryBlack = Color(0xFF121212);
  static const Color accentGold = Color(0xFFF5CE69);
  static const Color lightGold = Color(0xFFF8E8B0);
  static const Color darkGrey = Color(0xFF2D2D2D);
  static const Color mediumGrey = Color(0xFF4D4D4D);

  // Set current nav index to 3 (Profile tab)
  int _currentNavIndex = 3;

  User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // Check authentication status
    context.read<AuthBloc>().add(CheckAuthStatus());
    _loadBookingStats();
  }

  void _loadBookingStats() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context
          .read<BookingBloc>()
          .add(FetchBookings(userId: authState.appUser.uid));
    } else if (authState is GuestMode) {
      context
          .read<BookingBloc>()
          .add(FetchBookings(userId: authState.appUser.uid));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onNavigationTap(int index) {
    if (index == _currentNavIndex) return;

    setState(() {
      _currentNavIndex = index;
    });

    switch (index) {
      case 0:
        // Navigate back to home/cars screen
        Navigator.pop(context);
        break;
      case 1:
        // Navigate to My Bookings
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyBookingsScreen()),
        );
        break;
      case 2:
        // Notifications - Show coming soon
        _showComingSoonDialog('Notifications');
        break;
      case 3:
        // We're already on the profile screen
        break;
    }
  }

  void _showComingSoonDialog(String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Coming Soon',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '$featureName feature will be available soon!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: primaryGold,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _signInWithEmailAndPassword() {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email and password are required')),
      );
      return;
    }

    context.read<AuthBloc>().add(
          LoginWithEmailPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  void _signUp() {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email and password are required')),
      );
      return;
    }

    context.read<AuthBloc>().add(
          SignupWithEmailPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
          ),
        );
  }

  void _signOut() {
    context.read<AuthBloc>().add(Logout());
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If on a sub-tab, go to home tab instead of exiting the app
        if (_currentNavIndex != 0) {
          setState(() {
            _currentNavIndex = 0;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Profile',
            style: TextStyle(
              color: primaryGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 0,
          backgroundColor: primaryBlack,
          // Show back button only if pushed over another screen
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: primaryGold),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          automaticallyImplyLeading: false,
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading) {
              return const Center(
                child: CircularProgressIndicator(color: primaryGold),
              );
            } else if (state is Authenticated || state is GuestMode) {
              final appUser = state is Authenticated
                  ? state.appUser
                  : (state as GuestMode).appUser;
              return _buildUserProfile(appUser, state is GuestMode);
            } else {
              return _buildLoginForm();
            }
          },
        ),
        bottomNavigationBar: BottomNavigation(
          currentIndex: _currentNavIndex,
          onTap: _onNavigationTap,
        ),
      ),
    );
  }

  Widget _buildUserProfile(app_model.AppUser appUser, bool isGuestMode) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildUserProfileHeader(appUser, isGuestMode),
          _buildBookingHistorySection(),
          _buildUserProfileFooter(appUser, isGuestMode),
        ],
      ),
    );
  }

  Widget _buildUserProfileHeader(app_model.AppUser appUser, bool isGuestMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundColor: primaryGold,
              child: Icon(
                Icons.person,
                size: 60,
                color: primaryBlack,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              appUser.displayName ?? appUser.email ?? 'User',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (isGuestMode)
              const Text(
                'Guest User',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Text(
                appUser.email ?? '',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'User ID: ${appUser.uid.substring(0, 8)}...',
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

  Widget _buildBookingHistorySection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Booking History',
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryBlack,
                  ),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('View All'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyBookingsScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: primaryGold,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBookingStats(),
          const SizedBox(height: 24),
          _buildRecentBookings(),
        ],
      ),
    );
  }

  Widget _buildUserProfileFooter(app_model.AppUser appUser, bool isGuestMode) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Account settings header
          const Padding(
            padding: EdgeInsets.only(left: 8, top: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Account Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Account settings card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Edit profile option
                if (!isGuestMode)
                  ListTile(
                    leading:
                        const Icon(Icons.person_outline, color: primaryGold),
                    title: const Text('Edit Profile'),
                    subtitle: const Text('Update your personal information'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Edit Profile coming soon!')),
                      );
                    },
                  ),

                if (!isGuestMode) const Divider(height: 1),

                // Add Admin Dashboard option for admin users
                if (!isGuestMode && appUser.isAdmin)
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings,
                        color: primaryGold),
                    title: const Text('Admin Dashboard'),
                    subtitle: const Text('Manage cars, bookings, and users'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminDashboard(),
                        ),
                      );
                    },
                  ),

                if (!isGuestMode && appUser.isAdmin) const Divider(height: 1),

                // Payment methods option
                ListTile(
                  leading: const Icon(Icons.payment, color: primaryGold),
                  title: const Text('Payment Methods'),
                  subtitle: const Text('Manage your payment options'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Payment Methods coming soon!')),
                    );
                  },
                ),

                const Divider(height: 1),

                // Notifications option
                ListTile(
                  leading: const Icon(Icons.notifications_outlined,
                      color: primaryGold),
                  title: const Text('Notifications'),
                  subtitle: const Text('Manage your notification preferences'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Notifications coming soon!')),
                    );
                  },
                ),

                const Divider(height: 1),

                // Help & Support option
                ListTile(
                  leading: const Icon(Icons.help_outline, color: primaryGold),
                  title: const Text('Help & Support'),
                  subtitle: const Text('Get assistance and support'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Help & Support coming soon!')),
                    );
                  },
                ),

                const Divider(height: 1),

                // Log out or sign in option
                ListTile(
                  leading: Icon(
                    isGuestMode ? Icons.login : Icons.logout,
                    color: isGuestMode ? Colors.green : Colors.red,
                  ),
                  title: Text(isGuestMode ? 'Sign In' : 'Log Out'),
                  subtitle: Text(
                    isGuestMode
                        ? 'Create an account or sign in'
                        : 'Sign out from your account',
                  ),
                  onTap: () {
                    if (isGuestMode) {
                      // Navigate to auth screen or show convert dialog
                      _showConvertAccountDialog();
                    } else {
                      // Show log out confirmation
                      _showLogoutDialog();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Log Out',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to log out?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _signOut();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingStats() {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        if (state is BookingsLoaded) {
          final bookings = state.bookings;

          // Calculate stats
          final completedCount = bookings
              .where((b) => b.status.toLowerCase() == 'completed')
              .length;
          final activeCount = bookings
              .where((b) =>
                  b.status.toLowerCase() == 'confirmed' ||
                  b.status.toLowerCase() == 'pending')
              .length;
          final cancelledCount = bookings
              .where((b) => b.status.toLowerCase() == 'cancelled')
              .length;
          final totalCount = bookings.length;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', totalCount.toString()),
                _buildStatItem('Active', activeCount.toString()),
                _buildStatItem('Completed', completedCount.toString()),
                _buildStatItem('Cancelled', cancelledCount.toString()),
              ],
            ),
          );
        } else if (state is BookingLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: primaryGold),
            ),
          );
        } else {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', '0'),
                _buildStatItem('Active', '0'),
                _buildStatItem('Completed', '0'),
                _buildStatItem('Cancelled', '0'),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primaryBlack,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentBookings() {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        if (state is BookingsLoaded) {
          final bookings = state.bookings;

          if (bookings.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: lightGold.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.directions_car_outlined,
                    size: 48,
                    color: primaryGold,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No bookings yet',
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your booking history will appear here',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      textStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Show only the 2 most recent bookings
          final recentBookings = bookings.take(2).toList();

          return Column(
            children: [
              ...recentBookings.map((booking) => _buildBookingItem(booking)),
              if (bookings.length > 2)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyBookingsScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryGold,
                      side: const BorderSide(color: primaryGold),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('View All Bookings'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ),
            ],
          );
        } else if (state is BookingLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: primaryGold),
            ),
          );
        } else {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: lightGold.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.directions_car_outlined,
                  size: 48,
                  color: primaryGold,
                ),
                const SizedBox(height: 16),
                Text(
                  'No bookings yet',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your booking history will appear here',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildBookingItem(Booking booking) {
    Color statusColor;
    IconData statusIcon;

    switch (booking.status.toLowerCase()) {
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'completed':
        statusColor = Colors.purple;
        statusIcon = Icons.done_all;
        break;
      case 'pending':
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.pending;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            booking.carImageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 50,
                height: 50,
                color: Colors.grey[300],
                child: const Icon(Icons.car_rental, color: Colors.grey),
              );
            },
          ),
        ),
        title: Text(
          booking.carModel,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${booking.startDate.day}/${booking.startDate.month}/${booking.startDate.year} - ₹${booking.totalPrice.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                statusIcon,
                size: 12,
                color: statusColor,
              ),
              const SizedBox(width: 4),
              Text(
                booking.status[0].toUpperCase() + booking.status.substring(1),
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        onTap: () {
          if (booking.id != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingDetailsPage(
                  bookingId: booking.id!,
                ),
              ),
            ).then((_) {
              // Refresh the bookings when returning from details
              _loadBookingStats();
            });
          }
        },
      ),
    );
  }

  void _showConvertAccountDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Permanent Account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<AuthBloc>().add(
                      ConvertGuestToUser(
                        email: _emailController.text.trim(),
                        password: _passwordController.text,
                        name: _nameController.text.trim(),
                      ),
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGold,
              ),
              child: const Text('Create Account'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Icon(
              Icons.car_rental,
              size: 80,
              color: primaryGold,
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: primaryBlack,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to access your bookings and profile',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _signInWithEmailAndPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlack,
                foregroundColor: primaryGold,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Sign In'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: primaryBlack,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Create Account'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Login as guest
                      context.read<AuthBloc>().add(LoginAsGuest());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: primaryGold,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: primaryGold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Continue as Guest'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

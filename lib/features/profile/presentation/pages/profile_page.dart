import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: EdgeInsets.all(24.r),
              color: Theme.of(context).primaryColor,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50.r,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 50.r,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'John Doe',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'john.doe@example.com',
                    style: TextStyle(fontSize: 16.sp, color: Colors.white70),
                  ),
                ],
              ),
            ),
            // Profile Options
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                children: [
                  _buildProfileOption(
                    context,
                    icon: Icons.history,
                    title: 'Booking History',
                    onTap: () {
                      // Navigate to booking history
                    },
                  ),
                  _buildProfileOption(
                    context,
                    icon: Icons.favorite,
                    title: 'Favorite Cars',
                    onTap: () {
                      // Navigate to favorites
                    },
                  ),
                  _buildProfileOption(
                    context,
                    icon: Icons.payment,
                    title: 'Payment Methods',
                    onTap: () {
                      // Navigate to payment methods
                    },
                  ),
                  _buildProfileOption(
                    context,
                    icon: Icons.notifications,
                    title: 'Notifications',
                    onTap: () {
                      // Navigate to notifications
                    },
                  ),
                  _buildProfileOption(
                    context,
                    icon: Icons.help,
                    title: 'Help & Support',
                    onTap: () {
                      // Navigate to help
                    },
                  ),
                  _buildProfileOption(
                    context,
                    icon: Icons.logout,
                    title: 'Logout',
                    onTap: () {
                      // Handle logout
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24.r, color: Theme.of(context).primaryColor),
            SizedBox(width: 16.w),
            Text(
              title,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, size: 24.r, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}

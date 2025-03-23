import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rentapp/data/models/app_user_simple.dart' as app_model;
import 'package:rentapp/presentation/bloc/auth_bloc.dart';
import 'package:rentapp/presentation/bloc/auth_event.dart';
import 'package:rentapp/presentation/bloc/auth_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  // Theme colors
  static const Color primaryGold = Color(0xFFDAA520);
  static const Color primaryBlack = Color(0xFF121212);
  static const Color accentGold = Color(0xFFF5CE69);
  static const Color lightGold = Color(0xFFF8E8B0);
  static const Color darkGrey = Color(0xFF2D2D2D);
  static const Color mediumGrey = Color(0xFF4D4D4D);

  final List<app_model.AppUser> _users = [];
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Get all users from Firestore
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();

      final List<app_model.AppUser> users = [];

      for (final doc in snapshot.docs) {
        try {
          final userId = doc.id;
          final userData = doc.data();

          // Create a simplified AppUser model
          users.add(
            app_model.AppUser(
              uid: userId,
              email: userData['email'] ?? '',
              displayName: userData['displayName'] ?? 'User',
              phoneNumber: userData['phoneNumber'] ?? '',
              isAnonymous: userData['isAnonymous'] ?? false,
              isAdmin: userData['isAdmin'] ?? false,
              isGuest: userData['isGuest'] ?? false,
            ),
          );
        } catch (e) {
          // Silent error handling for parsing user data
        }
      }

      if (mounted) {
        setState(() {
          _users.clear();
          _users.addAll(users);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  List<app_model.AppUser> get _filteredUsers {
    if (_searchQuery.isEmpty) {
      return _users;
    }
    final query = _searchQuery.toLowerCase();
    return _users.where((user) {
      return user.email.toLowerCase().contains(query) ||
          user.displayName.toLowerCase().contains(query) ||
          user.uid.toLowerCase().contains(query);
    }).toList();
  }

  void _toggleAdminStatus(app_model.AppUser user) {
    final currentUserState = context.read<AuthBloc>().state;
    if (currentUserState is! Authenticated ||
        !currentUserState.appUser.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You do not have permission to modify admin status')),
      );
      return;
    }

    // Get the current authenticated user
    final authenticatedUser = (currentUserState as Authenticated).appUser;

    // Don't allow changing the admin status of the current user
    if (authenticatedUser.uid == user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You cannot change your own admin status')),
      );
      return;
    }

    // Toggle the admin status
    final newAdminStatus = !user.isAdmin;

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          newAdminStatus
              ? 'Promote User to Admin'
              : 'Remove User\'s Admin Status',
        ),
        content: Text(
          newAdminStatus
              ? 'Are you sure you want to make this user an admin?'
              : 'Are you sure you want to remove admin privileges from this user?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(
                    SetAdminRole(
                      userId: user.uid,
                      isAdmin: newAdminStatus,
                    ),
                  );

              // Update local state for immediate UI feedback
              if (mounted) {
                setState(() {
                  int index = _users.indexOf(user);
                  if (index != -1) {
                    _users[index] = app_model.AppUser(
                      uid: user.uid,
                      email: user.email,
                      displayName: user.displayName,
                      phoneNumber: user.phoneNumber,
                      isAnonymous: user.isAnonymous,
                      isAdmin: newAdminStatus,
                      isGuest: user.isGuest,
                    );
                  }
                });
              }
            },
            child: Text(newAdminStatus ? 'Promote' : 'Remove'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(app_model.AppUser user) {
    // Generate a random pastel color for avatar background
    final random = math.Random(user.uid.hashCode);
    final color = HSLColor.fromAHSL(
      1.0,
      random.nextDouble() * 360,
      0.8,
      0.8,
    ).toColor();

    // Format created date if available
    final createdAtTimestamp = user.toMap()['createdAt'] as Timestamp?;
    final createdAt = createdAtTimestamp != null
        ? _dateFormat.format(createdAtTimestamp.toDate())
        : 'Unknown';

    // Format last login date if available
    final lastLoginTimestamp = user.toMap()['lastLoginAt'] as Timestamp?;
    final lastLogin = lastLoginTimestamp != null
        ? _dateFormat.format(lastLoginTimestamp.toDate())
        : 'Unknown';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User avatar
                CircleAvatar(
                  radius: 32,
                  backgroundColor: color,
                  child: Text(
                    _getInitials(user.displayName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // User details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Admin status toggle
                          Switch(
                            value: user.isAdmin,
                            activeColor: primaryGold,
                            onChanged: (_) => _toggleAdminStatus(user),
                          ),
                        ],
                      ),
                      if (user.email.isNotEmpty)
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      // User type and ID
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: user.isAdmin
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user.isAdmin ? 'Admin' : 'User',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    user.isAdmin ? Colors.green : Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (user.isAnonymous)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Guest',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          const Spacer(),
                          Text(
                            'ID: ${user.uid.substring(0, 6)}...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Additional user info in columns
            Row(
              children: [
                Expanded(
                  child: _buildInfoColumn('Created', createdAt),
                ),
                Expanded(
                  child: _buildInfoColumn('Last Login', lastLogin),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Management',
          style: TextStyle(color: primaryGold),
        ),
        backgroundColor: primaryBlack,
        iconTheme: const IconThemeData(color: primaryGold),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh Users',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryGold),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // User count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredUsers.length} user${_filteredUsers.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // User list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: primaryGold),
                  )
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No users found'
                                  : 'No users matching "$_searchQuery"',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        color: primaryGold,
                        child: ListView.builder(
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            return _buildUserCard(_filteredUsers[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      // BlocListener for handling auth events
      bottomNavigationBar: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: const SizedBox.shrink(),
      ),
    );
  }
}

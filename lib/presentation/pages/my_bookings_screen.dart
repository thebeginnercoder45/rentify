import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rentapp/data/models/booking.dart';
import 'package:rentapp/presentation/bloc/booking_bloc.dart';
import 'package:rentapp/presentation/bloc/booking_event.dart';
import 'package:rentapp/presentation/bloc/booking_state.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentapp/presentation/pages/profile/profile_page.dart';
import 'package:rentapp/presentation/widgets/bottom_navigation.dart';
import 'package:rentapp/presentation/pages/booking_details_page.dart';
import 'package:rentapp/utils/notification_service.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  // Theme colors
  static const Color primaryGold = Color(0xFFDAA520);
  static const Color accentGold = Color(0xFFF5CE69);
  static const Color lightGold = Color(0xFFF8E8B0);
  static const Color primaryBlack = Color(0xFF121212);
  static const Color darkGrey = Color(0xFF2D2D2D);
  static const Color mediumGrey = Color(0xFF4D4D4D);

  // Filter options
  final List<String> _statusFilters = [
    'All',
    'Pending',
    'Confirmed',
    'Cancelled',
    'Completed'
  ];
  String _selectedStatusFilter = 'All';
  List<Booking> _filteredBookings = [];
  bool _isDateFilterActive = false;
  String? _dateFilterLabel;
  String _sortCriteria = 'Date (Newest)';
  final List<String> _sortOptions = [
    'Date (Newest)',
    'Date (Oldest)',
    'Price (High-Low)',
    'Price (Low-High)'
  ];

  // Set current nav index to 1 (Bookings tab)
  int _currentNavIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.read<BookingBloc>().state;
    if (state is BookingsLoaded) {
      _applyFilters(state.bookings);
    }
  }

  Future<void> _loadBookings() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        print("DEBUG: Loading bookings via Bloc - User: ${user.uid}");
        // Show loading state
        context.read<BookingBloc>().add(FetchBookings(userId: user.uid));

        // Reset date filter when loading all bookings
        setState(() {
          _isDateFilterActive = false;
          _dateFilterLabel = null;
        });

        // Set a timeout to check if bookings loaded successfully
        Future.delayed(Duration(seconds: 8), () {
          if (mounted) {
            final state = context.read<BookingBloc>().state;
            if (state is BookingLoading || state is BookingError) {
              print(
                  "DEBUG: Bloc loading timed out, trying direct Firestore approach");
              _loadBookingsDirectly();
            }
          }
        });
      } catch (e) {
        print("ERROR: Initial booking load failed: $e");
        // Try the direct approach as fallback
        _loadBookingsDirectly();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to be logged in to view bookings'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate to login if needed
      Navigator.pop(context);
    }
  }

  Future<void> _loadBookingsDirectly() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return; // Not logged in

      setState(() {
        // Show loading UI directly
        _filteredBookings = [];
      });

      print("DEBUG: Attempting direct Firestore booking fetch");

      // First check if the bookings collection exists
      var collectionRef = FirebaseFirestore.instance.collection('bookings');

      // Try to fetch just one document from the collection to check if it exists
      try {
        var testQuery = await collectionRef.limit(1).get();
        print(
            "DEBUG: Bookings collection exists: ${testQuery.docs.isNotEmpty}");

        // If collection is completely empty, try to create it with a test document
        if (testQuery.docs.isEmpty) {
          print(
              "DEBUG: Bookings collection is empty - checking permissions with test document");
          await _createTestBookingIfNeeded(user.uid);
        }
      } catch (e) {
        print("DEBUG: Error checking collection existence: $e");
        // Continue anyway to try the main query
      }

      // Try direct Firestore access, bypassing the Bloc
      final querySnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(Duration(seconds: 15));

      print("DEBUG: Direct fetch found ${querySnapshot.docs.length} bookings");

      // Parse the bookings manually
      List<Booking> bookings = [];
      for (var doc in querySnapshot.docs) {
        try {
          final Map<String, dynamic> data = doc.data();
          data['id'] = doc.id; // Ensure ID is included

          final booking = Booking.fromJson(data);
          bookings.add(booking);
        } catch (e) {
          print("DEBUG: Error parsing booking ${doc.id}: $e");
        }
      }

      // Update state directly
      setState(() {
        _filteredBookings = bookings;
      });

      // Also update the Bloc state to keep it in sync
      if (mounted) {
        context.read<BookingBloc>().emit(BookingsLoaded(bookings));
      }

      print(
          "DEBUG: Direct loading successful with ${bookings.length} bookings");
    } catch (e) {
      print("ERROR: Direct booking load failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load bookings: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createTestBookingIfNeeded(String userId) async {
    try {
      print("DEBUG: Attempting to create test booking for diagnostic purposes");

      // Create a collection reference
      final bookingsRef = FirebaseFirestore.instance.collection('bookings');

      // Create a test booking document
      Map<String, dynamic> bookingData = {
        'userId': userId,
        'carId': 'test_car_id',
        'carName': 'Test Car',
        'carModel': 'Diagnostic Vehicle',
        'carImageUrl': 'assets/images/car_placeholder.png',
        'startDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 2))),
        'endDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 3))),
        'totalPrice': 100.0,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Try to add the document
      final docRef = await bookingsRef.add(bookingData);

      print("DEBUG: Test booking created successfully with ID: ${docRef.id}");

      // Clean up the test booking to avoid cluttering the database
      // Comment this out if you want to keep the test booking for inspection
      await docRef.delete();
      print("DEBUG: Test booking deleted after successful creation test");
    } catch (e) {
      print("ERROR: Failed to create test booking: $e");

      // Try to determine the specific error
      String errorMessage = e.toString();
      if (errorMessage.contains('permission-denied')) {
        print(
            "DEBUG: PERMISSION DENIED - Check Firestore rules for bookings collection");
      } else if (errorMessage.contains('not-found')) {
        print(
            "DEBUG: COLLECTION NOT FOUND - Check if bookings collection exists");
      } else {
        print("DEBUG: Unknown error creating test booking: $errorMessage");
      }
    }
  }

  Future<void> _retryLoadBookings() async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )),
              SizedBox(width: 10),
              Text('Reconnecting to server...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Reset state for a fresh start
      setState(() {
        _selectedStatusFilter = 'All';
        _isDateFilterActive = false;
        _dateFilterLabel = null;
      });

      // Use the direct approach for better reliability
      await _loadBookingsDirectly();
    } catch (e) {
      print("ERROR in retry: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Network error. Check your connection and try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters(List<Booking> bookings) {
    // Apply filtering without setState
    if (_selectedStatusFilter == 'All') {
      _filteredBookings = bookings;
    } else {
      _filteredBookings = bookings
          .where((booking) =>
              booking.status.toLowerCase() ==
              _selectedStatusFilter.toLowerCase())
          .toList();
    }

    // Apply sorting
    _applySorting();
  }

  void _applySorting() {
    switch (_sortCriteria) {
      case 'Date (Newest)':
        _filteredBookings.sort((a, b) => b.startDate.compareTo(a.startDate));
        break;
      case 'Date (Oldest)':
        _filteredBookings.sort((a, b) => a.startDate.compareTo(b.startDate));
        break;
      case 'Price (High-Low)':
        _filteredBookings.sort((a, b) => b.totalPrice.compareTo(a.totalPrice));
        break;
      case 'Price (Low-High)':
        _filteredBookings.sort((a, b) => a.totalPrice.compareTo(b.totalPrice));
        break;
    }
  }

  void _filterBookings(List<Booking> bookings) {
    setState(() {
      _applyFilters(bookings);
    });
  }

  void _sortBookings() {
    setState(() {
      _applySorting();
    });
  }

  Future<void> _showDateRangeFilterDialog() async {
    final initialDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now().add(const Duration(days: 30)),
    );

    final pickedDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: initialDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryGold,
              onPrimary: Colors.black,
              onSurface: primaryBlack,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryGold,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDateRange != null) {
      final dateFormat = DateFormat('MMM d');
      setState(() {
        _isDateFilterActive = true;
        _dateFilterLabel =
            '${dateFormat.format(pickedDateRange.start)} - ${dateFormat.format(pickedDateRange.end)}';
      });

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Filtering bookings by date...'),
            duration: Duration(seconds: 1),
          ),
        );

        try {
          // Fetch filtered bookings by date range
          context.read<BookingBloc>().add(
                FetchFilteredBookings(
                  userId: user.uid,
                  status: _selectedStatusFilter == 'All'
                      ? null
                      : _selectedStatusFilter,
                  startDate: pickedDateRange.start,
                  endDate: pickedDateRange.end,
                ),
              );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error filtering bookings: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );

          // Reset date filter on error
          setState(() {
            _isDateFilterActive = false;
            _dateFilterLabel = null;
          });
        }
      }
    }
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
        // We're already on the bookings screen
        break;
      case 2:
        // Notifications - Show coming soon
        _showComingSoonDialog('Notifications');
        break;
      case 3:
        // Navigate to Profile
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        ).then((_) => setState(() => _currentNavIndex = 1));
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

  void _showSortFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sort & Filter',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text(
                    'Sort By',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: _sortOptions.map((option) {
                      return ChoiceChip(
                        label: Text(option),
                        selected: _sortCriteria == option,
                        selectedColor: primaryGold,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _sortCriteria = option;
                            });
                            Navigator.pop(context);
                            _sortBookings();
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Filter By Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: _statusFilters.map((status) {
                      return FilterChip(
                        label: Text(status),
                        selected: _selectedStatusFilter == status,
                        selectedColor: primaryGold,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedStatusFilter = status;
                            });
                            Navigator.pop(context);
                            final bookingState =
                                context.read<BookingBloc>().state;
                            if (bookingState is BookingsLoaded) {
                              _filterBookings(bookingState.bookings);
                            }
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryBlack,
        title: Text(
          'My Bookings',
          style: GoogleFonts.poppins(
            textStyle: const TextStyle(
              color: primaryGold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: primaryGold),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        automaticallyImplyLeading: false,
        actions: [
          // Filter icon
          IconButton(
            icon: const Icon(Icons.filter_list, color: primaryGold),
            onPressed: _showSortFilterOptions,
            tooltip: 'Sort & Filter',
          ),
          // Date range filter
          IconButton(
            icon: const Icon(Icons.date_range, color: primaryGold),
            onPressed: _showDateRangeFilterDialog,
            tooltip: 'Date Filter',
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: primaryGold),
            onPressed: _retryLoadBookings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: BlocBuilder<BookingBloc, BookingState>(
        builder: (context, state) {
          if (state is BookingInitial) {
            // If user is logged in, get their bookings
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              context.read<BookingBloc>().add(FetchBookings(userId: user.uid));
            } else {
              // Handle not logged in state
              return Center(child: Text('Please log in to view your bookings'));
            }
            return Center(child: CircularProgressIndicator());
          } else if (state is BookingLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is BookingsLoaded) {
            final bookings = state.bookings;
            if (bookings.isEmpty) {
              return _buildEmptyState();
            }
            return _buildBookingsList(bookings);
          } else if (state is BookingError) {
            return _buildErrorState(state.message, context);
          }
          return Center(child: Text('Unknown state'));
        },
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentNavIndex,
        onTap: _onNavigationTap,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No bookings yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Your booking history will appear here',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/explore');
            },
            child: Text('Browse Cars'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGold,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, BuildContext context) {
    // Check if this is a Firestore index error based on the error message
    final bool isIndexError = message.toLowerCase().contains('index') ||
        message.toLowerCase().contains('database setup');

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isIndexError ? Icons.storage : Icons.error_outline,
            size: 80,
            color: isIndexError ? Colors.orange[300] : Colors.red[300],
          ),
          SizedBox(height: 16),
          Text(
            isIndexError
                ? 'Database Configuration Issue'
                : 'Failed to load bookings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                if (isIndexError)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'The app needs additional database setup. Try using our direct booking approach instead.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.grey[700], fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  if (isIndexError) {
                    // For index errors, try the direct approach which doesn't use complex queries
                    _loadBookingsManually();
                  } else {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      context
                          .read<BookingBloc>()
                          .add(FetchBookings(userId: user.uid));
                    }
                  }
                },
                child: Text(isIndexError ? 'Try Alternative Method' : 'Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGold,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              SizedBox(width: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/explore');
                },
                child: Text('Browse Cars'),
                style: TextButton.styleFrom(
                  foregroundColor: primaryGold,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Add a manual bookings load method that doesn't rely on complex queries
  Future<void> _loadBookingsManually() async {
    try {
      // Show loading state
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 10),
              Text('Trying alternative approach...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Get the current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You need to be logged in to view bookings')),
        );
        return;
      }

      // Use the simplest possible query
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .get();

      List<Booking> bookings = [];
      for (var doc in snapshot.docs) {
        try {
          bookings.add(Booking.fromFirestore(doc));
        } catch (e) {
          print('Error parsing booking: $e');
        }
      }

      // Sort manually
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Update the state directly
      if (mounted) {
        context.read<BookingBloc>().emit(BookingsLoaded(bookings));
      }
    } catch (e) {
      print('Error in manual booking load: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Still unable to load bookings. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildBookingsList(List<Booking> bookings) {
    return RefreshIndicator(
      onRefresh: () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          context.read<BookingBloc>().add(FetchBookings(userId: user.uid));
        }
        // Wait for the refresh to complete
        await Future.delayed(Duration(seconds: 2));
      },
      child: ListView.builder(
        itemCount: bookings.length,
        padding: EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _buildBookingCard(booking);
        },
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final dateFormat = DateFormat('MMM dd, yyyy');

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

    return GestureDetector(
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
            // Refresh the bookings list when returning from details page
            _refreshBookings();
          });
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car image and status badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: _buildCarImage(booking),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          booking.status[0].toUpperCase() +
                              booking.status.substring(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Booking details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  _buildDetailRow(
                    Icons.calendar_today,
                    'Start Date: ${dateFormat.format(booking.startDate)}',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.calendar_month,
                    'End Date: ${dateFormat.format(booking.endDate)}',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.timelapse,
                    'Duration: ${booking.endDate.difference(booking.startDate).inDays + 1} days',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.currency_rupee,
                    'Total: ₹${booking.totalPrice.toStringAsFixed(0)}',
                    isBold: true,
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Actions based on booking status
                  if (booking.status.toLowerCase() == 'pending' ||
                      booking.status.toLowerCase() == 'confirmed')
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _showCancelDialog(context, booking),
                            icon: const Icon(Icons.cancel, size: 18),
                            label: const Text('Cancel Booking'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[700],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _showReminderOptions(booking),
                          child: const Icon(Icons.notifications_active),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlack,
                            foregroundColor: primaryGold,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    )
                  else if (booking.status.toLowerCase() == 'completed')
                    ElevatedButton.icon(
                      onPressed: () {
                        // Show rating dialog or navigate to rating screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Rating feature coming soon!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.star, size: 18),
                      label: const Text('Rate Your Experience'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGold,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarImage(Booking booking) {
    // Default images for specific car models to ensure we show images even in offline mode
    Map<String, String> defaultCarImages = {
      'Mahindra Scorpio Classic': 'assets/images/cars/mahindra_scorpio.jpg',
      'Maruti suzuki swift': 'assets/images/cars/suzuki_swift.jpg',
      'Tata Nexon': 'assets/images/cars/tata_nexon.jpg',
      'Toyota Fortuner': 'assets/images/cars/toyota_fortuner.jpg',
      'BMW X5': 'assets/images/cars/bmw_x5.jpg',
      'Tesla Model 3': 'assets/images/cars/tesla_model3.jpg',
      'Honda City': 'assets/images/cars/honda_city.jpg',
    };

    // Check if URL starts with http/https (direct URL)
    if (booking.carImageUrl.startsWith('http')) {
      return Image.network(
        booking.carImageUrl,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint("Error loading network image: $error");
          // If network image fails, try to use default image
          String? defaultImage = defaultCarImages[booking.carName];
          if (defaultImage != null) {
            return Image.asset(
              defaultImage,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholderImage();
              },
            );
          }
          return _buildPlaceholderImage();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingImage();
        },
      );
    }
    // Check if URL starts with assets/ (asset image path)
    else if (booking.carImageUrl.startsWith('assets/')) {
      return Image.asset(
        booking.carImageUrl,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
      );
    }
    // Check if we have a default image for this car model
    else if (defaultCarImages.containsKey(booking.carName)) {
      return Image.asset(
        defaultCarImages[booking.carName]!,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
      );
    }
    // Fallback to placeholder
    else {
      return _buildPlaceholderImage();
    }
  }

  Widget _buildDetailRow(IconData icon, String text, {bool isBold = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: primaryGold),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.poppins(
            textStyle: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? primaryBlack : Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  void _showCancelDialog(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Booking',
          style: GoogleFonts.poppins(
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: Text(
          'Are you sure you want to cancel this booking?\nThis action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep It'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (booking.id != null) {
                context.read<BookingBloc>().add(
                      CancelBooking(bookingId: booking.id!),
                    );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _showReminderOptions(Booking booking) {
    final List<String> reminderOptions = [
      '30 minutes before',
      '1 hour before',
      '3 hours before',
      '1 day before',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.alarm, color: primaryGold),
            const SizedBox(width: 8),
            const Expanded(child: Text('Set Reminder')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('When would you like to be reminded?'),
            const SizedBox(height: 8),
            ...reminderOptions.map(
              (option) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.alarm, color: primaryGold, size: 20),
                title: Text(option),
                onTap: () {
                  Navigator.pop(context);
                  _setReminderNotification(booking, option);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _setReminderNotification(
      Booking booking, String reminderOption) async {
    // Parse the reminder time from the option
    int minutesBefore = 60; // Default to 1 hour

    if (reminderOption.contains('30 minutes')) {
      minutesBefore = 30;
    } else if (reminderOption.contains('1 hour')) {
      minutesBefore = 60;
    } else if (reminderOption.contains('3 hours')) {
      minutesBefore = 180;
    } else if (reminderOption.contains('1 day')) {
      minutesBefore = 1440; // 24 hours
    }

    try {
      // Generate a unique notification ID based on booking
      final notificationId = booking.id.hashCode;

      // Use the notification service to schedule the reminder
      await NotificationService.instance.setRentalReminder(
        id: notificationId,
        carName: booking.carName,
        rentalDateTime: booking.startDate,
        reminderMinutesBefore: minutesBefore,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminder set for $reminderOption'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Test Now',
            textColor: Colors.white,
            onPressed: () {
              _showTestNotification(booking.carName);
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error setting reminder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to set reminder: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showTestNotification(String carName) async {
    try {
      await NotificationService.instance.showNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: 'Test Notification',
        body: 'This is a test reminder for your $carName booking',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent!'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      debugPrint('Error sending test notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send test notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAllRemindersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.notifications, color: primaryGold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Your Reminders',
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Active reminders will appear as notifications on your device'),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: lightGold.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: primaryGold),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Reminders are stored on your device and will trigger even if the app is closed.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  _showTestNotification("Test");
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.notifications_active),
                label: const Text('Send Test Notification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGold,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.car_rental,
            size: 60,
            color: Colors.grey[400],
          ),
          SizedBox(height: 8),
          Text(
            'No Image Available',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingImage() {
    return Container(
      height: 180,
      width: double.infinity,
      color: Colors.grey[200],
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryGold),
        ),
      ),
    );
  }

  // Create a helper method to refresh bookings
  void _refreshBookings() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<BookingBloc>().add(FetchBookings(userId: user.uid));
    }
  }
}

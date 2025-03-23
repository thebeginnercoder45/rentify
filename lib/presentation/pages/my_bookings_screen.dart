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
      // Show loading state
      context.read<BookingBloc>().add(FetchBookings(userId: user.uid));

      // Reset date filter when loading all bookings
      setState(() {
        _isDateFilterActive = false;
        _dateFilterLabel = null;
      });
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
    return BlocConsumer<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state is BookingsLoaded) {
          _filterBookings(state.bookings);
          // Show refresh success message, but only if not initial load
          if (state is! BookingInitial) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bookings refreshed successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 1),
              ),
            );
          }
        } else if (state is BookingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
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
                onPressed: _loadBookings,
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: Column(
            children: [
              _buildHeader(),
              _buildStatusFilter(),
              Expanded(
                child: _buildBookingContent(state),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigation(
            currentIndex: _currentNavIndex,
            onTap: _onNavigationTap,
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: const BoxDecoration(
        color: primaryBlack,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your car rental history',
            style: GoogleFonts.poppins(
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage Your Bookings',
            style: GoogleFonts.poppins(
              textStyle: const TextStyle(
                color: primaryGold,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _statusFilters.map((status) {
                final isSelected = _selectedStatusFilter == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(
                      status,
                      style: GoogleFonts.poppins(
                        textStyle: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? primaryBlack : Colors.grey[600],
                        ),
                      ),
                    ),
                    backgroundColor: Colors.grey[200],
                    selectedColor: primaryGold,
                    showCheckmark: false,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatusFilter = status;
                      });
                      // Trigger filtering based on current state
                      final state = context.read<BookingBloc>().state;
                      if (state is BookingsLoaded) {
                        _filterBookings(state.bookings);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        if (_isDateFilterActive && _dateFilterLabel != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: lightGold.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryGold.withOpacity(0.5), width: 1),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.date_range,
                  color: primaryGold,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Date range: $_dateFilterLabel',
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: primaryBlack,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.close, color: Colors.black54, size: 18),
                  onPressed: _loadBookings,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Clear date filter',
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Bookings Found',
              style: GoogleFonts.poppins(
                textStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your booking history is empty. Start by booking a car to see your reservations here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                textStyle: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlack,
                foregroundColor: primaryGold,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Browse Cars'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No ${_selectedStatusFilter} Bookings',
              style: GoogleFonts.poppins(
                textStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You don\'t have any bookings with the selected status',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                textStyle: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedStatusFilter = 'All';
                });
                final state = context.read<BookingBloc>().state;
                if (state is BookingsLoaded) {
                  _filterBookings(state.bookings);
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryGold,
                side: const BorderSide(color: primaryGold),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Show All Bookings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsList(List<Booking> bookings) {
    return RefreshIndicator(
      color: primaryGold,
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredBookings.length,
        itemBuilder: (context, index) {
          final booking = _filteredBookings[index];
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
            _loadBookings();
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
                  child: Image.asset(
                    booking.carImageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.car_rental,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                      );
                    },
                  ),
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
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Add booking date info
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      booking.carModel,
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                          onPressed: () => _showSetReminderDialog(booking),
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

  void _showSetReminderDialog(Booking booking) {
    final bookingStartDateString =
        DateFormat('EEEE, MMM dd, yyyy').format(booking.startDate);
    final daysUntilBooking =
        booking.startDate.difference(DateTime.now()).inDays;

    final reminderOptions = [
      '1 day before pickup',
      '3 days before pickup',
      '1 week before pickup',
      'Custom reminder...'
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.notifications_active, color: primaryGold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Set Booking Reminder',
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your booking is on $bookingStartDateString',
              style: GoogleFonts.poppins(
                textStyle: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              daysUntilBooking > 0
                  ? '($daysUntilBooking days from now)'
                  : daysUntilBooking == 0
                      ? '(Today!)'
                      : '(Past booking)',
              style: GoogleFonts.poppins(
                textStyle: TextStyle(
                  color: daysUntilBooking <= 1 ? Colors.red : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),
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
                  _confirmReminderSet(booking, option);
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

  void _confirmReminderSet(Booking booking, String reminderOption) {
    // In a real app, we would store this reminder in a local notifications system
    // or send it to a server for push notifications

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder set for $reminderOption'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'View All',
          textColor: Colors.white,
          onPressed: () {
            _showAllRemindersDialog();
          },
        ),
      ),
    );
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
              const Text('Reminder management feature coming soon!'),
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
                        'Set custom reminders for your upcoming bookings to never miss a pickup!',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
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

  Widget _buildBookingContent(BookingState state) {
    if (state is BookingLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: primaryGold,
        ),
      );
    } else if (state is BookingsLoaded) {
      final bookings = state.bookings;
      if (bookings.isEmpty) {
        return _buildEmptyState();
      } else if (_filteredBookings.isEmpty) {
        return _buildFilterEmptyState();
      } else {
        return _buildBookingsList(_filteredBookings);
      }
    } else if (state is BookingError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.message}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadBookings,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlack,
                foregroundColor: primaryGold,
              ),
            ),
          ],
        ),
      );
    } else {
      return const Center(
        child: CircularProgressIndicator(
          color: primaryGold,
        ),
      );
    }
  }
}

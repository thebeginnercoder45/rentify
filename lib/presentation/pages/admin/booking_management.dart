import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rentapp/data/models/booking.dart';
import 'package:rentapp/presentation/bloc/booking_bloc.dart';
import 'package:rentapp/presentation/bloc/booking_event.dart';
import 'package:rentapp/presentation/bloc/booking_state.dart';
import 'package:rentapp/presentation/pages/booking_details_page.dart';
import 'package:intl/intl.dart';

class BookingManagementScreen extends StatefulWidget {
  const BookingManagementScreen({Key? key}) : super(key: key);

  @override
  State<BookingManagementScreen> createState() =>
      _BookingManagementScreenState();
}

class _BookingManagementScreenState extends State<BookingManagementScreen> {
  // Theme colors
  static const Color primaryGold = Color(0xFFDAA520);
  static const Color primaryBlack = Color(0xFF121212);
  static const Color accentGold = Color(0xFFF5CE69);
  static const Color lightGold = Color(0xFFF8E8B0);
  static const Color darkGrey = Color(0xFF2D2D2D);
  static const Color mediumGrey = Color(0xFF4D4D4D);

  // Filter options
  String _statusFilter = 'All';
  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Confirmed',
    'Completed',
    'Cancelled'
  ];

  // Booking list
  List<Booking> _filteredBookings = [];
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final DateFormat _timeFormat = DateFormat('hh:mm a');

  @override
  void initState() {
    super.initState();
    // Load all bookings
    _loadAllBookings();
  }

  void _loadAllBookings() {
    context.read<BookingBloc>().add(const FetchAllBookings());
  }

  void _filterBookings(List<Booking> bookings) {
    setState(() {
      if (_statusFilter == 'All') {
        _filteredBookings = bookings;
      } else {
        _filteredBookings = bookings
            .where((booking) =>
                booking.status.toLowerCase() == _statusFilter.toLowerCase())
            .toList();
      }
    });
  }

  void _updateBookingStatus(String bookingId, String newStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content:
            Text('Are you sure you want to mark this booking as $newStatus?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<BookingBloc>().add(
                    UpdateBookingStatus(
                      bookingId: bookingId,
                      status: newStatus.toLowerCase(),
                    ),
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Booking marked as $newStatus')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Booking Management',
          style: TextStyle(color: primaryGold),
        ),
        backgroundColor: primaryBlack,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryGold),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              children: [
                const Text(
                  'Filter by Status:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _statusOptions.map((status) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(status),
                            selected: _statusFilter == status,
                            onSelected: (selected) {
                              setState(() {
                                _statusFilter = status;
                              });

                              // Re-filter bookings if there are any
                              if (_filteredBookings.isNotEmpty) {
                                final state = context.read<BookingBloc>().state;
                                if (state is BookingsLoaded) {
                                  _filterBookings(state.bookings);
                                }
                              }
                            },
                            selectedColor: primaryGold.withOpacity(0.4),
                            backgroundColor: Colors.grey[200],
                            checkmarkColor: primaryBlack,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bookings list
          Expanded(
            child: BlocConsumer<BookingBloc, BookingState>(
              listener: (context, state) {
                if (state is BookingsLoaded) {
                  _filterBookings(state.bookings);
                } else if (state is BookingError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${state.message}')),
                  );
                } else if (state is BookingUpdated) {
                  _loadAllBookings();
                }
              },
              builder: (context, state) {
                if (state is BookingLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryGold),
                  );
                } else if (state is BookingsLoaded) {
                  if (_filteredBookings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Bookings Found',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _statusFilter == 'All'
                                ? 'There are no bookings in the system yet'
                                : 'No $_statusFilter bookings found',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadAllBookings,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGold,
                              foregroundColor: primaryBlack,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: primaryGold,
                    onRefresh: () async {
                      _loadAllBookings();
                      return Future.delayed(const Duration(seconds: 1));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredBookings.length,
                      itemBuilder: (context, index) {
                        final booking = _filteredBookings[index];
                        return _buildBookingCard(booking);
                      },
                    ),
                  );
                } else if (state is BookingError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Error Loading Bookings',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadAllBookings,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGold,
                            foregroundColor: primaryBlack,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return const Center(
                  child: Text('Loading bookings...'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking.carModel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusBadge(booking.status),
              ],
            ),
            const SizedBox(height: 16),

            // Booking details
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('User ID: ${booking.userId.substring(0, 6)}...'),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Start Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        _dateFormat.format(booking.startDate),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _timeFormat.format(booking.startDate),
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, color: Colors.grey, size: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'End Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        _dateFormat.format(booking.endDate),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _timeFormat.format(booking.endDate),
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${booking.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryGold,
                  ),
                ),
                Row(
                  children: [
                    // View details button
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                BookingDetailsPage(bookingId: booking.id!),
                          ),
                        );
                      },
                    ),

                    // Status update dropdown
                    if (booking.status.toLowerCase() != 'cancelled' &&
                        booking.status.toLowerCase() != 'completed')
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          _updateBookingStatus(booking.id!, value);
                        },
                        itemBuilder: (context) => [
                          if (booking.status.toLowerCase() != 'confirmed')
                            const PopupMenuItem(
                              value: 'Confirmed',
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: Colors.green, size: 20),
                                  SizedBox(width: 8),
                                  Text('Confirm Booking'),
                                ],
                              ),
                            ),
                          if (booking.status.toLowerCase() != 'completed')
                            const PopupMenuItem(
                              value: 'Completed',
                              child: Row(
                                children: [
                                  Icon(Icons.done_all,
                                      color: Colors.blue, size: 20),
                                  SizedBox(width: 8),
                                  Text('Mark as Completed'),
                                ],
                              ),
                            ),
                          if (booking.status.toLowerCase() != 'cancelled')
                            const PopupMenuItem(
                              value: 'Cancelled',
                              child: Row(
                                children: [
                                  Icon(Icons.cancel,
                                      color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Text('Cancel Booking'),
                                ],
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;

    switch (status.toLowerCase()) {
      case 'confirmed':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      case 'completed':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

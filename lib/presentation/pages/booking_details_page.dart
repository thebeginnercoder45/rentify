import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rentapp/data/models/booking.dart';
import 'package:rentapp/presentation/bloc/booking_bloc.dart';
import 'package:rentapp/presentation/bloc/booking_event.dart';
import 'package:rentapp/presentation/bloc/booking_state.dart';
import 'package:rentapp/presentation/widgets/custom_button.dart';

class BookingDetailsPage extends StatefulWidget {
  final String bookingId;

  const BookingDetailsPage({
    Key? key,
    required this.bookingId,
  }) : super(key: key);

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  // Theme colors
  static const Color primaryGold = Color(0xFFDAA520);
  static const Color accentGold = Color(0xFFF5CE69);
  static const Color lightGold = Color(0xFFF8E8B0);
  static const Color primaryBlack = Color(0xFF121212);
  static const Color darkGrey = Color(0xFF2D2D2D);
  static const Color mediumGrey = Color(0xFF4D4D4D);

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
  }

  void _loadBookingDetails() {
    context
        .read<BookingBloc>()
        .add(FetchBookingDetails(bookingId: widget.bookingId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryBlack,
        title: Text(
          'Booking Details',
          style: GoogleFonts.poppins(
            textStyle: const TextStyle(
              color: primaryGold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryGold),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long, color: primaryGold),
            onPressed: () {
              if (context.read<BookingBloc>().state is BookingDetailsLoaded) {
                final booking =
                    (context.read<BookingBloc>().state as BookingDetailsLoaded)
                        .booking;
                _generateBookingTicket(context, booking);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Unable to generate ticket, booking not loaded'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            tooltip: 'Generate Ticket',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: primaryGold),
            onPressed: () {
              _loadBookingDetails();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing booking details...'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: BlocConsumer<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is BookingCancelled) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Booking cancelled successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context); // Go back after cancellation
          } else if (state is BookingUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Booking updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
            _loadBookingDetails(); // Reload the details
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
          if (state is BookingLoading) {
            return const Center(
              child: CircularProgressIndicator(color: primaryGold),
            );
          } else if (state is BookingDetailsLoaded) {
            return _buildBookingDetails(context, state.booking);
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
                    onPressed: _loadBookingDetails,
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
              child: CircularProgressIndicator(color: primaryGold),
            );
          }
        },
      ),
    );
  }

  Widget _buildBookingDetails(BuildContext context, Booking booking) {
    final dateFormat = DateFormat('EEEE, MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');

    // Determine status color and icon
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with car image
          Stack(
            children: [
              SizedBox(
                height: 250,
                width: double.infinity,
                child: Image.asset(
                  booking.carImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.car_rental,
                        size: 100,
                        color: Colors.grey[400],
                      ),
                    );
                  },
                ),
              ),
              Container(
                height: 250,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                child: Text(
                  booking.carModel,
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Status badge
              Positioned(
                top: 20,
                right: 20,
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
            ],
          ),

          // Booking information section
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking Information',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryBlack,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildInfoItem(
                  'Booking ID',
                  '#${booking.id!.substring(0, 8).toUpperCase()}',
                  Icons.confirmation_number,
                ),
                const Divider(),
                _buildInfoItem(
                  'Pick-up Date',
                  dateFormat.format(booking.startDate),
                  Icons.calendar_today,
                ),
                const SizedBox(height: 12),
                _buildInfoItem(
                  'Return Date',
                  dateFormat.format(booking.endDate),
                  Icons.event,
                ),
                const Divider(),
                _buildInfoItem(
                  'Duration',
                  '${booking.endDate.difference(booking.startDate).inDays + 1} days',
                  Icons.timelapse,
                ),
                const SizedBox(height: 12),
                _buildInfoItem(
                  'Total Price',
                  '₹${booking.totalPrice.toStringAsFixed(0)}',
                  Icons.currency_rupee,
                  isBold: true,
                ),
                const Divider(),
                const SizedBox(height: 20),

                // Payment Summary
                _buildPaymentSummary(booking),
                const SizedBox(height: 30),

                // Actions
                if (booking.status.toLowerCase() == 'pending' ||
                    booking.status.toLowerCase() == 'confirmed')
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          buttonText: 'Cancel Booking',
                          onPressed: () => _showCancelDialog(context, booking),
                          backgroundColor: Colors.red[700]!,
                          textColor: Colors.white,
                          borderRadius: 8,
                          icon: Icons.cancel,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (booking.status.toLowerCase() == 'pending')
                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            buttonText: 'Modify Dates',
                            onPressed: () {
                              // Navigate to a page for modifying the booking
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Modify feature coming soon!'),
                                ),
                              );
                            },
                            backgroundColor: darkGrey,
                            textColor: Colors.white,
                            borderRadius: 8,
                            icon: Icons.edit_calendar,
                          ),
                        ),
                    ],
                  )
                else if (booking.status.toLowerCase() == 'completed')
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      buttonText: 'Rate Your Experience',
                      onPressed: () {
                        // Navigate to rating screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Rating feature coming soon!'),
                          ),
                        );
                      },
                      backgroundColor: primaryGold,
                      textColor: Colors.white,
                      borderRadius: 8,
                      icon: Icons.star,
                    ),
                  ),
              ],
            ),
          ),

          // Additional information
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Need Help?',
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryBlack,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.summarize, size: 20),
                      label: const Text('View Summary'),
                      onPressed: () => _showBookingSummary(booking),
                      style: TextButton.styleFrom(
                        foregroundColor: primaryGold,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () {
                    // Launch contact support
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contact support feature coming soon!'),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.support_agent, color: primaryGold),
                        const SizedBox(width: 12),
                        Text(
                          'Contact Customer Support',
                          style: GoogleFonts.poppins(
                            textStyle: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon,
      {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: primaryGold, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                      color: isBold ? primaryBlack : Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  void _generateBookingTicket(BuildContext context, Booking booking) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');
    // Show ticket preview dialog
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: primaryBlack,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.confirmation_number,
                      color: primaryGold, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Booking Ticket',
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Stack(
              children: [
                // Ticket content
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                  child: Column(
                    children: [
                      // Header
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              booking.carImageUrl,
                              height: 70,
                              width: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 70,
                                  width: 100,
                                  color: Colors.grey[300],
                                  child: Icon(
                                    Icons.car_rental,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.carModel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(booking.status)
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    booking.status[0].toUpperCase() +
                                        booking.status.substring(1),
                                    style: TextStyle(
                                      color: _getStatusColor(booking.status),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Dashed line with car icons
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: primaryGold, size: 20),
                          Expanded(
                            child: CustomPaint(
                              size: const Size(double.infinity, 1),
                              painter: DashedLinePainter(),
                            ),
                          ),
                          Transform.rotate(
                            angle: 3.14, // 180 degrees in radians
                            child: const Icon(Icons.location_on,
                                color: primaryGold, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Pick-up and return dates
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PICK-UP DATE',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                dateFormat.format(booking.startDate),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'RETURN DATE',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                dateFormat.format(booking.endDate),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Price and duration
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTicketInfoBox('BOOKING ID',
                              '#${booking.id!.substring(0, 8).toUpperCase()}'),
                          _buildTicketInfoBox('DURATION',
                              '${booking.endDate.difference(booking.startDate).inDays + 1} days'),
                          _buildTicketInfoBox('PRICE',
                              '₹${booking.totalPrice.toStringAsFixed(0)}'),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Barcode section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.grey.shade300, width: 1),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'SCAN VERIFICATION CODE',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: List.generate(
                                  10,
                                  (index) => Container(
                                    width: 3,
                                    color: Colors.black,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SelectableText(
                              booking.id != null
                                  ? booking.id!.substring(0, 10).toUpperCase()
                                  : 'INVALID CODE',
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Circular cutouts
                Positioned(
                  left: -15,
                  top: 120,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  right: -15,
                  top: 120,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),

            // Footer actions
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Save Ticket'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlack,
                      foregroundColor: primaryGold,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ticket saved successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
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

  Widget _buildTicketInfoBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingSummary(Booking booking) {
    final dateFormat = DateFormat('EEEE, MMM dd, yyyy');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: primaryBlack,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Booking Summary',
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        color: primaryGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          booking.carImageUrl,
                          height: 80,
                          width: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 80,
                              width: 120,
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.car_rental,
                                size: 50,
                                color: Colors.grey[400],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.carModel,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(booking.status)
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                booking.status[0].toUpperCase() +
                                    booking.status.substring(1),
                                style: TextStyle(
                                  color: _getStatusColor(booking.status),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildSummaryItem('Booking ID',
                      '#${booking.id!.substring(0, 8).toUpperCase()}'),
                  _buildSummaryItem(
                      'Pick-up Date', dateFormat.format(booking.startDate)),
                  _buildSummaryItem(
                      'Return Date', dateFormat.format(booking.endDate)),
                  _buildSummaryItem('Duration',
                      '${booking.endDate.difference(booking.startDate).inDays + 1} days'),
                  _buildSummaryItem('Total Price',
                      '₹${booking.totalPrice.toStringAsFixed(0)}',
                      isBold: true),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.download),
                        label: const Text('Save as PDF'),
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('PDF generation feature coming soon!'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlack,
                          foregroundColor: primaryGold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.print),
                        label: const Text('Print'),
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Print feature coming soon!'),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryBlack,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.purple;
      case 'pending':
      default:
        return Colors.blue;
    }
  }

  Widget _buildPaymentSummary(Booking booking) {
    // Calculate the rental duration in days
    final rentalDays = booking.endDate.difference(booking.startDate).inDays + 1;

    // Base rate per day (assuming total price is base rate * days + taxes & fees)
    final baseDailyRate = (booking.totalPrice * 0.8) / rentalDays;
    final taxes = booking.totalPrice * 0.12;
    final serviceFee = booking.totalPrice * 0.08;

    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt, color: primaryGold, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Payment Summary',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPaymentRow(
              'Base Rate',
              '₹${baseDailyRate.toStringAsFixed(0)} × $rentalDays days',
              '₹${(baseDailyRate * rentalDays).toStringAsFixed(0)}',
            ),
            const SizedBox(height: 8),
            _buildPaymentRow(
              'Taxes (12%)',
              '',
              '₹${taxes.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 8),
            _buildPaymentRow(
              'Service Fee',
              '',
              '₹${serviceFee.toStringAsFixed(0)}',
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(),
            ),
            _buildPaymentRow(
              'Total Amount',
              '',
              '₹${booking.totalPrice.toStringAsFixed(0)}',
              isTotal: true,
            ),
            const SizedBox(height: 12),

            // Payment status
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Paid',
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Payment Completed',
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, String description, String amount,
      {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    fontSize: isTotal ? 15 : 14,
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    color: isTotal ? primaryBlack : Colors.grey[700],
                  ),
                ),
              ),
              if (description.isNotEmpty)
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            amount,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              textStyle: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isTotal ? primaryBlack : Colors.grey[800],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DashedLinePainter extends CustomPainter {
  static const Color primaryGold = Color(0xFFDAA520);

  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 5, dashSpace = 3, startX = 0;
    final paint = Paint()
      ..color = primaryGold
      ..strokeWidth = 1.5;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

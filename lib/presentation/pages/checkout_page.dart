import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rentapp/data/models/booking.dart';
import 'package:rentapp/data/models/car.dart';
import 'package:rentapp/presentation/pages/my_bookings_screen.dart';
import 'package:rentapp/presentation/bloc/booking_bloc.dart';
import 'package:rentapp/presentation/bloc/booking_event.dart';
import 'package:rentapp/presentation/bloc/booking_state.dart';

class CheckoutPage extends StatefulWidget {
  final Car car;
  final Booking booking;

  const CheckoutPage({
    Key? key,
    required this.car,
    required this.booking,
  }) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _nameOnCardController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _nameOnCardController.dispose();
    super.dispose();
  }

  void _processPayment() {
    if (_validatePaymentDetails()) {
      setState(() {
        _isProcessing = true;
      });

      // Create a confirmed booking
      final confirmedBooking = widget.booking.copyWith(status: 'confirmed');

      // Use the BookingBloc to create the booking
      context.read<BookingBloc>().add(
            CreateBooking(booking: confirmedBooking),
          );
    }
  }

  bool _validatePaymentDetails() {
    // Simple validation
    if (_cardNumberController.text.length < 16) {
      _showError('Please enter a valid card number');
      return false;
    }

    if (_expiryDateController.text.length < 5) {
      _showError('Please enter a valid expiry date (MM/YY)');
      return false;
    }

    if (_cvvController.text.length < 3) {
      _showError('Please enter a valid CVV');
      return false;
    }

    if (_nameOnCardController.text.isEmpty) {
      _showError('Please enter the name on card');
      return false;
    }

    return true;
  }

  void _showError(String message) {
    // Dismiss any existing snackbars
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Show an error dialog for more prominence
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: BlocConsumer<BookingBloc, BookingState>(listener: (context, state) {
        if (state is BookingCreated) {
          setState(() {
            _isProcessing = false;
          });
          _showBookingConfirmation(state.booking.id ?? 'Unknown');
        } else if (state is BookingError) {
          setState(() {
            _isProcessing = false;
          });
          _showError(state.message);
        }
      }, builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBookingSummary(),
              const SizedBox(height: 30),
              _buildPaymentForm(),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: state is BookingLoading || _isProcessing
                      ? null
                      : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: state is BookingLoading || _isProcessing
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2.0,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text('Processing...',
                                style: TextStyle(fontSize: 16)),
                          ],
                        )
                      : const Text(
                          'Pay Now',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBookingSummary() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildSummaryRow('Car', '${widget.car.brand} ${widget.car.model}'),
            _buildSummaryRow(
                'Start Date', _formatDate(widget.booking.startDate)),
            _buildSummaryRow('End Date', _formatDate(widget.booking.endDate)),
            _buildSummaryRow('Duration', _calculateDuration()),
            const Divider(),
            _buildSummaryRow(
              'Total Amount',
              '₹${widget.booking.totalPrice.toStringAsFixed(2)}',
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameOnCardController,
          decoration: InputDecoration(
            labelText: 'Name on Card',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _cardNumberController,
          decoration: InputDecoration(
            labelText: 'Card Number',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.credit_card),
          ),
          keyboardType: TextInputType.number,
          maxLength: 16,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expiryDateController,
                decoration: InputDecoration(
                  labelText: 'Expiry Date (MM/YY)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 5,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _cvvController,
                decoration: InputDecoration(
                  labelText: 'CVV',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _calculateDuration() {
    final difference =
        widget.booking.endDate.difference(widget.booking.startDate);
    final days = difference.inDays;
    final hours = difference.inHours % 24;

    if (days > 0) {
      return '$days days${hours > 0 ? ' $hours hours' : ''}';
    } else {
      return '${difference.inHours} hours';
    }
  }

  void _showBookingConfirmation(String bookingId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Booking Confirmed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text('Booking ID: $bookingId'),
            const SizedBox(height: 8),
            const Text(
              'Your booking has been confirmed. You can find your booking details in the My Bookings section.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Navigate to My Bookings screen
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => MyBookingsScreen(),
                ),
                (route) => false,
              );
            },
            child: const Text('View My Bookings'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }
}

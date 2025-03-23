import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:rentapp/data/models/car.dart';
import 'package:intl/intl.dart';
import 'package:rentapp/presentation/pages/my_bookings_screen.dart';
import 'package:rentapp/data/models/booking.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentapp/presentation/pages/checkout_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MapsDetailsPage extends StatefulWidget {
  final Car car;

  const MapsDetailsPage({Key? key, required this.car}) : super(key: key);

  @override
  _MapsDetailsPageState createState() => _MapsDetailsPageState();
}

class _MapsDetailsPageState extends State<MapsDetailsPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // Default location (can be replaced with actual car location)
  final LatLng _carLocation = LatLng(37.7749, -122.4194);

  // Modern luxury theme colors
  static const Color primaryColor = Color(0xFF1E1E1E);
  static const Color accentColor = Color(0xFFE0AA3E);
  static const Color backgroundColor = Color(0xFFF9F9F9);
  static const Color cardColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF1E1E1E);
  static const Color textSecondaryColor = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: primaryColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text(
          'Booking Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3.0,
                color: Colors.black.withOpacity(0.5),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Map Section
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: _carLocation,
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _carLocation,
                          width: 120,
                          height: 120,
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.directions_car,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 6),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Available',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.my_location,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Booking Form
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Car Overview
                    Row(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: widget.car.imageUrl != null
                                  ? AssetImage(widget.car.imageUrl!)
                                  : AssetImage('assets/car_image.png'),
                              fit: BoxFit.cover,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.car.brand} ${widget.car.model}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimaryColor,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.star,
                                      color: accentColor, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    '${widget.car.rating}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: textPrimaryColor,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Icon(Icons.location_on,
                                      color: textSecondaryColor, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    '${widget.car.distance} km away',
                                    style: TextStyle(
                                      color: textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                '₹${widget.car.pricePerHour}/hour',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 30),

                    // Date Selection Section
                    Text(
                      'Select Date & Time',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimaryColor,
                      ),
                    ),
                    SizedBox(height: 20),

                    // Date Pickers
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildDatePickerField(
                            'Start Date',
                            _startDate,
                            () => _selectStartDate(context),
                            Icons.calendar_today,
                          ),
                          Divider(height: 30),
                          _buildDatePickerField(
                            'End Date',
                            _endDate,
                            () => _selectEndDate(context),
                            Icons.calendar_today,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 30),

                    // Time Selection Section
                    Text(
                      'Select Pick-up & Return Time',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimaryColor,
                      ),
                    ),
                    SizedBox(height: 20),

                    // Time Pickers
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildTimePickerField(
                            'Pick-up Time',
                            _startTime,
                            () => _selectStartTime(context),
                            Icons.access_time,
                          ),
                          Divider(height: 30),
                          _buildTimePickerField(
                            'Return Time',
                            _endTime,
                            () => _selectEndTime(context),
                            Icons.access_time,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 30),

                    // Booking Summary
                    if (_startDate != null && _endDate != null)
                      _buildBookingSummary(),

                    SizedBox(height: 30),

                    // Book Now Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_isFormValid()) {
                            _navigateToCheckout();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[400],
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline),
                            SizedBox(width: 10),
                            Text(
                              'Confirm Booking',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerField(
      String label, DateTime? selectedDate, Function() onTap, IconData icon) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 24,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  selectedDate == null
                      ? 'Select date'
                      : DateFormat('dd MMM, yyyy').format(selectedDate),
                  style: TextStyle(
                    color: textPrimaryColor,
                    fontSize: 16,
                    fontWeight: selectedDate == null
                        ? FontWeight.normal
                        : FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: textSecondaryColor,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerField(
      String label, TimeOfDay? selectedTime, Function() onTap, IconData icon) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 24,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  selectedTime == null
                      ? 'Select time'
                      : _formatTimeOfDay(selectedTime),
                  style: TextStyle(
                    color: textPrimaryColor,
                    fontSize: 16,
                    fontWeight: selectedTime == null
                        ? FontWeight.normal
                        : FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: textSecondaryColor,
            size: 16,
          ),
        ],
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final now = DateTime.now();
    final dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
    return DateFormat('hh:mm a').format(dateTime);
  }

  Widget _buildBookingSummary() {
    // Calculate duration in hours
    final difference = _calculateDuration();
    final hours = difference.inHours;

    // Calculate total price
    final totalPrice = hours * widget.car.pricePerHour;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimaryColor,
            ),
          ),
          SizedBox(height: 20),
          _buildSummaryRow('Duration', '$hours hours'),
          SizedBox(height: 10),
          _buildSummaryRow('Price per hour', '₹${widget.car.pricePerHour}'),
          SizedBox(height: 10),
          _buildSummaryRow('Booking fee',
              '₹${(widget.car.pricePerHour * 0.1).toStringAsFixed(0)}'),
          Divider(height: 30),
          _buildSummaryRow(
            'Total Price',
            '₹${totalPrice.toStringAsFixed(0)}',
            textStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {TextStyle? textStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textSecondaryColor,
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: textStyle ??
              TextStyle(
                fontWeight: FontWeight.bold,
                color: textPrimaryColor,
                fontSize: 16,
              ),
        ),
      ],
    );
  }

  Duration _calculateDuration() {
    if (_startDate == null ||
        _endDate == null ||
        _startTime == null ||
        _endTime == null) {
      return Duration.zero;
    }

    final start = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    final end = DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    return end.difference(start);
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Reset end date if it's before start date
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a start date first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate!,
      firstDate: _startDate!,
      lastDate: _startDate!.add(Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a start date first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    if (_endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an end date first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  bool _isFormValid() {
    return _startDate != null &&
        _endDate != null &&
        _startTime != null &&
        _endTime != null;
  }

  void _showBookingSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                'Booking Confirmed!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your booking for ${widget.car.brand} ${widget.car.model} has been confirmed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textSecondaryColor,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildConfirmationDetail('Start',
                        '${DateFormat('dd MMM, yyyy').format(_startDate!)} at ${_formatTimeOfDay(_startTime!)}'),
                    const SizedBox(height: 10),
                    _buildConfirmationDetail('End',
                        '${DateFormat('dd MMM, yyyy').format(_endDate!)} at ${_formatTimeOfDay(_endTime!)}'),
                    const SizedBox(height: 10),
                    _buildConfirmationDetail('Booking ID',
                        '#${DateTime.now().millisecondsSinceEpoch.toString().substring(5, 13)}'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to previous screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyBookingsScreen(),
                  ),
                );
              },
              child: Text(
                'View My Bookings',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConfirmationDetail(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textSecondaryColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimaryColor,
          ),
        ),
      ],
    );
  }

  // Helper method to calculate the total price
  double _calculateTotalPrice() {
    final difference = _calculateDuration();
    final hours = difference.inHours;
    return hours * widget.car.pricePerHour;
  }

  // Method to navigate to checkout
  void _navigateToCheckout() {
    // Create a start and end datetime that combines date and time
    final startDateTime = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    final endDateTime = DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    final totalPrice = _calculateTotalPrice();

    // Create booking object
    final booking = Booking(
      userId: FirebaseAuth.instance.currentUser?.uid ?? 'guestUser',
      carId: widget.car.id ?? 'unknown',
      carName: widget.car.name,
      carModel: '${widget.car.brand} ${widget.car.model}',
      carImageUrl: widget.car.imageUrl ?? 'assets/car_image.png',
      startDate: startDateTime,
      endDate: endDateTime,
      totalPrice: totalPrice,
      status: 'pending',
    );

    // Navigate to checkout page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutPage(
          car: widget.car,
          booking: booking,
        ),
      ),
    );
  }
}

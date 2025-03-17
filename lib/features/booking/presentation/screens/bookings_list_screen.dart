import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/booking_bloc.dart';
import '../../domain/models/booking_model.dart';

class BookingsListScreen extends StatefulWidget {
  const BookingsListScreen({super.key});

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BookingBloc>().add(LoadUserBookings());
  }

  void _showModifyDialog(BookingModel booking) {
    DateTime? newStartDate;
    DateTime? newEndDate;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Modify Booking'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Start Date'),
                  subtitle: Text(
                    DateFormat('MMM dd, yyyy').format(booking.startDate),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: booking.startDate,
                      firstDate: DateTime.now(),
                      lastDate: booking.endDate,
                    );
                    if (date != null) {
                      newStartDate = date;
                    }
                  },
                ),
                ListTile(
                  title: const Text('End Date'),
                  subtitle: Text(
                    DateFormat('MMM dd, yyyy').format(booking.endDate),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: booking.endDate,
                      firstDate: newStartDate ?? booking.startDate,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      newEndDate = date;
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (newStartDate != null || newEndDate != null) {
                    context.read<BookingBloc>().add(
                      ModifyBooking(
                        bookingId: booking.id,
                        startDate: newStartDate,
                        endDate: newEndDate,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Modify'),
              ),
            ],
          ),
    );
  }

  void _showCancelDialog(BookingModel booking) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Booking'),
            content: const Text(
              'Are you sure you want to cancel this booking?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<BookingBloc>().add(CancelBooking(booking.id));
                  Navigator.pop(context);
                },
                child: const Text('Yes'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: BlocConsumer<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is BookingError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is BookingLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BookingsLoaded) {
            if (state.bookings.isEmpty) {
              return const Center(child: Text('No bookings found'));
            }

            return ListView.builder(
              itemCount: state.bookings.length,
              itemBuilder: (context, index) {
                final booking = state.bookings[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text('Booking #${booking.id.substring(0, 8)}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Car ID: ${booking.carId.substring(0, 8)}'),
                        Text(
                          'Dates: ${DateFormat('MMM dd, yyyy').format(booking.startDate)} - ${DateFormat('MMM dd, yyyy').format(booking.endDate)}',
                        ),
                        Text(
                          'Total: \$${booking.totalPrice.toStringAsFixed(2)}',
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(booking.status),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            booking.status.toString().split('.').last,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing:
                        booking.status == BookingStatus.pending ||
                                booking.status == BookingStatus.confirmed
                            ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showModifyDialog(booking),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel),
                                  onPressed: () => _showCancelDialog(booking),
                                ),
                              ],
                            )
                            : null,
                  ),
                );
              },
            );
          }

          return const Center(child: Text('Something went wrong'));
        },
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.completed:
        return Colors.blue;
      case BookingStatus.rejected:
        return Colors.purple;
    }
  }
}

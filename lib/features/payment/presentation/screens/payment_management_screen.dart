import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/models/payment_model.dart';
import '../../presentation/bloc/payment_bloc.dart';

class PaymentManagementScreen extends StatelessWidget {
  const PaymentManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        if (state is PaymentLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is PaymentsLoaded) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Payment Management',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    DropdownButton<String>(
                      value: 'all',
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('All Payments'),
                        ),
                        DropdownMenuItem(
                          value: 'pending',
                          child: Text('Pending'),
                        ),
                        DropdownMenuItem(
                          value: 'completed',
                          child: Text('Completed'),
                        ),
                        DropdownMenuItem(
                          value: 'failed',
                          child: Text('Failed'),
                        ),
                        DropdownMenuItem(
                          value: 'refunded',
                          child: Text('Refunded'),
                        ),
                      ],
                      onChanged: (value) {
                        // TODO: Implement filtering
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: state.payments.length,
                  itemBuilder: (context, index) {
                    final payment = state.payments[index];
                    return _buildPaymentCard(context, payment);
                  },
                ),
              ),
            ],
          );
        }

        return const Center(child: Text('Failed to load payments'));
      },
    );
  }

  Widget _buildPaymentCard(BuildContext context, PaymentModel payment) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment #${payment.id.substring(0, 8)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Booking #${payment.bookingId.substring(0, 8)}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(payment.status),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'view':
                        // TODO: Navigate to payment details
                        break;
                      case 'refund':
                        _showRefundConfirmation(context, payment);
                        break;
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility),
                              SizedBox(width: 8),
                              Text('View Details'),
                            ],
                          ),
                        ),
                        if (payment.status == PaymentStatus.completed)
                          PopupMenuItem(
                            value: 'refund',
                            child: Row(
                              children: [
                                Icon(Icons.assignment_return),
                                SizedBox(width: 8),
                                Text('Refund'),
                              ],
                            ),
                          ),
                      ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoChip(
                  'Amount',
                  '\$${payment.amount.toStringAsFixed(2)}',
                ),
                _buildInfoChip(
                  'Method',
                  payment.method.toString().split('.').last,
                ),
                _buildInfoChip(
                  'Date',
                  DateFormat('MMM dd, yyyy').format(payment.createdAt),
                ),
              ],
            ),
            if (payment.transactionId != null) ...[
              const SizedBox(height: 8),
              Text(
                'Transaction ID: ${payment.transactionId}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(PaymentStatus status) {
    Color color;
    switch (status) {
      case PaymentStatus.pending:
        color = Colors.orange;
        break;
      case PaymentStatus.processing:
        color = Colors.blue;
        break;
      case PaymentStatus.completed:
        color = Colors.green;
        break;
      case PaymentStatus.failed:
        color = Colors.red;
        break;
      case PaymentStatus.refunded:
        color = Colors.purple;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.toString().split('.').last.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showRefundConfirmation(BuildContext context, PaymentModel payment) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Refund Payment'),
            content: Text(
              'Are you sure you want to refund payment #${payment.id.substring(0, 8)}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Implement refund payment
                  Navigator.pop(context);
                },
                child: const Text('Refund'),
              ),
            ],
          ),
    );
  }
}

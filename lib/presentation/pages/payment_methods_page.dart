import 'package:flutter/material.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({Key? key}) : super(key: key);

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  // Theme colors
  static const Color primaryGold = Color(0xFFDAA520);
  static const Color primaryBlack = Color(0xFF121212);
  static const Color lightGrey = Color(0xFFF5F5F5);

  // Sample payment methods
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'type': 'credit_card',
      'name': 'VISA •••• 4242',
      'isDefault': true,
      'expiryDate': '12/25',
    },
    {
      'type': 'upi',
      'name': 'UPI ID: username@bank',
      'isDefault': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payment Methods',
          style: TextStyle(
            color: primaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: primaryGold),
        backgroundColor: primaryBlack,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Saved Payment Methods',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          Expanded(
            child: _paymentMethods.isEmpty
                ? _buildEmptyState()
                : _buildPaymentMethodsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPaymentMethodDialog,
        backgroundColor: primaryGold,
        child: const Icon(Icons.add, color: primaryBlack),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.credit_card,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No payment methods added yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add a new payment method',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsList() {
    return ListView.builder(
      itemCount: _paymentMethods.length,
      itemBuilder: (context, index) {
        final method = _paymentMethods[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(
              method['type'] == 'credit_card'
                  ? Icons.credit_card
                  : Icons.account_balance,
              color: primaryGold,
            ),
            title: Text(method['name']),
            subtitle: method.containsKey('expiryDate')
                ? Text('Expires: ${method['expiryDate']}')
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (method['isDefault'])
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Default',
                      style: TextStyle(
                        fontSize: 12,
                        color: primaryGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showPaymentMethodOptions(method),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddPaymentMethodDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Feature Coming Soon'),
        content: const Text(
          'This feature will be available in the next update. Please check back later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPaymentMethodOptions(Map<String, dynamic> method) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.check_circle),
            title: const Text('Set as Default'),
            onTap: () {
              Navigator.pop(context);
              _showComingSoonSnackbar();
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () {
              Navigator.pop(context);
              _showComingSoonSnackbar();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Remove', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showComingSoonSnackbar();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showComingSoonSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature is coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

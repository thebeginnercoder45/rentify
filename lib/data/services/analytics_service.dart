import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AdminAnalytics {
  final int totalCars;
  final int activeBookings;
  final int totalUsers;
  final double totalRevenue;

  AdminAnalytics({
    required this.totalCars,
    required this.activeBookings,
    required this.totalUsers,
    required this.totalRevenue,
  });

  @override
  String toString() {
    return 'AdminAnalytics(totalCars: $totalCars, activeBookings: $activeBookings, totalUsers: $totalUsers, totalRevenue: $totalRevenue)';
  }
}

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch all analytics data for the admin dashboard
  Future<AdminAnalytics> getAdminAnalytics() async {
    debugPrint('Fetching admin analytics...');

    final totalCars = await _getTotalCars();
    final activeBookings = await _getActiveBookings();
    final totalUsers = await _getTotalUsers();
    final totalRevenue = await _calculateTotalRevenue();

    final analytics = AdminAnalytics(
      totalCars: totalCars,
      activeBookings: activeBookings,
      totalUsers: totalUsers,
      totalRevenue: totalRevenue,
    );

    debugPrint('Analytics retrieved: $analytics');
    return analytics;
  }

  // Get the total number of cars in the system
  Future<int> _getTotalCars() async {
    try {
      // First try with count() method
      try {
        final snapshot = await _firestore.collection('cars').count().get();
        final count = snapshot.count ?? 0;
        debugPrint('Total cars from count(): $count');
        return count;
      } catch (countError) {
        // Fallback to getting all documents if count() is not supported
        debugPrint(
            'Count operation failed, fetching all car documents: $countError');
        final querySnapshot = await _firestore.collection('cars').get();
        final count = querySnapshot.docs.length;
        debugPrint('Total cars from docs.length: $count');
        return count;
      }
    } catch (e) {
      debugPrint('Error getting total cars: $e');
      return 0;
    }
  }

  // Get the number of active (current/upcoming) bookings
  Future<int> _getActiveBookings() async {
    try {
      final now = DateTime.now();
      debugPrint('Checking for active bookings after ${now.toIso8601String()}');

      // First try with the count() method
      try {
        final snapshot = await _firestore
            .collection('bookings')
            .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
            .where('status', isEqualTo: 'confirmed')
            .count()
            .get();

        final count = snapshot.count ?? 0;
        debugPrint('Active bookings from count(): $count');
        return count;
      } catch (countError) {
        // Fallback method if count() is not supported
        debugPrint(
            'Count operation failed, fetching all booking documents: $countError');
        final querySnapshot = await _firestore
            .collection('bookings')
            .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
            .where('status', isEqualTo: 'confirmed')
            .get();

        final count = querySnapshot.docs.length;
        debugPrint('Active bookings from docs.length: $count');
        return count;
      }
    } catch (e) {
      debugPrint('Error getting active bookings: $e');
      return 0;
    }
  }

  // Get the total number of users
  Future<int> _getTotalUsers() async {
    try {
      // First try with count() method
      try {
        final snapshot = await _firestore.collection('users').count().get();
        final count = snapshot.count ?? 0;
        debugPrint('Total users from count(): $count');
        return count;
      } catch (countError) {
        // Fallback to getting all documents if count() is not supported
        debugPrint(
            'Count operation failed, fetching all user documents: $countError');
        final querySnapshot = await _firestore.collection('users').get();
        final count = querySnapshot.docs.length;
        debugPrint('Total users from docs.length: $count');
        return count;
      }
    } catch (e) {
      debugPrint('Error getting total users: $e');
      return 0;
    }
  }

  /// Calculate total revenue from confirmed bookings
  Future<double> _calculateTotalRevenue() async {
    try {
      // Get all confirmed bookings
      final querySnapshot = await _firestore
          .collection('bookings')
          .get(); // Get all bookings first, then filter for more reliable results

      debugPrint(
          'Retrieved ${querySnapshot.docs.length} bookings for revenue calculation');

      // Sum up the total price from all bookings
      double totalRevenue = 0;
      int confirmedCount = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final bookingId = doc.id;
        final status = data['status'] as String?;

        // Only include confirmed bookings in revenue
        if (status == 'confirmed') {
          confirmedCount++;

          if (data.containsKey('totalPrice')) {
            var price = data['totalPrice'];
            double? priceValue;

            if (price is double) {
              priceValue = price;
            } else if (price is int) {
              priceValue = price.toDouble();
            } else if (price is String) {
              priceValue = double.tryParse(price);
            }

            if (priceValue != null) {
              totalRevenue += priceValue;
              debugPrint(
                  'Added booking #$bookingId with price: $priceValue (total so far: $totalRevenue)');
            } else {
              debugPrint(
                  'Warning: Could not parse price for booking #$bookingId: $price');
            }
          } else {
            debugPrint('Warning: Booking #$bookingId has no totalPrice field');
          }
        }
      }

      debugPrint(
          'Total revenue calculation: $totalRevenue from $confirmedCount confirmed bookings');
      return totalRevenue;
    } catch (e) {
      debugPrint('Error calculating total revenue: $e');
      return 0.0;
    }
  }
}

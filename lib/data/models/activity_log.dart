import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

enum ActivityType {
  carAdded,
  carUpdated,
  carDeleted,
  bookingCreated,
  bookingUpdated,
  bookingCancelled,
  userRegistered,
  userUpdated,
  systemUpdate,
}

class ActivityLog {
  final String id;
  final ActivityType type;
  final String title;
  final String description;
  final String? userId;
  final String? relatedId; // e.g., car ID, booking ID, etc.
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  ActivityLog({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.userId,
    this.relatedId,
    required this.timestamp,
    this.metadata = const {},
  });

  // Get the icon data for this activity
  IconData get icon {
    switch (type) {
      case ActivityType.carAdded:
      case ActivityType.carUpdated:
      case ActivityType.carDeleted:
        return Icons.directions_car;
      case ActivityType.bookingCreated:
      case ActivityType.bookingUpdated:
      case ActivityType.bookingCancelled:
        return Icons.calendar_today;
      case ActivityType.userRegistered:
      case ActivityType.userUpdated:
        return Icons.person;
      case ActivityType.systemUpdate:
        return Icons.system_update;
    }
  }

  // Get formatted time string (e.g., "10 mins ago")
  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'min' : 'mins'} ago';
    } else {
      return 'Just now';
    }
  }

  factory ActivityLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ActivityLog(
      id: doc.id,
      type: _parseActivityType(data['type'] ?? 'systemUpdate'),
      title: data['title'] ?? 'System Update',
      description: data['description'] ?? 'An update was made to the system',
      userId: data['userId'],
      relatedId: data['relatedId'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.toString().split('.').last,
      'title': title,
      'description': description,
      'userId': userId,
      'relatedId': relatedId,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }

  static ActivityType _parseActivityType(String typeStr) {
    switch (typeStr) {
      case 'carAdded':
        return ActivityType.carAdded;
      case 'carUpdated':
        return ActivityType.carUpdated;
      case 'carDeleted':
        return ActivityType.carDeleted;
      case 'bookingCreated':
        return ActivityType.bookingCreated;
      case 'bookingUpdated':
        return ActivityType.bookingUpdated;
      case 'bookingCancelled':
        return ActivityType.bookingCancelled;
      case 'userRegistered':
        return ActivityType.userRegistered;
      case 'userUpdated':
        return ActivityType.userUpdated;
      case 'systemUpdate':
      default:
        return ActivityType.systemUpdate;
    }
  }
}

// Helper class to log activities
class ActivityLogger {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _activityCollection =
      _firestore.collection('activityLogs');

  // Log a new car added activity
  static Future<void> logCarAdded(
      String carId, String carName, String userId) async {
    debugPrint(
        'Logging car added activity: carId=$carId, carName=$carName, userId=$userId');
    await _logActivity(
      type: ActivityType.carAdded,
      title: 'New Car Added',
      description: '$carName was added to the fleet',
      userId: userId,
      relatedId: carId,
    );
  }

  // Log a booking confirmed activity
  static Future<void> logBookingConfirmed(
      String bookingId, String userId) async {
    debugPrint(
        'Logging booking confirmed activity: bookingId=$bookingId, userId=$userId');
    await _logActivity(
      type: ActivityType.bookingCreated,
      title: 'Booking Confirmed',
      description: 'Booking #$bookingId was confirmed',
      userId: userId,
      relatedId: bookingId,
    );
  }

  // Log a user registered activity
  static Future<void> logUserRegistered(String userId, String userName) async {
    debugPrint(
        'Logging user registered activity: userId=$userId, userName=$userName');
    await _logActivity(
      type: ActivityType.userRegistered,
      title: 'New User Registered',
      description: '$userName created a new account',
      userId: userId,
    );
  }

  // Generic activity logging method
  static Future<void> _logActivity({
    required ActivityType type,
    required String title,
    required String description,
    String? userId,
    String? relatedId,
    Map<String, dynamic> metadata = const {},
    DateTime? timestamp,
  }) async {
    try {
      final activity = ActivityLog(
        id: '', // Will be assigned by Firestore
        type: type,
        title: title,
        description: description,
        userId: userId,
        relatedId: relatedId,
        timestamp: timestamp ?? DateTime.now(),
        metadata: metadata,
      );

      debugPrint('Creating activity log: $title, type=${type.toString()}');
      final docRef = await _activityCollection.add(activity.toFirestore());
      debugPrint('Activity log created with ID: ${docRef.id}');
    } catch (e) {
      debugPrint('Error logging activity: $e');
    }
  }

  // Public method for seeding test data
  static Future<void> seedActivityLog({
    required ActivityType type,
    required String title,
    required String description,
    String? userId,
    String? relatedId,
    Map<String, dynamic> metadata = const {},
    DateTime? timestamp,
  }) async {
    debugPrint(
        'Seeding activity log: $title, type=${type.toString()}, timestamp=${timestamp?.toIso8601String() ?? 'now'}');
    await _logActivity(
      type: type,
      title: title,
      description: description,
      userId: userId,
      relatedId: relatedId,
      metadata: metadata,
      timestamp: timestamp,
    );
  }

  // Get recent activities
  static Future<List<ActivityLog>> getRecentActivities({int limit = 10}) async {
    try {
      debugPrint('Fetching recent activities, limit=$limit');
      final querySnapshot = await _activityCollection
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      debugPrint('Found ${querySnapshot.docs.length} recent activities');

      if (querySnapshot.docs.isEmpty) {
        debugPrint('No activity logs found in the collection');
      } else {
        debugPrint('First activity: ${querySnapshot.docs.first.data()}');
      }

      final activities = querySnapshot.docs
          .map((doc) {
            try {
              return ActivityLog.fromFirestore(doc);
            } catch (e) {
              debugPrint('Error parsing activity log document ${doc.id}: $e');
              return null;
            }
          })
          .whereType<ActivityLog>() // Filter out null values
          .toList();

      debugPrint('Successfully parsed ${activities.length} activity logs');
      return activities;
    } catch (e) {
      debugPrint('Error fetching recent activities: $e');
      return [];
    }
  }
}

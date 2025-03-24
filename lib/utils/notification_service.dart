import 'dart:io';
import 'package:flutter/material.dart';

/// A simplified notification service that logs notifications instead of showing them.
/// This is a temporary solution until the flutter_local_notifications package issues are resolved.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  NotificationService._();

  Future<void> init() async {
    debugPrint('Mock Notification service initialized');
  }

  // Log an immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String payload = '',
  }) async {
    debugPrint('MOCK NOTIFICATION: $id, $title, $body');
  }

  // Log a scheduled notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String payload = '',
  }) async {
    debugPrint(
        'MOCK SCHEDULED NOTIFICATION for ${scheduledDate.toString()}: $id, $title, $body');
  }

  // Set notification for reminder (specialized for car rental)
  Future<void> setRentalReminder({
    required int id,
    required String carName,
    required DateTime rentalDateTime,
    int reminderMinutesBefore = 60, // Default 1 hour before
  }) async {
    final reminderTime =
        rentalDateTime.subtract(Duration(minutes: reminderMinutesBefore));

    // Only set reminder if it's in the future
    if (reminderTime.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: id,
        title: 'Rental Reminder',
        body:
            'Your booking for $carName is scheduled in ${reminderMinutesBefore ~/ 60} hour(s).',
        scheduledDate: reminderTime,
        payload: 'rental_reminder_$id',
      );

      debugPrint(
          'MOCK: Set rental reminder for $carName at ${reminderTime.toString()}');
      return;
    }

    debugPrint(
        'MOCK: Skipped setting reminder for $carName as the time has already passed');
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    debugPrint('MOCK: Cancelled all notifications');
  }

  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    debugPrint('MOCK: Cancelled notification with ID: $id');
  }
}

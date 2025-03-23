import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String? id;
  final String userId;
  final String carId;
  final String carName;
  final String carModel;
  final String carImageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final Map<String, dynamic>? extras;
  final DateTime createdAt;

  Booking({
    this.id,
    required this.userId,
    required this.carId,
    required this.carName,
    required this.carModel,
    required this.carImageUrl,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    this.status = 'pending',
    this.extras,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Factory constructor to create a Booking from Firestore document
  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Booking(
      id: doc.id,
      userId: data['userId'] ?? '',
      carId: data['carId'] ?? '',
      carName: data['carName'] ?? '',
      carModel: data['carModel'] ?? '',
      carImageUrl: data['carImageUrl'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      extras: data['extras'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Factory constructor to create a Booking from JSON
  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      userId: json['userId'] ?? '',
      carId: json['carId'] ?? '',
      carName: json['carName'] ?? '',
      carModel: json['carModel'] ?? '',
      carImageUrl: json['carImageUrl'] ?? '',
      startDate: json['startDate'] is Timestamp
          ? (json['startDate'] as Timestamp).toDate()
          : DateTime.parse(json['startDate'].toString()),
      endDate: json['endDate'] is Timestamp
          ? (json['endDate'] as Timestamp).toDate()
          : DateTime.parse(json['endDate'].toString()),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      extras: json['extras'],
      createdAt: json['createdAt'] != null
          ? json['createdAt'] is Timestamp
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }

  // Convert Booking to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'carId': carId,
      'carName': carName,
      'carModel': carModel,
      'carImageUrl': carImageUrl,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalPrice': totalPrice,
      'status': status,
      'extras': extras,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Convert Booking to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'carId': carId,
      'carName': carName,
      'carModel': carModel,
      'carImageUrl': carImageUrl,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalPrice': totalPrice,
      'status': status,
      'extras': extras,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create a copy of the booking with updated fields
  Booking copyWith({
    String? id,
    String? userId,
    String? carId,
    String? carName,
    String? carModel,
    String? carImageUrl,
    DateTime? startDate,
    DateTime? endDate,
    double? totalPrice,
    String? status,
    Map<String, dynamic>? extras,
    DateTime? createdAt,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      carId: carId ?? this.carId,
      carName: carName ?? this.carName,
      carModel: carModel ?? this.carModel,
      carImageUrl: carImageUrl ?? this.carImageUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      extras: extras ?? this.extras,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

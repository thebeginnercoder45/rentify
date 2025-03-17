import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus { pending, processing, completed, failed, refunded }

enum PaymentMethod { creditCard, debitCard, upi, netBanking }

class PaymentModel {
  final String id;
  final String bookingId;
  final String userId;
  final double amount;
  final PaymentStatus status;
  final PaymentMethod method;
  final String? transactionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentModel({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.amount,
    required this.status,
    required this.method,
    this.transactionId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json, String id) {
    return PaymentModel(
      id: id,
      bookingId: json['bookingId'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      method: PaymentMethod.values.firstWhere(
        (e) => e.toString() == json['method'],
        orElse: () => PaymentMethod.creditCard,
      ),
      transactionId: json['transactionId'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'userId': userId,
      'amount': amount,
      'status': status.toString(),
      'method': method.toString(),
      'transactionId': transactionId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  PaymentModel copyWith({
    String? id,
    String? bookingId,
    String? userId,
    double? amount,
    PaymentStatus? status,
    PaymentMethod? method,
    String? transactionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      method: method ?? this.method,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

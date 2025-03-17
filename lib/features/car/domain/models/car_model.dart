import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'car_model.g.dart';

@JsonSerializable()
class CarModel {
  final String id;
  final String name;
  final String brand;
  final String model;
  final String type;
  final String imageUrl;
  final double pricePerDay;
  final double rating;
  final int totalReviews;
  final List<String> features;
  final bool isAvailable;
  final String ownerId;
  final GeoPoint location;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  CarModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.type,
    required this.imageUrl,
    required this.pricePerDay,
    required this.rating,
    required this.totalReviews,
    required this.features,
    required this.isAvailable,
    required this.ownerId,
    required this.location,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CarModel.fromJson(Map<String, dynamic> json) =>
      _$CarModelFromJson(json);
  Map<String, dynamic> toJson() => _$CarModelToJson(this);
}

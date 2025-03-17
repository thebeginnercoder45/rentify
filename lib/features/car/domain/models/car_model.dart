import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'car_model.g.dart';

class GeoPointConverter
    implements JsonConverter<GeoPoint, Map<String, dynamic>> {
  const GeoPointConverter();

  @override
  GeoPoint fromJson(Map<String, dynamic> json) {
    return GeoPoint(json['latitude'] as double, json['longitude'] as double);
  }

  @override
  Map<String, dynamic> toJson(GeoPoint point) {
    return {'latitude': point.latitude, 'longitude': point.longitude};
  }
}

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

  @GeoPointConverter()
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
    this.isAvailable = true,
    required this.ownerId,
    required this.location,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CarModel.fromJson(Map<String, dynamic> json) =>
      _$CarModelFromJson(json);

  Map<String, dynamic> toJson() => _$CarModelToJson(this);

  CarModel copyWith({
    String? id,
    String? name,
    String? brand,
    String? model,
    String? type,
    String? imageUrl,
    double? pricePerDay,
    double? rating,
    int? totalReviews,
    List<String>? features,
    bool? isAvailable,
    String? ownerId,
    GeoPoint? location,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CarModel(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      features: features ?? this.features,
      isAvailable: isAvailable ?? this.isAvailable,
      ownerId: ownerId ?? this.ownerId,
      location: location ?? this.location,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

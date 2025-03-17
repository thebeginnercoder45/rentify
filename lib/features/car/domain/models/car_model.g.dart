// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'car_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CarModel _$CarModelFromJson(Map<String, dynamic> json) => CarModel(
  id: json['id'] as String,
  name: json['name'] as String,
  brand: json['brand'] as String,
  model: json['model'] as String,
  type: json['type'] as String,
  imageUrl: json['imageUrl'] as String,
  pricePerDay: (json['pricePerDay'] as num).toDouble(),
  rating: (json['rating'] as num).toDouble(),
  totalReviews: (json['totalReviews'] as num).toInt(),
  features:
      (json['features'] as List<dynamic>).map((e) => e as String).toList(),
  isAvailable: json['isAvailable'] as bool,
  ownerId: json['ownerId'] as String,
  location: const GeoPointConverter().fromJson(
    json['location'] as Map<String, dynamic>,
  ),
  description: json['description'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$CarModelToJson(CarModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'brand': instance.brand,
  'model': instance.model,
  'type': instance.type,
  'imageUrl': instance.imageUrl,
  'pricePerDay': instance.pricePerDay,
  'rating': instance.rating,
  'totalReviews': instance.totalReviews,
  'features': instance.features,
  'isAvailable': instance.isAvailable,
  'ownerId': instance.ownerId,
  'location': const GeoPointConverter().toJson(instance.location),
  'description': instance.description,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

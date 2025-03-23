/// Represents a car in the rental application.
import 'package:cloud_firestore/cloud_firestore.dart';

class Car {
  /// Unique identifier for the car
  final String id;

  /// Name of the car
  final String name;

  /// Brand of the car (e.g., Toyota, Honda)
  final String brand;

  /// Model of the car (e.g., Camry, Civic)
  final String model;

  /// Type of fuel used by the car (e.g., Petrol, Diesel)
  final String fuelType;

  /// Mileage of the car in km/L
  final double mileage;

  /// Rental price per day in currency units
  final double pricePerDay;

  /// Rental price per hour in currency units
  final double pricePerHour;

  /// URL to the car's image
  final String? imageUrl;

  /// Description of the car
  final String description;

  /// Features of the car (e.g., AC, Bluetooth, etc.)
  final Map<String, dynamic> features;

  /// Category of the car (e.g., SUV, Sedan, etc.)
  final String category;

  /// Whether the car is available for rent
  final bool isAvailable;

  /// Rating of the car (out of 5)
  final double rating;

  /// Distance from user in km
  final double distance;

  /// Fuel tank capacity in liters
  final double fuelCapacity;

  /// Latitude of the car location
  final double latitude;

  /// Longitude of the car location
  final double longitude;

  /// Creates a new [Car] instance.
  const Car({
    required this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.fuelType,
    required this.mileage,
    required this.pricePerDay,
    required this.pricePerHour,
    this.imageUrl,
    required this.description,
    required this.features,
    required this.category,
    this.isAvailable = true,
    this.rating = 4.5,
    this.distance = 3.2,
    this.fuelCapacity = 45.0,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  /// Creates a [Car] from JSON data.
  /// Use fromFirestore instead for Firestore documents.
  @Deprecated('Use fromFirestore instead for Firestore documents')
  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Car',
      brand: json['brand'] as String? ?? 'Unknown Brand',
      model: json['model'] as String? ?? 'Unknown Model',
      fuelType: json['fuelType'] as String? ?? 'Petrol',
      mileage: _parseDouble(json['mileage']) ?? 0.0,
      pricePerDay: _parseDouble(json['pricePerDay']) ?? 0.0,
      pricePerHour: _parseDouble(json['pricePerHour']) ??
          (_parseDouble(json['pricePerDay']) ?? 0.0) / 24,
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String? ?? 'No description available',
      features:
          json['features'] as Map<String, dynamic>? ?? <String, dynamic>{},
      category: json['category'] as String? ?? 'Sedan',
      isAvailable: json['isAvailable'] as bool? ?? true,
      rating: _parseDouble(json['rating']) ?? 4.5,
      distance: _parseDouble(json['distance']) ?? 3.2,
      fuelCapacity: _parseDouble(json['fuelCapacity']) ?? 45.0,
      latitude: _parseDouble(json['latitude']) ?? 0.0,
      longitude: _parseDouble(json['longitude']) ?? 0.0,
    );
  }

  /// Converts this [Car] to JSON.
  /// Use toFirestore instead for Firestore documents.
  @Deprecated('Use toFirestore instead for Firestore documents')
  Map<String, dynamic> toJson() {
    return toFirestore();
  }

  /// Creates a copy of this [Car] with the specified fields replaced.
  Car copyWith({
    String? id,
    String? name,
    String? brand,
    String? model,
    String? fuelType,
    double? mileage,
    double? pricePerDay,
    double? pricePerHour,
    String? imageUrl,
    String? description,
    Map<String, dynamic>? features,
    String? category,
    bool? isAvailable,
    double? rating,
    double? distance,
    double? fuelCapacity,
    double? latitude,
    double? longitude,
  }) {
    return Car(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      fuelType: fuelType ?? this.fuelType,
      mileage: mileage ?? this.mileage,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      features: features ?? this.features,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      distance: distance ?? this.distance,
      fuelCapacity: fuelCapacity ?? this.fuelCapacity,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Car &&
        other.id == id &&
        other.name == name &&
        other.brand == brand &&
        other.model == model;
  }

  @override
  int get hashCode => Object.hash(id, name, brand, model);

  /// Factory constructor to create a Car from Firestore document
  factory Car.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Calculate price per hour from price per day if needed
    final double pricePerDay = _parseDouble(data['pricePerDay']) ?? 0.0;
    double pricePerHour = _parseDouble(data['pricePerHour']) ?? 0.0;
    if (pricePerHour == 0.0 && pricePerDay > 0) {
      pricePerHour = pricePerDay / 24;
    }

    return Car(
      id: doc.id,
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      model: data['model'] ?? '',
      fuelType: data['fuelType'] ?? 'Petrol',
      mileage: _parseDouble(data['mileage']) ?? 0.0,
      pricePerDay: pricePerDay,
      pricePerHour: pricePerHour,
      imageUrl: data['imageUrl'] as String?,
      description: data['description'] ?? '',
      features: data['features'] is Map
          ? Map<String, dynamic>.from(data['features'] as Map)
          : {},
      category: data['category'] ?? 'Standard',
      isAvailable: data['isAvailable'] ?? true,
      rating: _parseDouble(data['rating']) ?? 4.5,
      distance: _parseDouble(data['distance']) ?? 3.2,
      fuelCapacity: _parseDouble(data['fuelCapacity']) ?? 45.0,
      latitude: _parseDouble(data['latitude']) ?? 0.0,
      longitude: _parseDouble(data['longitude']) ?? 0.0,
    );
  }

  /// Convert Car to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'brand': brand,
      'model': model,
      'fuelType': fuelType,
      'mileage': mileage,
      'pricePerDay': pricePerDay,
      'pricePerHour': pricePerHour,
      'imageUrl': imageUrl,
      'description': description,
      'features': features,
      'category': category,
      'isAvailable': isAvailable,
      'rating': rating,
      'distance': distance,
      'fuelCapacity': fuelCapacity,
      'latitude': latitude,
      'longitude': longitude,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

// Helper to safely parse numeric values from Firestore
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    try {
      return double.parse(value);
    } catch (_) {
      return null;
    }
  }
  return null;
}

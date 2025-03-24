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

  /// Search terms for easier filtering and searching
  final List<String>? searchTerms;

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
    this.searchTerms,
  });

  /// Creates a [Car] from JSON data.
  /// Use fromFirestore instead for Firestore documents.
  @Deprecated('Use fromFirestore instead for Firestore documents')
  factory Car.fromJson(Map<String, dynamic> json) {
    // Get the image URL or set to null
    String? imageUrl = json['imageUrl'] as String?;

    // Ensure imageUrl is properly formatted for assets
    if (imageUrl != null &&
        !imageUrl.startsWith('assets/') &&
        !imageUrl.startsWith('http')) {
      // Check if it's a path that needs 'assets/' prefix
      if (imageUrl.startsWith('cars/')) {
        imageUrl = 'assets/$imageUrl';
      }
    }

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
      imageUrl: imageUrl,
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
    // Use toFirestore instead to ensure consistency
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
    List<String>? searchTerms,
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
      searchTerms: searchTerms ?? this.searchTerms,
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
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Check if the document exists and has data
    if (data.isEmpty) {
      // Return a default car if document doesn't exist or is empty
      return Car(
        id: doc.id,
        name: 'Unknown Car',
        brand: 'Unknown Brand',
        model: 'Unknown Model',
        fuelType: 'Petrol',
        mileage: 0.0,
        pricePerDay: 0.0,
        pricePerHour: 0.0,
        description: 'No description available',
        features: {},
        category: 'Unknown',
      );
    }

    // Get the image URL or set to null
    String? imageUrl = data['imageUrl'] as String?;

    // Ensure imageUrl is properly formatted
    if (imageUrl != null &&
        !imageUrl.startsWith('assets/') &&
        !imageUrl.startsWith('http')) {
      // Check if it's a path that needs 'assets/' prefix
      if (imageUrl.startsWith('cars/')) {
        imageUrl = 'assets/$imageUrl';
      }
    }

    // Calculate price per hour from price per day if needed
    final double pricePerDay = _parseDouble(data['pricePerDay']) ?? 0.0;
    double pricePerHour = _parseDouble(data['pricePerHour']) ?? 0.0;
    if (pricePerHour == 0.0 && pricePerDay > 0) {
      pricePerHour = pricePerDay / 24;
    }

    // Ensure features is properly handled as a Map
    Map<String, dynamic> features = {};
    if (data['features'] is Map) {
      features = Map<String, dynamic>.from(data['features'] as Map);
    }

    // Handle searchTerms as a List
    List<String>? searchTerms;
    if (data['searchTerms'] is List) {
      searchTerms = List<String>.from(
          (data['searchTerms'] as List).map((item) => item.toString()));
    }

    // Create and return the Car object
    return Car(
      id: doc.id,
      name: data['name'] as String? ?? '',
      brand: data['brand'] as String? ?? '',
      model: data['model'] as String? ?? '',
      fuelType: data['fuelType'] as String? ?? 'Petrol',
      mileage: _parseDouble(data['mileage']) ?? 0.0,
      pricePerDay: pricePerDay,
      pricePerHour: pricePerHour,
      imageUrl: imageUrl,
      description: data['description'] as String? ?? '',
      features: features,
      category: data['category'] as String? ?? 'Standard',
      isAvailable: data['isAvailable'] as bool? ?? true,
      rating: _parseDouble(data['rating']) ?? 4.5,
      distance: _parseDouble(data['distance']) ?? 3.2,
      fuelCapacity: _parseDouble(data['fuelCapacity']) ?? 45.0,
      latitude: _parseDouble(data['latitude']) ?? 0.0,
      longitude: _parseDouble(data['longitude']) ?? 0.0,
      searchTerms: searchTerms,
    );
  }

  /// Convert Car to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    // Generate search terms if not provided
    final searchTerms = this.searchTerms ?? _generateSearchTerms();

    // Create normalized map of car data
    final Map<String, dynamic> data = {
      'name': name.trim(),
      'brand': brand.trim(),
      'model': model.trim(),
      'fuelType': fuelType,
      'mileage': mileage,
      'pricePerDay': pricePerDay,
      'pricePerHour': pricePerHour,
      'description': description.trim(),
      'features': features,
      'category': category.trim(),
      'isAvailable': isAvailable,
      'rating': rating,
      'distance': distance,
      'fuelCapacity': fuelCapacity,
      'latitude': latitude,
      'longitude': longitude,
      'searchTerms': searchTerms,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    };

    // Handle imageUrl specially to make sure it's not null in Firestore
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      data['imageUrl'] = imageUrl;

      // For local assets, store a flag to indicate it's an asset path
      if (imageUrl!.startsWith('assets/')) {
        data['isLocalAsset'] = true;
      } else {
        data['isLocalAsset'] = false;
      }
    } else {
      // Default to a standard asset path if no image is provided
      data['imageUrl'] = 'assets/car_image.png';
      data['isLocalAsset'] = true;
    }

    return data;
  }

  // Generate search terms for better Firestore queries
  List<String> _generateSearchTerms() {
    final List<String> terms = [];

    // Add name, brand, model, and category with their lowercase variants
    if (name.isNotEmpty) {
      terms.add(name.toLowerCase());
      // Add individual words from name
      terms.addAll(
          name.toLowerCase().split(' ').where((term) => term.length > 2));
    }

    if (brand.isNotEmpty) {
      terms.add(brand.toLowerCase());
    }

    if (model.isNotEmpty) {
      terms.add(model.toLowerCase());
      // Add individual words from model
      terms.addAll(
          model.toLowerCase().split(' ').where((term) => term.length > 2));
    }

    if (category.isNotEmpty) {
      terms.add(category.toLowerCase());
    }

    // Add fuel type
    terms.add(fuelType.toLowerCase());

    // Price range indicators for searching
    if (pricePerDay < 1000) terms.add('budget');
    if (pricePerDay >= 1000 && pricePerDay < 2500) terms.add('standard');
    if (pricePerDay >= 2500) terms.add('premium');

    // Add feature-related terms
    features.forEach((key, value) {
      if (value == true) {
        terms.add(key.toLowerCase());
      }
    });

    // Remove duplicates and return
    return terms.toSet().toList();
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

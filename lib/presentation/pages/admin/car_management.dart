import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rentapp/data/models/car.dart';
import 'package:rentapp/presentation/bloc/car_bloc.dart';
import 'package:rentapp/presentation/bloc/car_event.dart';
import 'package:rentapp/presentation/bloc/car_state.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class CarManagementScreen extends StatefulWidget {
  const CarManagementScreen({Key? key}) : super(key: key);

  @override
  State<CarManagementScreen> createState() => _CarManagementScreenState();
}

class _CarManagementScreenState extends State<CarManagementScreen> {
  // Theme colors
  static const Color primaryGold = Color(0xFFDAA520);
  static const Color primaryBlack = Color(0xFF121212);
  static const Color accentGold = Color(0xFFF5CE69);
  static const Color lightGold = Color(0xFFF8E8B0);
  static const Color darkGrey = Color(0xFF2D2D2D);
  static const Color mediumGrey = Color(0xFF4D4D4D);

  final _formKey = GlobalKey<FormState>();

  // Car form fields
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _pricePerDayController = TextEditingController();
  final _pricePerHourController = TextEditingController();
  final _mileageController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  String _selectedFuelType = 'Petrol';
  final List<String> _fuelTypes = ['Petrol', 'Diesel', 'Electric', 'Hybrid'];

  // Features checklist
  final Map<String, bool> _features = {
    'Air Conditioning': false,
    'Bluetooth': false,
    'Navigation': false,
    'Leather Seats': false,
    'Sunroof': false,
    'Automatic': false,
    'Backup Camera': false,
  };

  Car? _editingCar;
  File? _imageFile;
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _pricePerDayController.dispose();
    _pricePerHourController.dispose();
    _mileageController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _brandController.clear();
    _modelController.clear();
    _pricePerDayController.clear();
    _pricePerHourController.clear();
    _mileageController.clear();
    _descriptionController.clear();
    _categoryController.clear();
    _selectedFuelType = 'Petrol';

    // Reset features
    for (var key in _features.keys) {
      _features[key] = false;
    }

    _imageFile = null;
    _editingCar = null;
    _isEditMode = false;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    try {
      setState(() {
        _isLoading = true;
      });

      final fileName = 'car_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef =
          FirebaseStorage.instance.ref().child('car_images/$fileName');
      final uploadTask = storageRef.putFile(_imageFile!);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return null;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCar() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Upload image if present
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage();
      }

      // Create a map of features for the car
      final carFeatures = <String, dynamic>{};
      _features.forEach((key, value) {
        carFeatures[key.toLowerCase().replaceAll(' ', '_')] = value;
      });

      // Create car object
      final car = Car(
        id: _isEditMode ? _editingCar!.id : const Uuid().v4(),
        name: _nameController.text,
        brand: _brandController.text,
        model: _modelController.text,
        fuelType: _selectedFuelType,
        mileage: double.parse(_mileageController.text),
        pricePerDay: double.parse(_pricePerDayController.text),
        pricePerHour: _pricePerHourController.text.isNotEmpty
            ? double.parse(_pricePerHourController.text)
            : double.parse(_pricePerDayController.text) / 24,
        imageUrl: imageUrl ?? _editingCar?.imageUrl,
        description: _descriptionController.text,
        features: carFeatures,
        category: _categoryController.text,
        isAvailable: true,
      );

      if (_isEditMode) {
        // Update existing car
        context.read<CarBloc>().add(UpdateCar(car));
      } else {
        // Add new car
        context.read<CarBloc>().add(AddCar(car));
      }

      // Reset form
      _resetForm();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_isEditMode
                ? 'Car updated successfully'
                : 'Car added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving car: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _editCar(Car car) {
    setState(() {
      _isEditMode = true;
      _editingCar = car;

      _nameController.text = car.name;
      _brandController.text = car.brand;
      _modelController.text = car.model;
      _pricePerDayController.text = car.pricePerDay.toString();
      _pricePerHourController.text = car.pricePerHour.toString();
      _mileageController.text = car.mileage.toString();
      _descriptionController.text = car.description;
      _categoryController.text = car.category;
      _selectedFuelType = car.fuelType;

      // Load features
      for (var key in _features.keys) {
        _features[key] =
            car.features[key.toLowerCase().replaceAll(' ', '_')] == true;
      }
    });
  }

  void _deleteCar(Car car) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Car'),
        content: Text('Are you sure you want to delete ${car.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CarBloc>().add(DeleteCar(car.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Car deleted successfully')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Management'),
        backgroundColor: primaryBlack,
        foregroundColor: primaryGold,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<CarBloc>().add(const LoadCars());
            },
            tooltip: 'Refresh Cars',
          ),
        ],
      ),
      body: BlocListener<CarBloc, CarState>(
        listener: (context, state) {
          if (state is CarAdded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Car added successfully')),
            );
            _resetForm();
          } else if (state is CarUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Car updated successfully')),
            );
            _resetForm();
          } else if (state is CarDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Car deleted successfully')),
            );
          } else if (state is CarsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Car Inventory',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<CarBloc, CarState>(
                    builder: (context, state) {
                      if (state is CarsLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is CarsLoaded) {
                        final cars = state.cars;
                        if (cars.isEmpty) {
                          return const Center(
                            child: Text(
                              'No cars found. Add your first car!',
                              style: TextStyle(fontSize: 16),
                            ),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cars.length,
                          itemBuilder: (context, index) {
                            final car = cars[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: ListTile(
                                leading: car.imageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(
                                          car.imageUrl!,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.directions_car,
                                                  size: 40),
                                        ),
                                      )
                                    : const Icon(Icons.directions_car,
                                        size: 40),
                                title: Text(
                                  '${car.brand} ${car.name}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${car.category} - ₹${car.pricePerDay}/day',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _editCar(car),
                                      color: Colors.blue,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _deleteCar(car),
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      } else if (state is CarsError) {
                        return Center(
                          child: Text(
                            'Error: ${state.message}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }
                      return const Center(
                        child: Text('Loading cars...'),
                      );
                    },
                  ),
                  const Divider(height: 40),
                  const Text(
                    'Add New Car',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCarForm(),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _resetForm,
        backgroundColor: primaryGold,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCarForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image upload section
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 200,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: _imageFile != null
                    ? Image.file(
                        _imageFile!,
                        fit: BoxFit.cover,
                      )
                    : _editingCar?.imageUrl != null
                        ? Image.network(
                            _editingCar!.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.add_photo_alternate,
                              size: 50,
                              color: Colors.grey,
                            ),
                          )
                        : const Icon(
                            Icons.add_photo_alternate,
                            size: 50,
                            color: Colors.grey,
                          ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Select Image'),
              style: TextButton.styleFrom(foregroundColor: primaryGold),
            ),
          ),
          const SizedBox(height: 16),

          // Basic details
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Car Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter car name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _brandController,
                  decoration: const InputDecoration(
                    labelText: 'Brand',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter brand';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _modelController,
                  decoration: const InputDecoration(
                    labelText: 'Model',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter model';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    hintText: 'SUV, Sedan, Luxury, etc.',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter category';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFuelType,
                  decoration: const InputDecoration(
                    labelText: 'Fuel Type',
                    border: OutlineInputBorder(),
                  ),
                  items: _fuelTypes.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedFuelType = newValue!;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pricing and specs
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _pricePerDayController,
                  decoration: const InputDecoration(
                    labelText: 'Price Per Day (₹)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter price per day';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _pricePerHourController,
                  decoration: const InputDecoration(
                    labelText: 'Price Per Hour (₹)',
                    border: OutlineInputBorder(),
                    hintText: 'Optional',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _mileageController,
            decoration: const InputDecoration(
              labelText: 'Mileage (km/L)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter mileage';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter description';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Features
          const Text(
            'Features',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 0,
            children: _features.keys.map((feature) {
              return CheckboxListTile(
                title: Text(feature),
                value: _features[feature],
                onChanged: (bool? value) {
                  setState(() {
                    _features[feature] = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveCar,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGold,
                foregroundColor: Colors.white,
              ),
              child: Text(_isEditMode ? 'Update Car' : 'Add Car'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

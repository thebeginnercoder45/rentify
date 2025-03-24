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
import 'dart:async'; // Add this import for TimeoutException
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    _checkStorageConnection();
  }

  // Add a method to check storage connection
  Future<void> _checkStorageConnection() async {
    try {
      // Check Firebase Storage connection
      final storageInstance = FirebaseStorage.instance;
      print("DEBUG: Storage bucket: ${storageInstance.bucket}");

      // Create a test reference - directly at root level
      final testRef = storageInstance.ref().child('test.txt');
      print("DEBUG: Test reference path: ${testRef.fullPath}");

      // Try to upload a small test file to verify permissions
      try {
        // Create a simple text file
        final bytes = Uint8List.fromList([0]);
        await testRef.putData(bytes);
        print("DEBUG: Test upload successful, reference exists");

        // Clean up the test file
        await testRef.delete().catchError((e) {
          // Ignore delete errors
          print("DEBUG: Error cleaning up test file: $e");
        });
      } catch (uploadError) {
        print("DEBUG: Storage upload test failed: $uploadError");

        if (uploadError.toString().contains('storage/unauthorized')) {
          print("DEBUG: Unauthorized. Check Firebase Storage rules");

          // Show warning to user about storage permissions
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Firebase Storage permission denied. Please check your Firebase Storage rules.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 10),
            ),
          );
        }
      }
    } catch (e) {
      print("DEBUG: Storage connection check failed: $e");
    }
  }

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
    try {
      // Check authentication first
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to upload images'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        print("DEBUG: Image selected: ${pickedFile.path}");

        // Show preview
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Image selected successfully. Click Add Car to upload.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("DEBUG: Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) {
      debugPrint("DEBUG: No image file to upload");
      return null;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0;
    });

    try {
      debugPrint("DEBUG: Starting image upload");

      // Check authentication
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create a storage reference from our app
      final storageRef = FirebaseStorage.instance.ref();

      // Create a unique filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filename = 'car_images/car_${user.uid}_$timestamp.jpg';

      debugPrint("DEBUG: Will upload to: $filename");

      // Create reference for this specific file
      final ref = storageRef.child(filename);

      // Compress image before upload
      final File compressedFile = await _compressImage(_imageFile!);
      final Uint8List fileBytes = await compressedFile.readAsBytes();

      debugPrint("DEBUG: Original size: ${await _imageFile!.length()} bytes");
      debugPrint("DEBUG: Compressed size: ${fileBytes.length} bytes");

      // Create metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': user.uid,
          'timestamp': timestamp,
        },
      );

      // Upload file
      final uploadTask = ref.putData(fileBytes, metadata);

      // Track upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        setState(() {
          _uploadProgress = progress;
        });
        debugPrint(
            "DEBUG: Upload progress: ${(progress * 100).toStringAsFixed(1)}%");
      });

      // Wait for upload to complete
      final snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        // Get download URL
        final downloadUrl = await ref.getDownloadURL();
        debugPrint("DEBUG: Upload successful! Download URL: $downloadUrl");
        return downloadUrl;
      } else {
        throw Exception('Upload failed: ${snapshot.state}');
      }
    } catch (e) {
      debugPrint("DEBUG: Error uploading image: $e");
      String errorMessage = 'Failed to upload image';

      if (e.toString().contains('storage/unauthorized')) {
        errorMessage = 'Permission denied. Please check if you are signed in.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      return null;
    } finally {
      setState(() {
        _isLoading = false;
        _uploadProgress = 0;
      });
    }
  }

  // Helper method to compress images before upload
  Future<File> _compressImage(File file) async {
    try {
      // Get file path and name components
      final dir = path.dirname(file.path);
      final fileName = path.basenameWithoutExtension(file.path);
      final ext = path.extension(file.path);
      final targetPath = path.join(dir, '${fileName}_compressed$ext');

      // Use image package to resize/compress
      final img.Image? image = img.decodeImage(await file.readAsBytes());
      if (image == null) return file;

      // Resize if too large (keeping aspect ratio)
      img.Image resized = image;
      if (image.width > 1200 || image.height > 1200) {
        resized = img.copyResize(
          image,
          width: image.width > image.height ? 1200 : null,
          height: image.height >= image.width ? 1200 : null,
        );
      }

      // Encode with reduced quality
      final compressedData = img.encodeJpg(resized, quality: 80);

      // Save to new file
      final compressedFile = File(targetPath);
      await compressedFile.writeAsBytes(compressedData);

      return compressedFile;
    } catch (e) {
      debugPrint("Error compressing image: $e");
      // Return original file if compression fails
      return file;
    }
  }

  Future<void> _saveCar() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isLoading = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Processing your request...'),
          duration: Duration(seconds: 30),
        ),
      );

      print("DEBUG: Car form validated, starting save process");

      // Upload image if present
      String? imageUrl;
      if (_imageFile != null) {
        print("DEBUG: Uploading image file: ${_imageFile!.path}");
        imageUrl = await _uploadImage();
        print("DEBUG: Image upload result: $imageUrl");
      } else if (_editingCar != null && _editingCar!.imageUrl != null) {
        // Keep existing image URL if editing car and no new image selected
        imageUrl = _editingCar!.imageUrl;
        print("DEBUG: Using existing image URL: $imageUrl");
      } else {
        // Use default image if no image provided
        imageUrl = 'assets/car_image.png';
        print("DEBUG: Using default asset image: $imageUrl");
      }

      // Create a map of features for the car
      final carFeatures = <String, dynamic>{};
      _features.forEach((key, value) {
        if (value) {
          carFeatures[key.toLowerCase().replaceAll(' ', '_')] = value;
        }
      });

      print("DEBUG: Features processed: $carFeatures");

      // Parse numeric values from text fields
      final double pricePerDay =
          double.tryParse(_pricePerDayController.text) ?? 0.0;
      final double pricePerHour =
          double.tryParse(_pricePerHourController.text) ?? 0.0;
      final double mileage = double.tryParse(_mileageController.text) ?? 0.0;

      // Create the car object
      final car = Car(
        id: _editingCar?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        category: _categoryController.text.trim(),
        fuelType: _selectedFuelType,
        mileage: mileage,
        pricePerDay: pricePerDay,
        pricePerHour: pricePerHour,
        description: _descriptionController.text.trim(),
        features: carFeatures,
        imageUrl: imageUrl,
      );

      print("DEBUG: Car object created: ${car.toJson()}");

      // Save car to Firestore using the CarBloc
      if (_isEditMode) {
        context.read<CarBloc>().add(UpdateCar(car));
        print("DEBUG: Update car event dispatched");
      } else {
        context.read<CarBloc>().add(AddCar(car));
        print("DEBUG: Add car event dispatched");
      }

      // Hide the current snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Car updated successfully!'
                : 'Car added successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Reset the form after successful save
      _resetForm();

      // Refresh car list
      context.read<CarBloc>().add(const LoadCars());
    } catch (e) {
      print("DEBUG: Error saving car: $e");

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving car: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
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
              print("DEBUG: Manually refreshing car list");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing car list...')),
              );
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
            // Reset form after successful addition
            _resetForm();
            setState(() {
              _isLoading = false;
            });
          } else if (state is CarUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Car updated successfully')),
            );
            // Reset form after successful update
            _resetForm();
            setState(() {
              _isLoading = false;
            });
          } else if (state is CarDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Car deleted successfully')),
            );
          } else if (state is CarsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
            setState(() {
              _isLoading = false;
            });
          }
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Car Inventory',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      BlocBuilder<CarBloc, CarState>(
                        builder: (context, state) {
                          if (state is CarsLoaded) {
                            final cars = state.cars;
                            if (cars.isEmpty) {
                              return const Text(
                                'No cars available',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              );
                            }
                            return Text(
                              '${cars.length} cars',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
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
                        return _buildCarList(cars);
                      } else if (state is CarsError) {
                        return Center(
                          child: Text(
                            'Error: ${state.message}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }
                      return const Center(child: Text('Loading cars...'));
                    },
                  ),
                  const Divider(height: 40),
                  const Text(
                    'Add New Car',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildCarForm(),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("DEBUG: FAB pressed - reset form");
          _resetForm();
        },
        backgroundColor: primaryGold,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCarList(List<Car> cars) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: cars.length,
      itemBuilder: (context, index) {
        final car = cars[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12.0),
            leading: SizedBox(
              width: 80,
              height: 80,
              child: car.imageUrl != null && car.imageUrl!.isNotEmpty
                  ? Image.network(
                      car.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print("Error loading image: $error");
                        return const Icon(
                          Icons.directions_car,
                          size: 40.0,
                          color: Colors.grey,
                        );
                      },
                    )
                  : const Icon(
                      Icons.directions_car,
                      size: 40.0,
                      color: Colors.grey,
                    ),
            ),
            title: Text(
              '${car.brand} ${car.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Model: ${car.model}'),
                Text(
                  'Price: ₹${car.pricePerDay.toStringAsFixed(0)}/day',
                ),
                Text(
                  'Available: ${car.isAvailable ? 'Yes' : 'No'}',
                  style: TextStyle(
                    color: car.isAvailable ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editCar(car),
                  color: primaryGold,
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
  }

  Widget _buildCarForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageInputField(),
          const SizedBox(height: 16),
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
          const Text(
            'Features',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGold,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(_isEditMode ? 'Update Car' : 'Add Car'),
              onPressed: _isLoading
                  ? null
                  : () async {
                      print("DEBUG: Save button pressed");
                      if (!_formKey.currentState!.validate()) {
                        print("DEBUG: Form validation failed");
                        return;
                      }

                      // First check storage connection if uploading image
                      if (_imageFile != null) {
                        try {
                          // Quick check if Firebase Storage is accessible
                          final storageInstance = FirebaseStorage.instance;
                          print(
                              "DEBUG: Pre-save storage check: ${storageInstance.bucket}");

                          // Try to access the cars directory
                          try {
                            await storageInstance.ref().child('cars').listAll();
                            print(
                                "DEBUG: Cars directory exists and is accessible");
                          } catch (listError) {
                            print(
                                "DEBUG: Cars directory access error: $listError");
                            // Instead of trying to create a directory, just warn the user but continue
                            // Firebase Storage doesn't really have directories, just paths
                            print(
                                "DEBUG: Will use root-level paths instead of cars/ directory");

                            // Don't show warning as we'll just use root path
                            // Continue with save using root-level paths
                          }
                        } catch (storageError) {
                          print(
                              "DEBUG: Storage access error before save: $storageError");

                          // Show error message with troubleshooting options
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Storage Access Error'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Unable to access Firebase Storage: $storageError'),
                                  const SizedBox(height: 16),
                                  const Text('Troubleshooting steps:'),
                                  const SizedBox(height: 8),
                                  const Text(
                                      '• Check your internet connection'),
                                  const Text(
                                      '• Verify Firebase project settings'),
                                  const Text(
                                      '• Ensure Storage permissions are set correctly'),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    // Try save without image if user wants to continue
                                    _imageFile = null;
                                    _saveCar();
                                  },
                                  child: const Text('Continue Without Image'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    // Retry storage connection check
                                    _checkStorageConnection()
                                        .then((_) => _saveCar());
                                  },
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          );
                          return; // Exit early
                        }
                      }

                      setState(() {
                        _isLoading = true;
                      });

                      try {
                        // Show loading indicator
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Processing your request...'),
                            duration: Duration(seconds: 30),
                          ),
                        );

                        // Upload image if present
                        String? imageUrl;
                        if (_imageFile != null) {
                          print(
                            "DEBUG: Uploading image: ${_imageFile!.path}",
                          );

                          // Upload image and get URL
                          imageUrl = await _uploadImage();

                          if (imageUrl == null) {
                            setState(() {
                              _isLoading = false;
                            });
                            ScaffoldMessenger.of(
                              context,
                            ).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Image upload failed. Please try again.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          print("DEBUG: Image URL: $imageUrl");
                        } else if (_editingCar != null &&
                            _editingCar!.imageUrl != null) {
                          // Keep existing image URL if editing
                          imageUrl = _editingCar!.imageUrl;
                          print("DEBUG: Using existing image URL: $imageUrl");
                        }

                        // Create a map of features
                        final carFeatures = <String, dynamic>{};
                        _features.forEach((key, value) {
                          carFeatures[key.toLowerCase().replaceAll(
                                ' ',
                                '_',
                              )] = value;
                        });

                        // Create search terms for better searching
                        final List<String> searchTerms = [
                          _nameController.text.toLowerCase(),
                          _brandController.text.toLowerCase(),
                          _modelController.text.toLowerCase(),
                          _categoryController.text.toLowerCase(),
                          _selectedFuelType.toLowerCase(),
                        ];

                        // Add feature terms
                        _features.forEach((key, value) {
                          if (value) {
                            searchTerms.add(
                              key.toLowerCase().replaceAll(' ', '_'),
                            );
                          }
                        });

                        // Add premium tag for luxury cars
                        if (_categoryController.text.toLowerCase() ==
                            'luxury') {
                          searchTerms.add('premium');
                        }

                        // Create car object with all required fields
                        final car = Car(
                          id: _isEditMode ? _editingCar!.id : const Uuid().v4(),
                          name: _nameController.text.trim(),
                          brand: _brandController.text.trim(),
                          model: _modelController.text.trim(),
                          fuelType: _selectedFuelType,
                          mileage: double.parse(_mileageController.text),
                          pricePerDay: double.parse(
                            _pricePerDayController.text,
                          ),
                          pricePerHour: _pricePerHourController.text.isNotEmpty
                              ? double.parse(_pricePerHourController.text)
                              : double.parse(
                                    _pricePerDayController.text,
                                  ) /
                                  24,
                          imageUrl: imageUrl,
                          description: _descriptionController.text.trim(),
                          features: carFeatures,
                          category: _categoryController.text.trim(),
                          isAvailable: true,
                          searchTerms: searchTerms,
                        );

                        print("DEBUG: Car object created: ${car.id}");
                        print(
                          "DEBUG: Image URL in car object: ${car.imageUrl}",
                        );

                        // Dispatch appropriate event based on mode
                        if (_isEditMode) {
                          context.read<CarBloc>().add(UpdateCar(car));
                        } else {
                          context.read<CarBloc>().add(AddCar(car));
                        }

                        // Form will be reset in the BlocListener callback
                        // Loading state will be updated there as well
                      } catch (e) {
                        print("DEBUG: Error in save button handler: $e");
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    },
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildImageInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Car Image',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: _imageFile != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _imageFile!,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (_isLoading)
                      Container(
                        color: Colors.black.withOpacity(0.5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              value:
                                  _uploadProgress > 0 ? _uploadProgress : null,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _uploadProgress > 0
                                  ? 'Uploading: ${(_uploadProgress * 100).toStringAsFixed(0)}%'
                                  : 'Uploading...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                )
              : _editingCar != null &&
                      _editingCar!.imageUrl != null &&
                      _editingCar!.imageUrl!.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: _editingCar!.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error,
                                  color: Colors.red[300],
                                  size: 48,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Failed to load image',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to add an image',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickImage,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Select Image'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
              ),
            ),
            if (_imageFile != null ||
                (_editingCar != null &&
                    _editingCar!.imageUrl != null &&
                    _editingCar!.imageUrl!.isNotEmpty))
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _resetForm,
                icon: const Icon(Icons.delete),
                label: const Text('Remove'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/car_bloc.dart';
import '../widgets/car_card.dart';

class CarListingScreen extends StatefulWidget {
  const CarListingScreen({super.key});

  @override
  State<CarListingScreen> createState() => _CarListingScreenState();
}

class _CarListingScreenState extends State<CarListingScreen> {
  final _searchController = TextEditingController();
  String? _selectedBrand;
  String? _selectedType;
  double? _maxPrice;
  bool _showOnlyAvailable = false;

  @override
  void initState() {
    super.initState();
    context.read<CarBloc>().add(LoadCars());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    context.read<CarBloc>().add(
      SearchCars(
        query: _searchController.text,
        brand: _selectedBrand,
        type: _selectedType,
        maxPrice: _maxPrice,
        isAvailable: _showOnlyAvailable ? true : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search cars...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) => _onSearch(),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Available Only'),
                        selected: _showOnlyAvailable,
                        onSelected: (selected) {
                          setState(() {
                            _showOnlyAvailable = selected;
                          });
                          _onSearch();
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('All Brands'),
                        selected: _selectedBrand == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedBrand = selected ? null : _selectedBrand;
                          });
                          _onSearch();
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('All Types'),
                        selected: _selectedType == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = selected ? null : _selectedType;
                          });
                          _onSearch();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<CarBloc, CarState>(
              builder: (context, state) {
                if (state is CarLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is CarError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (state is CarsLoaded) {
                  if (state.cars.isEmpty) {
                    return const Center(child: Text('No cars found'));
                  }

                  return ListView.builder(
                    itemCount: state.cars.length,
                    itemBuilder: (context, index) {
                      final car = state.cars[index];
                      return CarCard(
                        car: car,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/car-details',
                            arguments: car.id,
                          );
                        },
                      );
                    },
                  );
                }

                return const SizedBox();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/car-management');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

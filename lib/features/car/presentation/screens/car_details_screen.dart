import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/models/car_model.dart';
import '../bloc/car_bloc.dart';

class CarDetailsScreen extends StatelessWidget {
  final String carId;

  const CarDetailsScreen({super.key, required this.carId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) =>
              CarBloc(carRepository: context.read())
                ..add(LoadCarDetails(carId)),
      child: Scaffold(
        appBar: AppBar(title: const Text('Car Details')),
        body: BlocBuilder<CarBloc, CarState>(
          builder: (context, state) {
            if (state is CarLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CarError) {
              return Center(child: Text(state.message));
            }
            if (state is CarDetailsLoaded) {
              return _buildCarDetails(context, state.car);
            }
            return const Center(child: Text('No car details available'));
          },
        ),
      ),
    );
  }

  Widget _buildCarDetails(BuildContext context, CarModel car) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(car.imageUrl, fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),
          Text(car.name, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '${car.brand} ${car.model}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber[700]),
              const SizedBox(width: 4),
              Text(
                car.rating.toString(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 8),
              Text(
                '(${car.totalReviews} reviews)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '\$${car.pricePerDay.toStringAsFixed(2)}/day',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text('Features', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                car.features.map((feature) {
                  return Chip(label: Text(feature));
                }).toList(),
          ),
          const SizedBox(height: 24),
          Text('Description', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(car.description, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/booking', arguments: car.id);
              },
              child: const Text('Book Now'),
            ),
          ),
        ],
      ),
    );
  }
}

# CLI Tools for Data Management

This document explains how to use the CLI tools to manage car data in the RentApp Firestore database.

## Prerequisites

1. Make sure Firebase is properly configured for your app
2. Ensure you have the required dependencies installed:
   ```
   flutter pub get
   ```

## Available CLI Tools

### 1. Add Sample Cars (Non-Interactive Batch Mode)

This tool automatically adds the sample cars to your Firestore database without requiring user input.

```bash
dart run lib/cli/add_cars_batch.dart
```

### 2. Car Manager CLI (Interactive Mode)

This tool provides a full interactive CRUD interface to:
- List all cars in the database
- Add new cars
- Update existing cars
- Delete cars

```bash
dart run lib/cli/car_manager_cli.dart
```

#### Commands in Interactive Mode

Once the CLI is running, you'll see a menu with the following options:

1. **List all cars** - Shows all cars in the database with their details
2. **Add a new car** - Prompts you to enter the details for a new car
3. **Update a car** - Shows all cars, then lets you select one to update
4. **Delete a car** - Shows all cars, then lets you select one to delete
5. **Exit** - Exits the CLI

## Common Issues

### Firebase Access Error

If you see errors related to Firebase access:
1. Make sure you've initialized Firebase correctly
2. Check that your emulator is running (if using one)
3. Verify your internet connection

### Data Not Showing in App

If the app shows a white screen after the onboarding page:
1. First check if data is available using the CLI tool to list cars
2. If no data exists, run the add_cars_batch.dart script
3. Restart the app and the cars should be visible

## Custom Data Import

If you want to import data from a custom source (like CSV):

1. Create a new Dart file in the `lib/cli` directory
2. Use the `FirebaseCarDataSource` class for database operations
3. Implement your import logic to convert and save data

Example of custom import (conceptual):

```dart
import 'package:rentapp/data/datasources/firebase_car_data_source.dart';
import 'package:rentapp/data/models/car.dart';

Future<void> importFromCsv(String filePath, FirebaseCarDataSource dataSource) async {
  // 1. Read the CSV file
  // 2. Parse each line into a Car object
  // 3. Use dataSource.addCar() to save to Firestore
}
``` 
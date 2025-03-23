# Setting Up Firebase and Firestore for RentApp

This guide will help you set up Firebase and Firestore for your RentApp project.

## Step 1: Configure Firebase with FlutterFire CLI

1. Make sure you have the Firebase CLI and FlutterFire CLI installed:
   ```
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   ```

2. Log in to Firebase:
   ```
   firebase login
   ```

3. Run the FlutterFire configure command:
   ```
   flutterfire configure
   ```
   - Select your Firebase project from the list or create a new one
   - Choose which platforms you want to support (Android, iOS, etc.)
   - The CLI will automatically update your firebase_options.dart file

## Step 2: Set Up Firestore Database

After your app is connected to Firebase:

1. Go to the Firebase Console and select your project
2. In the left sidebar, click on "Firestore Database"
3. Click "Create database"
4. Choose "Start in test mode" for development (you can change this later)
5. Select a location close to your users
6. Click "Enable"

## Step 3: Create a Collection and Sample Documents

### Create the "cars" Collection:

1. Once Firestore is set up, click "Start collection"
2. Enter "cars" as the Collection ID
3. Click "Next"

### Add Sample Car Documents:

Add the following car documents to the "cars" collection:

#### Car 1:
- Field: "model", Type: string, Value: "Tesla Model 3"
- Field: "distance", Type: number, Value: 15.5
- Field: "fuelCapacity", Type: number, Value: 100.0
- Field: "pricePerHour", Type: number, Value: 25.0

#### Car 2:
- Field: "model", Type: string, Value: "Toyota Camry"
- Field: "distance", Type: number, Value: 20.0
- Field: "fuelCapacity", Type: number, Value: 60.0
- Field: "pricePerHour", Type: number, Value: 15.0

#### Car 3:
- Field: "model", Type: string, Value: "Honda Civic"
- Field: "distance", Type: number, Value: 18.0
- Field: "fuelCapacity", Type: number, Value: 50.0
- Field: "pricePerHour", Type: number, Value: 12.0

#### Car 4:
- Field: "model", Type: string, Value: "BMW X5"
- Field: "distance", Type: number, Value: 25.0
- Field: "fuelCapacity", Type: number, Value: 80.0
- Field: "pricePerHour", Type: number, Value: 30.0

#### Car 5:
- Field: "model", Type: string, Value: "Mercedes-Benz E-Class"
- Field: "distance", Type: number, Value: 22.0
- Field: "fuelCapacity", Type: number, Value: 70.0
- Field: "pricePerHour", Type: number, Value: 35.0

## Step 4: Run Your App

After completing these steps, run your app with:

```
flutter run
```

The app should now connect to Firebase and retrieve the car data from Firestore. 
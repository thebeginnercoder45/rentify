# Firebase Setup Guide for RentApp

This guide will help you set up Firebase for this rent app project, specifically configuring Firestore for storing car data.

## Step 1: Create a Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click on "Add project"
3. Enter "RentApp" or your preferred name for the project
4. Follow the setup wizard (enable or disable Google Analytics as per your preference)
5. Click "Create Project"

## Step 2: Register Your App with Firebase

### For Android:

1. In the Firebase console, click on the Android icon to add an Android app to your Firebase project
2. Enter the package name: `com.example.rentapp` (or the actual package name if you've changed it)
3. Enter a nickname for your app (optional)
4. Add the SHA-1 certificate fingerprint (optional for basic setup, required for Google Sign-In)
5. Click "Register app"
6. Download the `google-services.json` file
7. Place the file in the `android/app` directory of your Flutter project

### For iOS (if needed):

1. In the Firebase console, click on the iOS icon to add an iOS app
2. Enter the iOS bundle ID from the Runner.xcodeproj/project.pbxproj file (usually `com.example.rentapp`)
3. Enter a nickname for your app (optional)
4. Click "Register app"
5. Download the `GoogleService-Info.plist` file
6. Move the file into the iOS app's Runner directory using Xcode

## Step 3: Configure FlutterFire

1. Install the FlutterFire CLI (if not already installed):
   ```
   dart pub global activate flutterfire_cli
   ```

2. Configure your apps using FlutterFire:
   ```
   flutterfire configure --project=YOUR_PROJECT_ID
   ```
   * Select all platforms you want to support (Android, iOS, web, etc.)
   * This will update your `firebase_options.dart` file

## Step 4: Set Up Firestore Database

1. In the Firebase console, go to Firestore Database
2. Click "Create Database"
3. Choose start mode (test mode or production mode)
   * For initial development, you can choose "Start in test mode" 
   * This will allow read/write access to your database for 30 days
4. Choose a location for your Firestore database
5. Click "Enable"

## Step 5: Import Sample Data to Firestore

Create a collection called `cars` with documents that have the following structure:

```json
{
  "model": "Car Model Name",
  "distance": 20.0,
  "fuelCapacity": 60.0,
  "pricePerHour": 15.0
}
```

You can manually add these documents or use the Firebase Admin SDK to import from the provided `firestore_sample_data.json` file.

## Step 6: Update Your Firebase Options

After running `flutterfire configure`, your `firebase_options.dart` file should be updated with the correct configuration. If not, replace the placeholder values in the file manually with the values from your Firebase project.

## Step 7: Run Your App

After completing these steps, run your app with:

```
flutter run
```

The app should now connect to Firebase and retrieve the car data from Firestore.

## Troubleshooting

If you encounter any issues:

1. Ensure all Firebase dependencies are properly added to your `pubspec.yaml`
2. Make sure the `google-services.json` file is in the correct location
3. Verify your Firestore collection is named `cars` and has documents with the required fields
4. Check the console for any Firebase-related errors 
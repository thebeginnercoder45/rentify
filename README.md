# RentApp - Car Rental Application

## Features

### User Features
- Browse available cars
- View car details with photos and specifications
- Book cars for a specific date range
- View booking history
- User profile management

### Admin Features
- Dashboard with real-time analytics
- Recent activity tracking
- Car management (add, edit, delete)
- Booking management (view, approve, reject)
- User management (view, edit roles)

## Analytics & Activity Tracking

The application now includes comprehensive analytics and activity tracking:

### Admin Analytics
- Total Cars: Shows the total number of cars in the fleet
- Active Bookings: Displays currently active bookings
- Total Users: Shows the total number of registered users
- Revenue: Calculates the total revenue from confirmed bookings

### Activity Logging
The system automatically logs important activities:
- New car additions
- Booking confirmations
- User registrations

Each activity log contains:
- Activity type
- Title and description
- Timestamp
- Associated user ID
- Related entity ID (car, booking, etc.)
- Additional metadata

## Implementation Details

### Models
- `ActivityLog`: Model for storing and retrieving activity logs
- `AdminAnalytics`: Model for storing dashboard analytics data

### Services
- `AnalyticsService`: Service for fetching and calculating analytics data
- `ActivityLogger`: Helper class for logging system activities

### Testing
For debugging purposes, sample activity logs are automatically seeded when running in debug mode if no logs exist in the database.

## Getting Started

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Connect to Firebase (ensure Firestore is set up)
4. Run the app with `flutter run`

## Screenshots
(Add screenshots of the admin dashboard here)
A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
#   r e n t i f y 
 
 
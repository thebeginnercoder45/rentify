import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rentapp/firebase_options.dart';
import 'package:rentapp/injection_container.dart' as di;
import 'package:rentapp/presentation/bloc/car_bloc.dart';
import 'package:rentapp/presentation/bloc/booking_bloc.dart';
import 'package:rentapp/presentation/pages/splash_screen.dart';
import 'package:rentapp/presentation/bloc/search_bloc.dart';
import 'package:rentapp/presentation/bloc/auth_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:rentapp/utils/notification_service.dart';
import 'package:rentapp/utils/download_test_images.dart';
import 'package:flutter/foundation.dart';
import 'package:rentapp/data/models/activity_log.dart';

Future<bool> _initializeFirebase() async {
  try {
    debugPrint("Initializing Firebase...");

    // Check if Firebase is already initialized
    if (Firebase.apps.isNotEmpty) {
      debugPrint("Firebase already initialized");
      return true;
    }

    // Initialize with a longer timeout for slow connections
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 15), onTimeout: () {
      throw TimeoutException(
          'Firebase initialization timed out after 15 seconds');
    });

    // Configure Firestore for better offline support
    await FirebaseFirestore.instance
        .enablePersistence(const PersistenceSettings(
      synchronizeTabs: true,
    ));

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Configure Firebase Storage settings for better upload reliability
    try {
      FirebaseStorage.instance
          .setMaxUploadRetryTime(const Duration(seconds: 30));
      FirebaseStorage.instance
          .setMaxDownloadRetryTime(const Duration(seconds: 30));
      FirebaseStorage.instance
          .setMaxOperationRetryTime(const Duration(seconds: 15));

      // Verify storage access with a test upload
      debugPrint("Verifying Firebase Storage access...");
      final testRef =
          FirebaseStorage.instance.ref().child('test/connection_test.txt');
      await testRef
          .putString('Test connection ${DateTime.now().toIso8601String()}')
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Firebase Storage test upload timed out');
      });
      debugPrint("Firebase Storage test successful");
    } catch (storageError) {
      debugPrint("Firebase Storage configuration error: $storageError");

      // Continue even if storage test fails - don't block app startup
      if (storageError.toString().contains('storage/unauthorized') ||
          storageError.toString().contains('permission-denied')) {
        debugPrint("""
Firebase Storage permission error detected. 
Please check your Firebase Storage rules in the Firebase Console.
Example rules that allow authenticated users to upload:

rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read;
      allow write: if request.auth != null;
    }
  }
}
""");
      }
    }

    debugPrint("Firebase initialized successfully");
    return true;
  } catch (e) {
    debugPrint("Firebase initialization error: $e");

    // For default app already exists error, return true as Firebase is working
    if (e.toString().contains('already exists')) {
      return true;
    }

    return false;
  }
}

Future<void> main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  try {
    await NotificationService.instance.init();
    debugPrint("Notification service initialized successfully");
  } catch (e) {
    debugPrint("Error initializing notification service: $e");
  }

  // Download test images in debug mode
  if (kDebugMode) {
    try {
      await ImageDownloader.downloadTestImages();
    } catch (e) {
      debugPrint("Error downloading test images: $e");
    }
  }

  // Initialize Firebase with improved error handling
  final bool firebaseInitialized = await _initializeFirebase();
  String? errorMessage;

  if (firebaseInitialized) {
    // Initialize dependency injection
    try {
      di.initInjection();

      // Seed activity logs if in debug mode
      if (kDebugMode) {
        try {
          await _seedActivityLogsIfNeeded();
        } catch (e) {
          debugPrint("Error seeding activity logs: $e");
        }
      }
    } catch (e) {
      debugPrint("Error in setup: $e");
      errorMessage = e.toString();
    }
  } else {
    errorMessage =
        "Could not connect to Firebase. Check your internet connection and try again.";
  }

  runApp(MyApp(
    firebaseInitialized: firebaseInitialized,
    errorMessage: errorMessage,
  ));
}

// Function to ensure required car data exists in Firestore
// This function is no longer needed because we have local sample cars in CarBloc
// Adding a comment to clarify why this was removed

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}

class MyApp extends StatelessWidget {
  final bool firebaseInitialized;
  final String? errorMessage;

  const MyApp({
    Key? key,
    this.firebaseInitialized = false,
    this.errorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CarBloc>(create: (context) => di.getIt<CarBloc>()),
        BlocProvider<BookingBloc>(create: (context) => di.getIt<BookingBloc>()),
        BlocProvider<SearchBloc>(create: (context) => di.getIt<SearchBloc>()),
        BlocProvider<AuthBloc>(
          create: (context) => di.getIt<AuthBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'Rent App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3A3A3A),
            primary: const Color(0xFF3A3A3A),
            secondary: const Color(0xFFF7F7F7),
            tertiary: const Color(0xFF9E9E9E),
            onPrimary: Colors.white,
            onSecondary: const Color(0xFF3A3A3A),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: Color(0xFF3A3A3A),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            iconTheme: IconThemeData(color: Color(0xFF3A3A3A)),
          ),
          cardTheme: CardTheme(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3A3A3A),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF3A3A3A),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF9E9E9E)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF9E9E9E), width: 2),
            ),
            fillColor: Colors.white,
            filled: true,
          ),
        ),
        // Start with the splash screen or error screen
        home: !firebaseInitialized
            ? _FirebaseErrorScreen(errorMessage: errorMessage)
            : const SplashScreen(),
      ),
    );
  }
}

class _FirebaseErrorScreen extends StatelessWidget {
  final String? errorMessage;

  const _FirebaseErrorScreen({this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.amber, size: 80),
                const SizedBox(height: 24),
                const Text(
                  'Firebase Connection Warning',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'The app could not connect to Firebase. This could be due to network connectivity issues or server problems.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'You can continue using the app in offline mode with sample data, or try to reconnect.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Troubleshooting:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.wifi_off, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Check your internet connection',
                              style: TextStyle(color: Colors.grey[800]),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.timer_outlined, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Try again in a few minutes',
                              style: TextStyle(color: Colors.grey[800]),
                            ),
                          ),
                        ],
                      ),
                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Technical Details:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.all(8),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  errorMessage!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Reload the app by restarting with a retry for Firebase
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SplashScreen(forceRetryConnection: true),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Connection',
                        style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Start the app anyway, using offline mode
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SplashScreen(useOfflineMode: true),
                        ),
                      );
                    },
                    icon: const Icon(Icons.offline_bolt),
                    label: const Text('Continue with Offline Mode',
                        style: TextStyle(fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[400]!),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Seed sample activity logs if none exist
Future<void> _seedActivityLogsIfNeeded() async {
  try {
    debugPrint('Checking for existing activity logs...');
    final activityCollection =
        FirebaseFirestore.instance.collection('activityLogs');
    final snapshot = await activityCollection.limit(1).get();

    // Only seed if there are no existing activity logs
    if (snapshot.docs.isEmpty) {
      debugPrint('No activity logs found. Seeding sample data...');

      // Seed a sample car added activity from 2 days ago
      await ActivityLogger.seedActivityLog(
        type: ActivityType.carAdded,
        title: 'New Car Added',
        description: 'Tesla Model 3 was added to the fleet',
        userId: 'admin123',
        relatedId: 'car123',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      );

      // Seed a sample booking confirmed activity from 1 day ago
      await ActivityLogger.seedActivityLog(
        type: ActivityType.bookingCreated,
        title: 'Booking Confirmed',
        description: 'Booking #B12345 was confirmed',
        userId: 'user456',
        relatedId: 'booking456',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      );

      // Seed a sample user registered activity from today
      await ActivityLogger.seedActivityLog(
        type: ActivityType.userRegistered,
        title: 'New User Registered',
        description: 'John Doe created a new account',
        userId: 'user789',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      );

      // Add one more recent activity to ensure we have fresh data
      await ActivityLogger.seedActivityLog(
        type: ActivityType.systemUpdate,
        title: 'System Updated',
        description: 'The rental system was updated to version 1.2.0',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      debugPrint('✓ Sample activity logs seeded successfully!');
    } else {
      debugPrint(
          'Activity logs already exist (${snapshot.docs.length} found), skipping seeding');
      // Log a sample of what's in the database
      try {
        final firstDoc = snapshot.docs.first;
        debugPrint('Sample activity log: ${firstDoc.data()}');
      } catch (e) {
        debugPrint('Could not log sample activity: $e');
      }
    }
  } catch (e) {
    debugPrint('❌ Error seeding activity logs: $e');
    // Try again with a simpler approach if we hit an error
    try {
      debugPrint('Attempting fallback seeding with a single log entry...');
      await ActivityLogger.seedActivityLog(
        type: ActivityType.systemUpdate,
        title: 'System Initialized',
        description: 'The rental system was initialized',
        timestamp: DateTime.now(),
      );
      debugPrint('Fallback seeding successful');
    } catch (fallbackError) {
      debugPrint('Fallback seeding also failed: $fallbackError');
    }
  }
}

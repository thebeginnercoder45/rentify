import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_event.dart';
import 'auth_state.dart';

// Import with alias to prevent conflicts
import '../../data/models/app_user_simple.dart' as app_model;

/// This function is a safe wrapper for login that handles PigeonUserDetails errors
/// by using direct constructor calls and avoiding problematic pigeon methods
Future<User?> safeLogin(
    FirebaseAuth auth, String email, String password) async {
  try {
    // Sign in and get the user credential
    final userCredential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Return the user object
    return userCredential.user;
  } catch (e) {
    // If there's an error with PigeonUserDetails, try to get currentUser
    if (e.toString().contains('PigeonUserDetails') ||
        e.toString().contains('List<Object?>')) {
      // The login may have succeeded even if we got the error
      // Check if the current user is set and return it
      return auth.currentUser;
    }

    // If it's a different error, rethrow it
    rethrow;
  }
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthBloc({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore,
        super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginWithEmailPassword>(_onLoginWithEmailPassword);
    on<SignupWithEmailPassword>(_onSignupWithEmailPassword);
    on<LoginAsGuest>(_onLoginAsGuest);
    on<Logout>(_onLogout);
    on<UpdateAuthenticatedUser>(_onUpdateAuthenticatedUser);
    on<UpdateGuestUser>(_onUpdateGuestUser);
    on<SetAdminRole>(_onSetAdminRole);
  }

  // Handle app user and simple user separately
  void _onUpdateAuthenticatedUser(
    UpdateAuthenticatedUser event,
    Emitter<AuthState> emit,
  ) {
    emit(Authenticated(appUser: event.user, isNewUser: false));
  }

  void _onUpdateGuestUser(
    UpdateGuestUser event,
    Emitter<AuthState> emit,
  ) {
    emit(GuestMode(appUser: event.user));
  }

  // Event handler for checking auth status
  FutureOr<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        emit(Unauthenticated());
        return;
      }

      // Create user without relying on the Firebase user object
      try {
        // Get user data from Firestore
        final userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists && userDoc.data() != null) {
          // Create AppUser from the document data
          final userData = userDoc.data() as Map<String, dynamic>;
          final appUser = app_model.AppUser(
            uid: currentUser.uid,
            email: userData['email'] ?? currentUser.email ?? '',
            displayName:
                userData['displayName'] ?? currentUser.displayName ?? '',
            phoneNumber: userData['phoneNumber'] ?? '',
            isAnonymous: userData['isAnonymous'] ?? currentUser.isAnonymous,
            isAdmin: userData['isAdmin'] ?? false,
            isGuest: userData['isGuest'] ?? false,
          );

          // Emit authenticated state
          if (currentUser.isAnonymous) {
            emit(GuestMode(appUser: appUser));
          } else {
            emit(Authenticated(appUser: appUser, isNewUser: false));
          }
        } else {
          // If no document exists, create a basic user from Firebase data
          final appUser = app_model.AppUser(
            uid: currentUser.uid,
            email: currentUser.email ?? '',
            displayName: currentUser.displayName ?? '',
            phoneNumber: currentUser.phoneNumber ?? '',
            isAnonymous: currentUser.isAnonymous,
            isAdmin: false,
            isGuest: currentUser.isAnonymous,
          );

          // Save this minimal user to Firestore in the background
          try {
            await _firestore.collection('users').doc(currentUser.uid).set(
                  appUser.toMap(),
                  SetOptions(merge: true),
                );
          } catch (_) {
            // Ignore Firestore errors
          }

          if (currentUser.isAnonymous) {
            emit(GuestMode(appUser: appUser));
          } else {
            emit(Authenticated(appUser: appUser, isNewUser: false));
          }
        }
      } catch (_) {
        // If Firestore fails, create a minimal user from Firebase data
        final appUser = app_model.AppUser(
          uid: currentUser.uid,
          email: currentUser.email ?? '',
          displayName: currentUser.displayName ?? '',
          phoneNumber: currentUser.phoneNumber ?? '',
          isAnonymous: currentUser.isAnonymous,
          isAdmin: false,
          isGuest: currentUser.isAnonymous,
        );

        if (currentUser.isAnonymous) {
          emit(GuestMode(appUser: appUser));
        } else {
          emit(Authenticated(appUser: appUser, isNewUser: false));
        }
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  void _onLoginWithEmailPassword(
    LoginWithEmailPassword event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Use the safe login method
      final user =
          await safeLogin(_auth, event.email.trim(), event.password.trim());

      if (user != null) {
        try {
          // Try to get user data from Firestore
          DocumentSnapshot userDoc =
              await _firestore.collection('users').doc(user.uid).get();

          if (userDoc.exists && userDoc.data() != null) {
            Map<String, dynamic> userData =
                userDoc.data() as Map<String, dynamic>;

            app_model.AppUser appUser = app_model.AppUser(
              uid: user.uid,
              email: userData['email'] ?? user.email ?? '',
              displayName: userData['displayName'] ?? user.displayName ?? '',
              phoneNumber: userData['phoneNumber'] ?? '',
              isAnonymous: userData['isAnonymous'] ?? false,
              isAdmin: userData['isAdmin'] ?? false,
              isGuest: userData['isGuest'] ?? false,
            );

            emit(Authenticated(appUser: appUser, isNewUser: false));
          } else {
            // If user document doesn't exist, create a minimal user object
            app_model.AppUser appUser = app_model.AppUser(
              uid: user.uid,
              email: user.email ?? '',
              displayName: user.displayName ?? '',
              phoneNumber: user.phoneNumber ?? '',
              isAnonymous: user.isAnonymous,
              isAdmin: false,
              isGuest: false,
            );

            // Save this minimal user to Firestore in the background
            try {
              await _firestore.collection('users').doc(user.uid).set(
                    appUser.toMap(),
                    SetOptions(merge: true),
                  );
            } catch (_) {
              // Ignore Firestore errors
            }

            emit(Authenticated(appUser: appUser, isNewUser: false));
          }
        } catch (e) {
          // If there's an error getting from Firestore, still authenticate with minimal user data
          app_model.AppUser appUser = app_model.AppUser(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? '',
            phoneNumber: user.phoneNumber ?? '',
            isAnonymous: user.isAnonymous,
            isAdmin: false,
            isGuest: false,
          );

          emit(Authenticated(appUser: appUser, isNewUser: false));
        }
      } else {
        emit(AuthError('Login failed: User is null'));
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format.';
          break;
        case 'user-disabled':
          errorMessage = 'User account has been disabled.';
          break;
        default:
          errorMessage = 'Login failed: ${e.message}';
          break;
      }

      emit(AuthError(errorMessage));
    } catch (e) {
      emit(AuthError('Login failed: ${e.toString()}'));
    }
  }

  FutureOr<void> _onSignupWithEmailPassword(
    SignupWithEmailPassword event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Attempt to create a new account with Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;

        try {
          // Use non-null displayName or default to empty string
          final displayName = event.name ?? '';
          // Update the user profile with the provided name
          await userCredential.user!.updateDisplayName(displayName);
        } catch (_) {
          // Ignore display name update errors
        }

        // Create a new AppUser instance
        final appUser = app_model.AppUser(
          uid: uid,
          email: event.email,
          displayName: event.name ?? '', // Use non-null value
          phoneNumber: '',
          isAnonymous: false,
          isAdmin: false,
          isGuest: false,
        );

        try {
          // Save to Firestore
          await _firestore.collection('users').doc(uid).set(appUser.toMap());
        } catch (_) {
          // Ignore Firestore errors
        }

        // Emit authenticated state with the new user
        emit(Authenticated(appUser: appUser, isNewUser: true));
      } else {
        emit(AuthError("Signup failed: No user created"));
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already registered';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled';
          break;
        default:
          errorMessage = 'Signup failed: ${e.message}';
      }
      emit(AuthError(errorMessage));
    } catch (e) {
      emit(AuthError("Signup failed: ${e.toString()}"));
    }
  }

  // Guest login
  FutureOr<void> _onLoginAsGuest(
    LoginAsGuest event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Sign in anonymously with Firebase
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;

      if (user != null) {
        // Create guest user
        final appUser = app_model.AppUser(
          uid: user.uid,
          email: '',
          displayName: 'Guest',
          phoneNumber: '',
          isAnonymous: true,
          isAdmin: false,
          isGuest: true,
        );

        try {
          // Try to save guest data to Firestore
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(appUser.toMap(), SetOptions(merge: true));
        } catch (_) {
          // Ignore Firestore errors
        }

        // Emit guest mode state
        emit(GuestMode(appUser: appUser));
      } else {
        emit(AuthError("Guest login failed"));
      }
    } catch (e) {
      emit(AuthError("Guest login failed: ${e.toString()}"));
    }
  }

  // Logout
  FutureOr<void> _onLogout(
    Logout event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Sign out from Firebase
      await _auth.signOut();

      // Add a small delay to allow the UI to update
      await Future.delayed(const Duration(milliseconds: 300));

      // Emit unauthenticated state
      emit(Unauthenticated());
    } catch (e) {
      // Even if there's an error, force to unauthenticated state
      emit(Unauthenticated());
    }
  }

  // Set admin role
  FutureOr<void> _onSetAdminRole(
    SetAdminRole event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());

      // Update admin status in Firestore
      await _firestore.collection('users').doc(event.userId).update({
        'isAdmin': event.isAdmin,
      });

      // If the current state is Authenticated, check if this is the current user
      if (state is Authenticated) {
        final currentState = state as Authenticated;
        final currentUser = currentState.appUser;

        // If this is the current user, update the state
        if (currentUser.uid == event.userId) {
          // Create updated app user model with admin role changed
          final updatedUser = app_model.AppUser(
            uid: currentUser.uid,
            email: currentUser.email,
            displayName: currentUser.displayName,
            phoneNumber: currentUser.phoneNumber ?? '',
            isAnonymous: currentUser.isAnonymous,
            isAdmin: event.isAdmin,
            isGuest: currentUser.isGuest,
          );

          // Emit authenticated state with updated user
          emit(Authenticated(appUser: updatedUser, isNewUser: false));
          emit(AuthSuccess('Admin status updated successfully'));
        } else {
          emit(AuthSuccess('User admin status updated successfully'));
        }
      } else {
        emit(AuthSuccess('User admin status updated successfully'));
      }
    } catch (e) {
      emit(AuthError('Failed to update admin status: ${e.toString()}'));
    }
  }
}

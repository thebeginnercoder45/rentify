import 'package:flutter/foundation.dart';
import '../../data/models/app_user_simple.dart' as app_model;

abstract class AuthState {
  const AuthState();

  List<Object?> get props => [];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthState && other.runtimeType == runtimeType;
  }

  @override
  int get hashCode => props.hashCode;
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final app_model.AppUser appUser;
  final bool isNewUser;

  const Authenticated({
    required this.appUser,
    this.isNewUser = false,
  });

  @override
  List<Object?> get props => [appUser.uid, isNewUser, appUser.isAdmin];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Authenticated &&
        other.appUser.uid == appUser.uid &&
        other.isNewUser == isNewUser &&
        other.appUser.isAdmin == appUser.isAdmin;
  }

  @override
  int get hashCode => Object.hash(appUser.uid, isNewUser, appUser.isAdmin);
}

class GuestMode extends AuthState {
  final app_model.AppUser appUser;

  const GuestMode({required this.appUser});

  @override
  List<Object?> get props => [appUser.uid];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GuestMode && other.appUser.uid == appUser.uid;
  }

  @override
  int get hashCode => appUser.uid.hashCode;
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

class AuthSuccess extends AuthState {
  final String message;

  const AuthSuccess(this.message);

  @override
  List<Object?> get props => [message];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthSuccess && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

import 'package:rentapp/data/models/app_user_simple.dart' as app_model;

abstract class AuthEvent {
  const AuthEvent();

  List<Object?> get props => [];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthEvent && other.runtimeType == runtimeType;
  }

  @override
  int get hashCode => props.hashCode;
}

class CheckAuthStatus extends AuthEvent {}

class LoginWithEmailPassword extends AuthEvent {
  final String email;
  final String password;

  const LoginWithEmailPassword({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoginWithEmailPassword &&
        other.email == email &&
        other.password == password;
  }

  @override
  int get hashCode => Object.hash(email, password);
}

class SignupWithEmailPassword extends AuthEvent {
  final String email;
  final String password;
  final String? name;

  const SignupWithEmailPassword({
    required this.email,
    required this.password,
    this.name,
  });

  @override
  List<Object?> get props => [email, password, name];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SignupWithEmailPassword &&
        other.email == email &&
        other.password == password &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(email, password, name);
}

class LoginAsGuest extends AuthEvent {}

class Logout extends AuthEvent {}

class UpdateAuthenticatedUser extends AuthEvent {
  final app_model.AppUser user;

  const UpdateAuthenticatedUser(this.user);

  @override
  List<Object?> get props => [user];
}

class UpdateGuestUser extends AuthEvent {
  final app_model.AppUser user;

  const UpdateGuestUser(this.user);

  @override
  List<Object?> get props => [user];
}

class ConvertGuestToUser extends AuthEvent {
  final String email;
  final String password;
  final String? name;

  const ConvertGuestToUser({
    required this.email,
    required this.password,
    this.name,
  });

  @override
  List<Object?> get props => [email, password, name];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConvertGuestToUser &&
        other.email == email &&
        other.password == password &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(email, password, name);
}

class SetAdminRole extends AuthEvent {
  final String userId;
  final bool isAdmin;

  const SetAdminRole({
    required this.userId,
    required this.isAdmin,
  });

  @override
  List<Object?> get props => [userId, isAdmin];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SetAdminRole &&
        other.userId == userId &&
        other.isAdmin == isAdmin;
  }

  @override
  int get hashCode => Object.hash(userId, isAdmin);
}

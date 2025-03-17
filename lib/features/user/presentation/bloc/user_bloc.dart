import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/user_model.dart';
import '../../data/repositories/user_repository.dart';

// Events
abstract class UserEvent {}

class LoadUsers extends UserEvent {}

class BlockUser extends UserEvent {
  final String userId;
  BlockUser(this.userId);
}

class UnblockUser extends UserEvent {
  final String userId;
  UnblockUser(this.userId);
}

class DeleteUser extends UserEvent {
  final String userId;
  DeleteUser(this.userId);
}

// States
abstract class UserState {}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UsersLoaded extends UserState {
  final List<UserModel> users;
  UsersLoaded(this.users);
}

class UserError extends UserState {
  final String message;
  UserError(this.message);
}

// Bloc
class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository userRepository;

  UserBloc({required this.userRepository}) : super(UserInitial()) {
    on<LoadUsers>(_onLoadUsers);
    on<BlockUser>(_onBlockUser);
    on<UnblockUser>(_onUnblockUser);
    on<DeleteUser>(_onDeleteUser);
  }

  Future<void> _onLoadUsers(LoadUsers event, Emitter<UserState> emit) async {
    try {
      emit(UserLoading());
      final users = await userRepository.getAllUsers();
      emit(UsersLoaded(users));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onBlockUser(BlockUser event, Emitter<UserState> emit) async {
    try {
      await userRepository.blockUser(event.userId);
      add(LoadUsers());
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onUnblockUser(
    UnblockUser event,
    Emitter<UserState> emit,
  ) async {
    try {
      await userRepository.unblockUser(event.userId);
      add(LoadUsers());
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onDeleteUser(DeleteUser event, Emitter<UserState> emit) async {
    try {
      await userRepository.deleteUser(event.userId);
      add(LoadUsers());
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }
}

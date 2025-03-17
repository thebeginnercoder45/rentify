import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/admin_repository.dart';
import '../../domain/models/admin_model.dart';

// Events
abstract class AdminEvent {}

class CheckAdminStatus extends AdminEvent {}

class LoadDashboardStats extends AdminEvent {}

class LoadAllAdmins extends AdminEvent {}

class CreateAdmin extends AdminEvent {
  final String userId;
  final String name;
  final String email;
  final List<String> permissions;

  CreateAdmin({
    required this.userId,
    required this.name,
    required this.email,
    required this.permissions,
  });
}

class UpdateAdminPermissions extends AdminEvent {
  final String adminId;
  final List<String> permissions;

  UpdateAdminPermissions({required this.adminId, required this.permissions});
}

class DeleteAdmin extends AdminEvent {
  final String adminId;

  DeleteAdmin(this.adminId);
}

// States
abstract class AdminState {}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminAuthenticated extends AdminState {
  final AdminModel admin;

  AdminAuthenticated(this.admin);
}

class AdminUnauthenticated extends AdminState {}

class DashboardStatsLoaded extends AdminState {
  final Map<String, dynamic> stats;

  DashboardStatsLoaded(this.stats);
}

class AdminsLoaded extends AdminState {
  final List<AdminModel> admins;

  AdminsLoaded(this.admins);
}

class AdminError extends AdminState {
  final String message;

  AdminError(this.message);
}

// Bloc
class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository _repository;

  AdminBloc(this._repository) : super(AdminInitial()) {
    on<CheckAdminStatus>(_onCheckAdminStatus);
    on<LoadDashboardStats>(_onLoadDashboardStats);
    on<LoadAllAdmins>(_onLoadAllAdmins);
    on<CreateAdmin>(_onCreateAdmin);
    on<UpdateAdminPermissions>(_onUpdateAdminPermissions);
    on<DeleteAdmin>(_onDeleteAdmin);
  }

  Future<void> _onCheckAdminStatus(
    CheckAdminStatus event,
    Emitter<AdminState> emit,
  ) async {
    try {
      emit(AdminLoading());
      final admin = await _repository.getCurrentAdmin();
      if (admin != null) {
        emit(AdminAuthenticated(admin));
      } else {
        emit(AdminUnauthenticated());
      }
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onLoadDashboardStats(
    LoadDashboardStats event,
    Emitter<AdminState> emit,
  ) async {
    try {
      emit(AdminLoading());
      final stats = await _repository.getDashboardStats();
      emit(DashboardStatsLoaded(stats));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onLoadAllAdmins(
    LoadAllAdmins event,
    Emitter<AdminState> emit,
  ) async {
    try {
      emit(AdminLoading());
      final admins = await _repository.getAllAdmins();
      emit(AdminsLoaded(admins));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onCreateAdmin(
    CreateAdmin event,
    Emitter<AdminState> emit,
  ) async {
    try {
      emit(AdminLoading());
      await _repository.createAdmin(
        userId: event.userId,
        name: event.name,
        email: event.email,
        permissions: event.permissions,
      );
      add(LoadAllAdmins());
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onUpdateAdminPermissions(
    UpdateAdminPermissions event,
    Emitter<AdminState> emit,
  ) async {
    try {
      emit(AdminLoading());
      await _repository.updateAdminPermissions(
        adminId: event.adminId,
        permissions: event.permissions,
      );
      add(LoadAllAdmins());
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onDeleteAdmin(
    DeleteAdmin event,
    Emitter<AdminState> emit,
  ) async {
    try {
      emit(AdminLoading());
      await _repository.deleteAdmin(event.adminId);
      add(LoadAllAdmins());
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }
}

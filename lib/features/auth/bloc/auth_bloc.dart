import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/token_storage_service.dart';
import '../../../core/network/api_error_handler.dart';
import '../../../data/repositories/karatflow_api_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

/// Authentication BLoC with Strict Live API Integration & Debug Logs
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    TokenStorageService? tokenStorage,
    KaratFlowApiRepository? apiRepository,
  }) : _tokenStorage = tokenStorage ?? TokenStorageService(),
       _api = apiRepository ?? KaratFlowApiRepository(),
       super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginSubmitted>(_onAuthLoginSubmitted);
    on<AuthRoleChanged>(_onAuthRoleChanged);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
  }

  final TokenStorageService _tokenStorage;
  final KaratFlowApiRepository _api;

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        emit(const AuthUnauthenticated());
        return;
      }

      final profile = await _api.getProfile();
      final role = profile.role.toLowerCase();
      await _tokenStorage.saveUserRole(role);

      emit(
        AuthAuthenticated(
          token: token,
          role: role,
          userName: profile.name,
          userEmail: profile.email,
          userPhone: profile.phone,
          isActive: profile.isActive,
        ),
      );
    } catch (e) {
      await _tokenStorage.clearAll();
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final authData = await _api.login(
        email: event.username.trim(),
        password: event.password.trim(),
      );

      await _tokenStorage.saveAccessToken(authData.token);
      await _tokenStorage.saveRefreshToken(authData.refreshToken);

      // Some login responses omit the user object. Load /auth/me in that
      // case instead of inventing a local profile.
      final profile = authData.user ?? await _api.getProfile();
      final userRole = profile.role.toLowerCase();
      await _tokenStorage.saveUserRole(userRole);

      emit(
        AuthAuthenticated(
          token: authData.token,
          role: userRole,
          userName: profile.name,
          userEmail: profile.email,
          userPhone: profile.phone,
          isActive: profile.isActive,
        ),
      );
    } catch (e) {
      emit(
        AuthError(
          ApiErrorHandler.parseMessage(
            e,
            fallback: 'Login failed. Check your email and password.',
          ),
        ),
      );
    }
  }

  Future<void> _onAuthRoleChanged(
    AuthRoleChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthAuthenticated) {
      final current = state as AuthAuthenticated;
      await _tokenStorage.saveUserRole(event.role);
      emit(
        AuthAuthenticated(
          token: current.token,
          role: event.role,
          userName: current.userName,
          userEmail: current.userEmail,
          userPhone: current.userPhone,
          isActive: current.isActive,
        ),
      );
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    await _tokenStorage.clearAll();
    emit(const AuthUnauthenticated());
  }
}

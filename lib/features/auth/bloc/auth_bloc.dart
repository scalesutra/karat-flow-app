import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/token_storage_service.dart';
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
    debugPrint('🔍 [AuthBloc] Checking stored session token...');
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        debugPrint('ℹ️ [AuthBloc] No active session found.');
        emit(const AuthUnauthenticated());
        return;
      }

      debugPrint(
        '👤 [AuthBloc] Fetching profile for existing token from GET /auth/me...',
      );
      final profile = await _api.getProfile();
      final role = profile.role.toLowerCase();
      await _tokenStorage.saveUserRole(role);

      debugPrint(
        '✅ [AuthBloc] Session verified. User: ${profile.name}, Role: $role',
      );
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
      debugPrint('⚠️ [AuthBloc] Stored session invalid or expired: $e');
      await _tokenStorage.clearAll();
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    debugPrint(
      '🔐 [AuthBloc] Submitting login request for ${event.username} to POST /auth/login...',
    );
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

      debugPrint(
        '🎉 [AuthBloc] Login success! Name: ${profile.name}, Role: $userRole, JWT Token length: ${authData.token.length}',
      );

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
      debugPrint('❌ [AuthBloc] Login failed with error: $e');
      emit(AuthError('Login failed: ${e.toString()}'));
    }
  }

  Future<void> _onAuthRoleChanged(
    AuthRoleChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthAuthenticated) {
      final current = state as AuthAuthenticated;
      debugPrint('🔄 [AuthBloc] Switching role to: ${event.role}');
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
    debugPrint('🚪 [AuthBloc] Logging out and clearing all secure tokens...');
    await _tokenStorage.clearAll();
    debugPrint('✅ [AuthBloc] Logout complete.');
    emit(const AuthUnauthenticated());
  }
}

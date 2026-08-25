/// Base Authentication State (Minimal & clear states)
sealed class AuthState {
  const AuthState();
}

/// Initial state before session check
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Authentication in-progress (logging in / validating token)
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authenticated user session
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({
    required this.token,
    required this.role,
    this.userName = '',
    this.userEmail = '',
    this.userPhone = '',
    this.isActive = true,
  });

  final String token;
  final String role;
  final String userName;
  final String userEmail;
  final String userPhone;
  final bool isActive;
}

/// Logged out / unauthenticated
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Authentication failure / error
final class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;
}

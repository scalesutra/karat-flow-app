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
    this.userName = 'Operator',
  });

  final String token;
  final String role;
  final String userName;
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

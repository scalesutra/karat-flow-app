/// Base Authentication Event (Pure Dart, no Equatable)
sealed class AuthEvent {
  const AuthEvent();
}

/// App startup authentication check
final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Login with user credentials
final class AuthLoginSubmitted extends AuthEvent {
  const AuthLoginSubmitted({required this.username, required this.password});

  final String username;
  final String password;
}

/// Switch active workshop/operator role
final class AuthRoleChanged extends AuthEvent {
  const AuthRoleChanged(this.role);

  final String role;
}

/// Clear session & logout
final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

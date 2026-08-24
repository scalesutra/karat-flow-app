import '../../../domain/models.dart';

/// Base Admin State (Minimal, readable and clean)
sealed class AdminState {
  const AdminState();
}

/// Initial admin state
final class AdminInitial extends AdminState {
  const AdminInitial();
}

/// Loading admin dashboard / stock data
final class AdminLoading extends AdminState {
  const AdminLoading();
}

/// Admin overview & governance data successfully loaded
final class AdminLoaded extends AdminState {
  const AdminLoaded({
    required this.team,
    required this.clients,
    required this.designs,
    required this.directives,
  });

  final List<TeamMember> team;
  final List<ClientInfo> clients;
  final List<JewelleryDesign> designs;
  final List<Map<String, String>> directives;
}

/// Admin action completed successfully
final class AdminActionSuccess extends AdminState {
  const AdminActionSuccess(this.message);

  final String message;
}

/// Admin error occurred
final class AdminError extends AdminState {
  const AdminError(this.message);

  final String message;
}

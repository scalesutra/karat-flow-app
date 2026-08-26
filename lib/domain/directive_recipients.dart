import 'models.dart';

abstract final class DirectiveRecipients {
  static const String allTeams = 'All Teams';

  static const List<String> options = [
    allTeams,
    'CAD Designer',
    'Product Manager',
    'Front Office',
    'Raw Designer',
    'Workshop Artisan',
    'Goldsmith (Artisans)',
    'QC Team',
    'Store Keeper',
  ];

  static bool matchesRole(String recipient, AppRole role) {
    final normalized = recipient.trim().toLowerCase();
    if (normalized == 'all' || normalized == allTeams.toLowerCase()) {
      return true;
    }

    final aliases = switch (role) {
      AppRole.admin => const ['admin'],
      AppRole.cadDesigner => const [
        'cad designer',
        '3d designer',
        'three d designer',
      ],
      AppRole.processManager => const [
        'product manager',
        'process manager',
        'production manager',
      ],
      AppRole.frontOffice => const ['front office', 'sales & orders'],
      AppRole.rawDesigner => const ['raw designer', 'sketch designer'],
      AppRole.workshopArtisan => const [
        'workshop artisan',
        'goldsmith (artisans)',
        'goldsmith',
        'qc team',
        'store keeper',
        'vault / store keeper',
      ],
    };
    return aliases.any((alias) => normalized == alias);
  }
}

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
    final normalized = recipient.trim().toLowerCase().replaceAll('_', ' ');
    if (normalized == 'all' ||
        normalized == 'all teams' ||
        normalized == allTeams.toLowerCase()) {
      return true;
    }

    final aliases = switch (role) {
      AppRole.admin => const ['admin', 'all'],
      AppRole.cadDesigner => const [
        'cad designer',
        '3d designer',
        'three d designer',
        'cad',
      ],
      AppRole.processManager => const [
        'product manager',
        'process manager',
        'production manager',
      ],
      AppRole.frontOffice => const ['front office', 'sales & orders', 'sales'],
      AppRole.rawDesigner => const [
        'raw designer',
        'sketch designer',
        'sketcher',
        'sketch',
        'designer',
      ],
      AppRole.workshopArtisan => const [
        'workshop artisan',
        'all artisans',
        'bench artisan',
        'goldsmith (artisans)',
        'goldsmith',
        'qc team',
      ],
      AppRole.worker => const [
        'worker',
        'bench worker',
        'factory worker',
        'goldsmith',
        'artisan',
      ],
      AppRole.stockist => const [
        'stockist',
        'vault keeper',
        'store keeper',
        'vault / store keeper',
        'stock manager',
      ],
    };
    return aliases.any((alias) => normalized.contains(alias) || alias.contains(normalized));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/common_card.dart';
import '../bloc/auth_bloc.dart';

/// Displays only the profile returned by the authentication API.
class AuthenticatedProfileCard extends StatelessWidget {
  const AuthenticatedProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading || state is AuthInitial) {
          return const CommonCard(
            backgroundColor: AppColors.ink,
            child: Center(
              child: SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFFFD18A),
                ),
              ),
            ),
          );
        }

        if (state is! AuthAuthenticated) {
          return const CommonCard(
            backgroundColor: AppColors.ink,
            child: Text(
              'Profile unavailable',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final name = state.userName.trim().isEmpty
            ? 'Profile name unavailable'
            : state.userName.trim();
        final role = _roleLabel(state.role);
        final contactItems = <Widget>[
          if (state.userEmail.trim().isNotEmpty)
            _ContactItem(icon: Icons.email_outlined, value: state.userEmail),
          if (state.userPhone.trim().isNotEmpty)
            _ContactItem(icon: Icons.phone_outlined, value: state.userPhone),
        ];

        return CommonCard(
          backgroundColor: AppColors.ink,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.emerald,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _initials(name),
                      style: const TextStyle(
                        color: AppColors.pureWhite,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.pureWhite,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          role,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFFFD18A),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (state.isActive ? AppColors.success : AppColors.muted)
                              .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull,
                      ),
                    ),
                    child: Text(
                      state.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: state.isActive
                            ? AppColors.successLight
                            : Colors.white70,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              if (contactItems.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(spacing: 16, runSpacing: 8, children: contactItems),
              ],
            ],
          ),
        );
      },
    );
  }

  static String _initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty || name == 'Profile name unavailable') return '--';
    return parts.map((part) => part[0].toUpperCase()).join();
  }

  static String _roleLabel(String role) {
    const labels = <String, String>{
      'ADMIN': 'Admin',
      'FRONT_OFFICE': 'Front Office',
      'PROCESS_MANAGER': 'Production Manager',
      'PRODUCTION_MANAGER': 'Production Manager',
      'CAD_DESIGNER': 'CAD Designer',
    };
    final normalized = role.trim().toUpperCase();
    if (normalized.isEmpty) return 'Role unavailable';
    return labels[normalized] ??
        normalized
            .split('_')
            .where((part) => part.isNotEmpty)
            .map((part) => '${part[0]}${part.substring(1).toLowerCase()}')
            .join(' ');
  }
}

class _ContactItem extends StatelessWidget {
  const _ContactItem({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFFFD18A), size: 14),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

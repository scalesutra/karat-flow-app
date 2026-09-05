import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../data/demo_store.dart';
import '../../domain/models.dart';
import '../directives/bloc/directives_bloc.dart';
import 'directive_audio.dart';

/// Top bar notification bell button with active directive count badge.
/// When tapped, displays all active Admin directives and voice/image notes for the role.
class DirectivesNotificationButton extends StatelessWidget {
  const DirectivesNotificationButton({
    super.key,
    required this.currentRole,
    this.store,
  });

  final AppRole? currentRole;
  final DemoStore? store;

  @override
  Widget build(BuildContext context) {
    final effectiveStore = store ?? DemoStore.instance;

    return AnimatedBuilder(
      animation: effectiveStore,
      builder: (context, _) {
        final role = currentRole ?? AppRole.frontOffice;
        final List<Map<String, String>> directives;
        if (role == AppRole.admin) {
          directives = effectiveStore.adminDirectives
              .where((d) =>
                  d['status'] == 'Active' &&
                  (d['recipient']?.toLowerCase().trim() == 'admin'))
              .toList();
        } else {
          directives = effectiveStore.directivesForRole(role);
        }

        final unreadCount = directives.length;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: unreadCount > 0
                  ? '$unreadCount Admin Directive${unreadCount > 1 ? 's' : ''}'
                  : 'Notifications & Directives',
              icon: Icon(
                unreadCount > 0
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
                color: unreadCount > 0 ? AppColors.goldDark : AppColors.ink,
                size: 22,
              ),
              onPressed: () {
                try {
                  context.read<DirectivesBloc>().add(const FetchDirectivesEvent());
                } catch (_) {}
                _showDirectivesSheet(context, role, effectiveStore);
              },
            ),
            if (unreadCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showDirectivesSheet(
    BuildContext context,
    AppRole role,
    DemoStore store,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _DirectivesNotificationModal(
        role: role,
        store: store,
      ),
    );
  }
}

class _DirectivesNotificationModal extends StatelessWidget {
  const _DirectivesNotificationModal({
    required this.role,
    required this.store,
  });

  final AppRole role;
  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.goldLight.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.campaign_outlined,
                    color: AppColors.goldDark,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Admin Directives & Notices',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'Role: ${role.label} · Directives from Admin',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.outline),

          // Content List
          Expanded(
            child: AnimatedBuilder(
              animation: store,
              builder: (context, _) {
                final directives = role == AppRole.admin
                    ? store.adminDirectives
                        .where((d) =>
                            d['status'] == 'Active' &&
                            (d['recipient']?.toLowerCase().trim() == 'admin'))
                        .toList()
                    : store.directivesForRole(role);

                if (directives.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.sage.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              size: 40,
                              color: AppColors.emerald,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'No Pending Directives',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'All instructions are cleared. Any new directives sent by Admin will appear here instantly.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  itemCount: directives.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final directive = directives[index];
                    return _NotificationDirectiveCard(
                      directive: directive,
                      store: store,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationDirectiveCard extends StatelessWidget {
  const _NotificationDirectiveCard({
    required this.directive,
    required this.store,
  });

  final Map<String, String> directive;
  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    final message = DirectiveMessage.parse(directive['content'] ?? '');
    final audioUrl = directive['audioUrl']?.trim().isNotEmpty == true
        ? directive['audioUrl']!.trim()
        : message.audioUrl;
    final imageUrl = directive['imageUrl']?.trim().isNotEmpty == true
        ? directive['imageUrl']!.trim()
        : message.imageUrl;

    final displayText = message.text.isNotEmpty
        ? message.text
        : (directive['title']?.trim().isNotEmpty == true
            ? directive['title']!
            : 'Directive Note Attached');

    final acknowledged = directive['status'] == 'Acknowledged';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: acknowledged
            ? AppColors.canvas
            : AppColors.goldLight.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: acknowledged
              ? AppColors.outline
              : AppColors.gold.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.goldDark.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'To: ${directive['recipient'] ?? 'All Teams'}',
                  style: const TextStyle(
                    color: AppColors.goldDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                directive['date'] ?? '',
                style: const TextStyle(color: AppColors.muted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            displayText,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.ink,
              height: 1.3,
            ),
          ),
          if (audioUrl != null && audioUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            DirectiveVoiceButton(audioUrl: audioUrl),
          ],
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            DirectiveImageAttachment(imageUrl: imageUrl),
          ],
          if (!acknowledged) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  try {
                    context.read<DirectivesBloc>().add(
                          AcknowledgeDirectiveEvent(directive['id'] ?? ''),
                        );
                  } catch (_) {}
                },
                icon: const Icon(Icons.check_circle_outline, size: 14),
                label: const Text('Mark as Acknowledged'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

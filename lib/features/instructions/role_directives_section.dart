import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/common_card.dart';
import '../../data/demo_store.dart';
import '../../domain/models.dart';
import 'directive_audio.dart';

class RoleDirectivesSection extends StatelessWidget {
  const RoleDirectivesSection({
    super.key,
    required this.store,
    required this.role,
  });

  final DemoStore store;
  final AppRole role;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final directives = store.directivesForRole(role);
        return CommonCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.campaign_outlined,
                    color: AppColors.goldDark,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Admin Directives & Voice Notes',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    '${directives.length} Active',
                    style: const TextStyle(
                      color: AppColors.goldDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (directives.isEmpty)
                const Text(
                  'No directives assigned to your role.',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                )
              else
                ...directives.map(
                  (directive) =>
                      _RoleDirectiveTile(directive: directive, store: store),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RoleDirectiveTile extends StatelessWidget {
  const _RoleDirectiveTile({required this.directive, required this.store});

  final Map<String, String> directive;
  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    final message = DirectiveMessage.parse(directive['content'] ?? '');
    final acknowledged = directive['status'] == 'Acknowledged';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: acknowledged
            ? AppColors.canvas
            : AppColors.goldLight.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'To: ${directive['recipient'] ?? 'All Teams'}',
                  style: const TextStyle(
                    color: AppColors.goldDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                directive['date'] ?? '',
                style: const TextStyle(color: AppColors.muted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message.text.isEmpty
                ? 'Voice Directive Note Attached'
                : message.text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          if (message.hasAudio) ...[
            const SizedBox(height: 8),
            DirectiveVoiceButton(audioUrl: message.audioUrl!),
          ],
          if (message.hasImage) ...[
            const SizedBox(height: 8),
            DirectiveImageAttachment(imageUrl: message.imageUrl!),
          ],
          if (!acknowledged) ...[
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: () =>
                  store.acknowledgeDirective(directive['id'] ?? ''),
              icon: const Icon(Icons.done, size: 16),
              label: const Text('Acknowledge'),
            ),
          ],
        ],
      ),
    );
  }
}

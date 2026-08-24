import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/common_progress_indicator.dart';
import '../../../../data/demo_store.dart';

/// Workshop Process Manager - Artisans & Goldsmiths Workload Tab
class ArtisansPeopleTab extends StatelessWidget {
  const ArtisansPeopleTab({super.key, required this.store});

  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    final allLots = store.lots;
    final artisans = store.team.map((member) {
      final assignedLots = allLots
          .where(
            (l) =>
                l.assignedEmployee.trim().toLowerCase() ==
                member.name.trim().toLowerCase(),
          )
          .toList();

      final int totalPieces = assignedLots.fold(0, (sum, l) => sum + l.pieces);
      final String taskText;
      final String statusText;
      final Color statusColor;

      if (assignedLots.isNotEmpty) {
        final lotSummary = assignedLots
            .map(
              (l) => '${l.productTitle} (${l.pieces} pcs in ${l.stage.label})',
            )
            .join(' · ');
        taskText =
            '${assignedLots.length} Lot(s) · $totalPieces Pcs: $lotSummary';
        statusText = 'Working (${assignedLots.length} Lots)';
        statusColor = AppColors.emerald;
      } else {
        taskText = 'No active lot assigned (Available)';
        statusText = 'Free';
        statusColor = AppColors.muted;
      }

      return {
        'member': member,
        'name': member.name,
        'craft': member.craft,
        'lotsCount': assignedLots.length,
        'totalPieces': totalPieces,
        'task': taskText,
        'status': statusText,
        'statusColor': statusColor,
        'lots': assignedLots,
      };
    }).toList();

    final freeCount = artisans.where((p) => p['lotsCount'] == 0).length;

    return CommonRefreshIndicator(
      theme: IndicatorTheme.workshop,
      onRefresh: () async {
        await Future<void>.delayed(const Duration(milliseconds: 600));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${artisans.length} Artisans · $freeCount Available / Free',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final p in artisans) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.outline),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: (p['statusColor'] as Color)
                              .withValues(alpha: 0.15),
                          radius: 18,
                          child: Text(
                            (p['name'] as String)[0],
                            style: TextStyle(
                              color: p['statusColor'] as Color,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${p['name']} · ${p['craft']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p['task'] as String,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: (p['statusColor'] as Color).withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusFull,
                            ),
                            border: Border.all(
                              color: (p['statusColor'] as Color).withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                          child: Text(
                            p['status'] as String,
                            style: TextStyle(
                              color: p['statusColor'] as Color,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

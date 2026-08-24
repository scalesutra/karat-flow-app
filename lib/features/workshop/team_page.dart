import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/widgets.dart';
import '../../data/demo_store.dart';
import '../../domain/models.dart';

class TeamWorkloadPage extends StatefulWidget {
  const TeamWorkloadPage({super.key, required this.store});

  final DemoStore store;

  @override
  State<TeamWorkloadPage> createState() => _TeamWorkloadPageState();
}

class _TeamWorkloadPageState extends State<TeamWorkloadPage> {
  String _selectedFilter = 'All';

  final List<String> _filters = const ['All', 'Working', 'Free'];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final allLots = widget.store.lots;

        // Build dynamic list of team members with current assignment from store
        final dynamicArtisans = widget.store.team.map((member) {
          final assignedLots = allLots
              .where(
                (l) =>
                    l.assignedEmployee.trim().toLowerCase() ==
                    member.name.trim().toLowerCase(),
              )
              .toList();

          final String taskText;
          final String statusText;
          final Color statusColor;

          if (assignedLots.isNotEmpty) {
            final firstLot = assignedLots.first;
            taskText =
                '${firstLot.stage.label} · ${firstLot.orderId} (${firstLot.productTitle})';
            statusText = 'Working';
            statusColor = AppColors.emerald;
          } else {
            taskText = 'No active lot';
            statusText = 'Free';
            statusColor = AppColors.muted;
          }

          return {
            'member': member,
            'name': member.name,
            'craft': member.craft,
            'task': taskText,
            'status': statusText,
            'statusColor': statusColor,
            'assignedLotsCount': assignedLots.length,
          };
        }).toList();

        final filtered = dynamicArtisans.where((a) {
          if (_selectedFilter == 'All') return true;
          return (a['status'] as String).toLowerCase() ==
              _selectedFilter.toLowerCase();
        }).toList();

        final freeCount = dynamicArtisans
            .where((a) => a['status'] == 'Free')
            .length;

        return SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CommonText.headlineLarge('Workshop Team'),
                    const SizedBox(height: 2),
                    Text(
                      '${dynamicArtisans.length} Artisans · $freeCount Free',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filters.map((f) {
                          final isSelected = _selectedFilter == f;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () => setState(() => _selectedFilter = f),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusFull,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.emerald
                                      : AppColors.paper,
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusFull,
                                  ),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.emerald
                                        : AppColors.outline,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Text(
                                  f,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.pureWhite
                                        : AppColors.ink,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No artisans found for this filter.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final artisan = filtered[index];
                          final statusColor = artisan['statusColor'] as Color;

                          return InkWell(
                            onTap: () =>
                                _showArtisanDetailModal(context, artisan),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
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
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: statusColor.withValues(
                                      alpha: 0.15,
                                    ),
                                    radius: 20,
                                    child: Text(
                                      (artisan['name'] as String)[0],
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          artisan['name'] as String,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          artisan['task'] as String,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppDimensions.radiusFull,
                                      ),
                                      border: Border.all(
                                        color: statusColor.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      artisan['status'] as String,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showArtisanDetailModal(
    BuildContext context,
    Map<String, dynamic> artisan,
  ) {
    final member = artisan['member'] as TeamMember;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              artisan['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 2),
            Text(
              member.craft,
              style: const TextStyle(
                color: AppColors.emeraldDark,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current Activity: ${artisan['task']}',
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: CommonButton.primary(
                height: 40,
                label: 'Close',
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

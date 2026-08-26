import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jewellery_ops_mobile/core/constants/app_colors.dart';
import 'package:jewellery_ops_mobile/core/constants/app_dimensions.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_progress_indicator.dart';
import 'package:jewellery_ops_mobile/data/demo_store.dart';
import 'package:jewellery_ops_mobile/data/models/api_models.dart';
import 'package:jewellery_ops_mobile/domain/models.dart';
import '../bloc/workshop_bloc.dart';
import 'stage_lots_modal.dart';

/// Workshop Process Manager - Stages Pipeline Aggregation Tab
class StagesPipelineTab extends StatelessWidget {
  const StagesPipelineTab({super.key, required this.store});

  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkshopBloc, WorkshopState>(
      builder: (context, state) {
        if (state is WorkshopLoading) {
          return const Center(
            child: CommonProgressIndicator.workshop(
              label: 'Syncing Process Manager Pipeline...',
            ),
          );
        }

        final allLots = store.lots;
        final stageGroups = store.stages.map((apiStage) {
          final st = _domainStage(apiStage);
          final stageLots = allLots.where((l) => l.stage == st).toList();
          return {
            'stageEnum': st,
            'stageId': apiStage.id,
            'name': apiStage.name,
            'count': stageLots.length,
            'color': switch (st) {
              WorkshopStage.inQueue => AppColors.warning,
              WorkshopStage.cadAndWax => AppColors.emerald,
              WorkshopStage.casting => const Color(0xFFFFD18A),
              WorkshopStage.filingAndAssembly => AppColors.emeraldDark,
              WorkshopStage.stoneSetting => AppColors.goldDark,
              WorkshopStage.polishing => AppColors.emerald,
              WorkshopStage.qualityCheck => const Color(0xFF1E824C),
              WorkshopStage.readyForDispatch => AppColors.emerald,
            },
            'lots': stageLots,
          };
        }).toList();

        return CommonRefreshIndicator(
      theme: IndicatorTheme.workshop,
      onRefresh: () async =>
          context.read<WorkshopBloc>().add(const FetchWorkshopLotsEvent()),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
        children: [
          for (final st in stageGroups)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () =>
                    StageLotsModal.show(context, stage: st, store: store),
                borderRadius: BorderRadius.circular(14),
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
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: (st['color'] as Color).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.token,
                          color: st['color'] as Color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          st['name'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldLight,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull,
                          ),
                        ),
                        child: Text(
                          '${st['count']} lots',
                          style: const TextStyle(
                            color: AppColors.emeraldDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: AppColors.muted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
      },
    );
  }

  WorkshopStage _domainStage(ApiStage stage) {
    final normalized = stage.name.trim().toLowerCase();
    return switch (normalized) {
      'queue' || 'in queue' => WorkshopStage.inQueue,
      'waxing' || 'cad & wax' || 'cad and wax' => WorkshopStage.cadAndWax,
      'casting' => WorkshopStage.casting,
      'filing' || 'filing & assembly' => WorkshopStage.filingAndAssembly,
      'setting' || 'stone setting' => WorkshopStage.stoneSetting,
      'polishing' => WorkshopStage.polishing,
      'qc' || 'quality check' => WorkshopStage.qualityCheck,
      'ready' || 'ready for dispatch' => WorkshopStage.readyForDispatch,
      _ =>
        WorkshopStage.values[(stage.stageNumber - 1)
            .clamp(0, WorkshopStage.values.length - 1)
            .toInt()],
    };
  }
}

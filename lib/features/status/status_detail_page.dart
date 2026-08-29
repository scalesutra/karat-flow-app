import 'package:flutter/material.dart';
import 'package:jewellery_ops_mobile/core/constants/app_colors.dart';
import 'package:jewellery_ops_mobile/data/mappers/api_domain_mapper.dart';
import 'package:jewellery_ops_mobile/features/instructions/instruction_composer.dart';

import '../../core/widgets/common_app_bar.dart';
import '../../core/widgets/common_button.dart';
import '../../core/widgets/common_card.dart';
import '../../core/widgets/common_text.dart';
import '../../data/demo_store.dart';
import '../../domain/models.dart';

class StatusDetailPage extends StatelessWidget {
  const StatusDetailPage({super.key, required this.item, required this.store});

  final WorkItem item;
  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    if (item.pivot == StatusPivot.stages) {
      return _buildStageDetailPage(context);
    }
    if (item.pivot == StatusPivot.orders) {
      return _buildOrderDetailPage(context);
    }
    if (item.pivot == StatusPivot.people) {
      return _buildPeopleDetailPage(context);
    }

    final (_, color, icon) = statusTone(item.tone);
    return Scaffold(
      appBar: CommonAppBar(
        title: item.title,
        showBrand: false,
        showBackButton: true,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            CommonCard(
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.subtitle,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CommonCard(
              backgroundColor: AppColors.ink,
              child: Row(
                children: item.metrics.entries
                    .map(
                      (entry) => Expanded(
                        child: Column(
                          children: [
                            Text(
                              entry.value,
                              style: const TextStyle(
                                color: Color(0xFFFFD18A),
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              entry.key,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            const CommonText.titleMedium('Timeline & Route Events'),
            const SizedBox(height: 10),
            for (final event in item.timeline)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CommonCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Icon(
                          Icons.circle,
                          size: 8,
                          color: AppColors.emerald,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (event.detail.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                event.detail,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (event.time.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          event.time,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomSheet: SafeArea(
        top: false,
        child: Container(
          color: AppColors.canvas,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: CommonButton.primary(
            onPressed: () =>
                showInstructionComposer(context, store: store, target: item),
            icon: Icons.add_comment_outlined,
            label: 'Send Directive for ${item.title}',
          ),
        ),
      ),
    );
  }

  // ── 1. STAGE DETAILS SCREEN ──────────────────────────────────────────
  Widget _buildStageDetailPage(BuildContext context) {
    final activeLots = store.lotsForStageName(item.id);
    final heldLots = activeLots.where((lot) => lot.isOnHold).toList();
    final totalPcs = activeLots.fold(0, (sum, l) => sum + l.pieces);

    return Scaffold(
      appBar: CommonAppBar(
        title: item.title,
        showBrand: false,
        showBackButton: true,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            CommonCard(
              backgroundColor: AppColors.ink,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.emerald.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Icon(
                          Icons.precision_manufacturing_rounded,
                          color: AppColors.gold,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.subtitle,
                              style: const TextStyle(
                                color: Colors.white70,
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
                          color: heldLots.isNotEmpty
                              ? AppColors.danger
                              : AppColors.emerald,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          heldLots.isNotEmpty
                              ? '${heldLots.length} ON HOLD'
                              : 'OPERATIONAL',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _stageMetricTile(
                          'ACTIVE LOTS',
                          '${activeLots.length}',
                          AppColors.gold,
                        ),
                      ),
                      Container(width: 1, height: 32, color: Colors.white12),
                      Expanded(
                        child: _stageMetricTile(
                          'TOTAL PIECES',
                          '$totalPcs',
                          const Color(0xFF00E5FF),
                        ),
                      ),
                      Container(width: 1, height: 32, color: Colors.white12),
                      Expanded(
                        child: _stageMetricTile(
                          'ON HOLD',
                          '${heldLots.length}',
                          heldLots.isNotEmpty
                              ? const Color(0xFFFFA88D)
                              : AppColors.emerald,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
              CommonText.titleMedium(
                'Active Lots on Bench (${activeLots.length})',
              ),
            const SizedBox(height: 10),
            if (activeLots.isEmpty)
              const CommonCard(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: Text(
                      'No active lots in this stage.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ),
                ),
              ),
            for (final lot in activeLots) ...[
              CommonCard(
                borderColor: lot.isOnHold
                    ? AppColors.danger.withValues(alpha: 0.55)
                    : AppColors.outline,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.ink,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  lot.id.length > 10
                                      ? 'LOT-${lot.id.substring(0, 6).toUpperCase()}'
                                      : lot.id,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  lot.designCode.isNotEmpty
                                      ? 'Design #${lot.designCode}'
                                      : ApiDomainMapper.formatOrderNumber(
                                          lot.orderId,
                                        ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
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
                            color: AppColors.emeraldLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            (lot.stage == WorkshopStage.readyForDispatch ||
                                    lot.apiStageName.toLowerCase().contains(
                                      'complete',
                                    ) ||
                                    lot.apiStageName.toUpperCase() ==
                                        'ALL_STAGES_COMPLETED')
                                ? 'Ready for Dispatch'
                                : (lot.apiStageName.isNotEmpty
                                      ? lot.apiStageName
                                      : lot.stage.label),
                            style: const TextStyle(
                              color: AppColors.emerald,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      lot.productTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 14,
                                color: AppColors.muted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  lot.assignedEmployee,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${lot.targetWeightGrams} g · ${lot.pieces} pcs',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                    if (lot.isOnHold) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ON HOLD · ${lot.blockerReason}',
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
      bottomSheet: SafeArea(
        top: false,
        child: Container(
          color: AppColors.canvas,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: CommonButton.primary(
            onPressed: () =>
                showInstructionComposer(context, store: store, target: item),
            icon: Icons.add_comment_outlined,
            label: 'Send Directive for ${item.title}',
          ),
        ),
      ),
    );
  }

  // ── 2. ORDER DETAILS SCREEN ───────────────────────────────────────────
  Widget _buildOrderDetailPage(BuildContext context) {
    final matchingOrders = store.orders.where((o) => o.id == item.id);
    if (matchingOrders.isEmpty) {
      return _missingLiveRecord('Order data is no longer available.');
    }
    final order = matchingOrders.first;
    final partIds = order.designs.map((design) => design.partId).toSet();

    final orderLots = store.lots
        .where(
          (lot) =>
              lot.orderId == order.id ||
              (order.apiId.isNotEmpty && lot.orderId == order.apiId) ||
              partIds.contains(lot.id),
        )
        .toList();
    final activeLots = orderLots;
    final isOnHold = order.isBlocked || activeLots.any((lot) => lot.isOnHold);
    final isOrderCompleted =
        order.status == OrderStatus.ready ||
        order.status == OrderStatus.delivered ||
        (activeLots.isNotEmpty &&
            activeLots.every(
              (lot) =>
                  lot.stage == WorkshopStage.readyForDispatch ||
                  lot.apiStageName.toLowerCase().contains('complete') ||
                  lot.apiStageName.toUpperCase() == 'ALL_STAGES_COMPLETED',
            ));
    final liveStages = isOrderCompleted
        ? <String>['Completed / Ready for Dispatch']
        : activeLots
              .where((lot) => lot.stage != WorkshopStage.readyForDispatch)
              .map(
                (lot) => lot.apiStageName.isNotEmpty
                    ? lot.apiStageName
                    : lot.stage.label,
              )
              .toSet()
              .toList();

    return Scaffold(
      appBar: CommonAppBar(
        title: item.title,
        showBrand: false,
        showBackButton: true,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            CommonCard(
              backgroundColor: AppColors.ink,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          ApiDomainMapper.formatOrderNumber(order.id),
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isOnHold
                              ? AppColors.danger
                              : AppColors.emerald,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isOnHold
                              ? 'ON HOLD'
                              : (isOrderCompleted
                                    ? 'COMPLETED'
                                    : order.status.label.toUpperCase()),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    order.clientFirmName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (order.responsibleManager.isNotEmpty ||
                      item.owner.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.account_circle_outlined,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Manager: ${order.responsibleManager.isNotEmpty ? order.responsibleManager : item.owner}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _stageMetricTile(
                          'GROSS WEIGHT',
                          '${order.totalGrossGrams} g',
                          AppColors.gold,
                        ),
                      ),
                      Container(width: 1, height: 32, color: Colors.white12),
                      Expanded(
                        child: _stageMetricTile(
                          'TOTAL ITEMS',
                          '${order.itemsCount} pcs',
                          const Color(0xFF00E5FF),
                        ),
                      ),
                      Container(width: 1, height: 32, color: Colors.white12),
                      Expanded(
                        child: _stageMetricTile(
                          'DUE DATE',
                          order.promiseDate,
                          const Color(0xFFFFD18A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const CommonText.titleMedium('Production Pipeline Status'),
            const SizedBox(height: 10),
            CommonCard(
              padding: const EdgeInsets.all(14),
              child: liveStages.isEmpty
                  ? const Text(
                      'No active production stage returned by the API.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    )
                  : Column(
                      children: [
                        for (
                          var index = 0;
                          index < liveStages.length;
                          index++
                        ) ...[
                          if (index > 0) const Divider(height: 16),
                          _pipelineStep(
                            step: index + 1,
                            name: liveStages[index],
                            status: isOrderCompleted
                                ? 'All production completed'
                                : 'In Workshop',
                            isDone: isOrderCompleted,
                            isCurrent: !isOrderCompleted,
                          ),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 20),
            CommonText.titleMedium(
              'Order Production Lots (${activeLots.length})',
            ),
            const SizedBox(height: 10),
            if (activeLots.isEmpty)
              const CommonCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      'No active lots returned for this order.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ),
                ),
              ),
            for (final lot in activeLots) ...[
              CommonCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.ink,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  lot.id.length > 10
                                      ? 'LOT-${lot.id.substring(0, 6).toUpperCase()}'
                                      : lot.id,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  lot.designCode.isNotEmpty
                                      ? 'Design #${lot.designCode}'
                                      : ApiDomainMapper.formatOrderNumber(
                                          lot.orderId,
                                        ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
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
                            color: AppColors.emeraldLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            lot.stage.label,
                            style: const TextStyle(
                              color: AppColors.emerald,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      lot.productTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 14,
                                color: AppColors.muted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  lot.assignedEmployee,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${lot.targetWeightGrams} g · ${lot.pieces} pcs',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomSheet: SafeArea(
        top: false,
        child: Container(
          color: AppColors.canvas,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: CommonButton.primary(
            onPressed: () =>
                showInstructionComposer(context, store: store, target: item),
            icon: Icons.add_comment_outlined,
            label: 'Send Directive for ${item.title}',
          ),
        ),
      ),
    );
  }

  // ── 3. PEOPLE (ARTISAN) DETAILS SCREEN ───────────────────────────────
  Widget _buildPeopleDetailPage(BuildContext context) {
    final matchingTeam = store.team.where((t) => t.id == item.id);
    if (matchingTeam.isEmpty) {
      return _missingLiveRecord('Employee data is no longer available.');
    }
    final member = matchingTeam.first;

    final artisanLots = store.lots
        .where(
          (l) =>
              l.assignedEmployee.trim().toLowerCase() ==
              member.name.trim().toLowerCase(),
        )
        .toList();
    final activeLots = artisanLots;

    return Scaffold(
      appBar: CommonAppBar(
        title: item.title,
        showBrand: false,
        showBackButton: true,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            CommonCard(
              backgroundColor: AppColors.ink,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.emerald.withValues(
                          alpha: 0.2,
                        ),
                        child: Text(
                          member.name.isNotEmpty
                              ? member.name.substring(0, 1).toUpperCase()
                              : 'A',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              [
                                member.craft,
                                if (member.shift.isNotEmpty)
                                  'Shift: ${member.shift}',
                              ].join(' · '),
                              style: const TextStyle(
                                color: Colors.white70,
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
                          color:
                              (member.status == EmployeeStatus.working ||
                                  member.status == EmployeeStatus.available)
                              ? AppColors.emerald
                              : AppColors.warning,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          member.status.label.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _stageMetricTile(
                          'ACTIVE LOTS',
                          '${activeLots.length} lots',
                          AppColors.emerald,
                        ),
                      ),
                      Container(width: 1, height: 32, color: Colors.white12),
                      Expanded(
                        child: _stageMetricTile(
                          'CRAFT ROLE',
                          member.craft.split(' ').first,
                          const Color(0xFF00E5FF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            CommonText.titleMedium(
              'Assigned Active Lots (${activeLots.length})',
            ),
            const SizedBox(height: 10),
            if (activeLots.isEmpty)
              const CommonCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      'No active lots assigned to this employee.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ),
                ),
              ),
            for (final lot in activeLots) ...[
              CommonCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.ink,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  lot.id.length > 10
                                      ? 'LOT-${lot.id.substring(0, 6).toUpperCase()}'
                                      : lot.id,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  lot.designCode.isNotEmpty
                                      ? 'Design #${lot.designCode}'
                                      : ApiDomainMapper.formatOrderNumber(
                                          lot.orderId,
                                        ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
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
                            color: AppColors.emeraldLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            (lot.stage == WorkshopStage.readyForDispatch ||
                                    lot.apiStageName.toLowerCase().contains(
                                      'complete',
                                    ) ||
                                    lot.apiStageName.toUpperCase() ==
                                        'ALL_STAGES_COMPLETED')
                                ? 'Ready for Dispatch'
                                : (lot.apiStageName.isNotEmpty
                                      ? lot.apiStageName
                                      : lot.stage.label),
                            style: const TextStyle(
                              color: AppColors.emerald,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      lot.productTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current Bench Assignment',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                        Text(
                          '${lot.targetWeightGrams} g · ${lot.pieces} pcs',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
      bottomSheet: SafeArea(
        top: false,
        child: Container(
          color: AppColors.canvas,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: CommonButton.primary(
            onPressed: () =>
                showInstructionComposer(context, store: store, target: item),
            icon: Icons.add_comment_outlined,
            label: 'Send Directive to ${member.name}',
          ),
        ),
      ),
    );
  }

  Widget _stageMetricTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _missingLiveRecord(String message) => Scaffold(
    appBar: CommonAppBar(
      title: item.title,
      showBrand: false,
      showBackButton: true,
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted),
        ),
      ),
    ),
  );

  Widget _pipelineStep({
    required int step,
    required String name,
    required String status,
    required bool isDone,
    required bool isCurrent,
  }) {
    final color = isDone
        ? AppColors.emerald
        : (isCurrent ? AppColors.gold : AppColors.muted);
    return Row(
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: color.withValues(alpha: 0.2),
          child: isDone
              ? Icon(Icons.check, size: 14, color: color)
              : Text(
                  '$step',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
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
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                  color: isCurrent
                      ? AppColors.ink
                      : AppColors.ink.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                status,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

(String, Color, IconData) statusTone(HealthTone tone) => switch (tone) {
  HealthTone.healthy => (
    'Healthy',
    AppColors.success,
    Icons.check_circle_outline,
  ),
  HealthTone.warning => ('Needs Review', AppColors.warning, Icons.schedule),
  HealthTone.critical => (
    'Critical Hold',
    AppColors.danger,
    Icons.error_outline,
  ),
};

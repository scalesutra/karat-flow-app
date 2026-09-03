import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/common_3d_viewer.dart';
import '../../../../core/widgets/common_button.dart';
import '../../../../core/widgets/common_card.dart';
import '../../../../core/widgets/common_progress_indicator.dart';
import '../../../../core/widgets/common_snackbar.dart';
import '../../../../core/widgets/common_text_field.dart';
import '../../../../core/widgets/animated_empty_state_widget.dart';
import '../../../../data/demo_store.dart';
import '../../../../domain/models.dart';
import '../bloc/admin_bloc.dart';
import '../../cad_designer/bloc/cad_bloc.dart';

/// Modal bottom sheet for Admin Review of 3D CAD Models & Stock Management
class AdminReviewCadSheet extends StatelessWidget {
  const AdminReviewCadSheet({
    super.key,
    required this.store,
    required this.onSendDirective,
  });

  final DemoStore store;
  final void Function(String contextRef) onSendDirective;

  void _approveTask(BuildContext context, CadDesignTask task) {
    context.read<CadBloc>().add(ApproveCadTaskEvent(task.id));
  }

  static void show(
    BuildContext context, {
    required DemoStore store,
    required void Function(String contextRef) onSendDirective,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.90,
        child: AdminReviewCadSheet(
          store: store,
          onSendDirective: onSendDirective,
        ),
      ),
    );
  }

  void _openDirectCadBriefModal(BuildContext context) {
    CommonSnackbar.error(
      context,
      title: 'CAD Brief API Unavailable',
      message: 'The backend does not expose a direct CAD brief endpoint.',
    );
  }

  void _openUpdateStockModal(BuildContext context, CadDesignTask task) {
    final titleController = TextEditingController(text: task.productTitle);
    final stockController = TextEditingController(text: '1');
    final initialPrice = (task.calculatedPrice != null && task.calculatedPrice! > 0)
        ? '${task.calculatedPrice!.toInt()}'
        : ((task.priceBreakdown?.finalPrice != null && task.priceBreakdown!.finalPrice > 0)
            ? '${task.priceBreakdown!.finalPrice.toInt()}'
            : '');
    final priceController = TextEditingController(text: initialPrice);
    final goldQtyController = TextEditingController(
      text: '${task.goldQuantity}',
    );
    final totalWeightController = TextEditingController(
      text: '${task.estimatedWeightGrams}',
    );
    String selectedStatus = 'In Stock';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(dialogCtx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
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
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, color: AppColors.goldDark),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Edit Product Stock: ${task.designCode}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Purity: ${task.sizeDimensions.isNotEmpty ? task.sizeDimensions : 'Gold'} · Making Code: ${task.makingCode.isNotEmpty ? task.makingCode : 'N/A'}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  CommonTextField(
                    controller: titleController,
                    label: 'Product Title',
                    hintText: 'Enter product title',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CommonTextField(
                          controller: stockController,
                          label: 'Stock Quantity',
                          hintText: 'Enter quantity',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CommonTextField(
                          controller: priceController,
                          label: 'Final Price (₹)',
                          hintText: 'Enter price in ₹',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CommonTextField(
                          controller: goldQtyController,
                          label: 'Net Gold (g)',
                          hintText: 'Enter net gold in grams',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CommonTextField(
                          controller: totalWeightController,
                          label: 'Gross Weight (g)',
                          hintText: 'Enter gross weight in grams',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Stock Status',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    items: const [
                      DropdownMenuItem(value: 'In Stock', child: Text('In Stock')),
                      DropdownMenuItem(value: 'Low Stock', child: Text('Low Stock')),
                      DropdownMenuItem(value: 'Out of Stock', child: Text('Out of Stock')),
                      DropdownMenuItem(value: 'Custom Made', child: Text('Custom Made')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedStatus = val);
                      }
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: CommonButton.primary(
                      label: 'Save & Update Stock',
                      icon: Icons.check,
                      onPressed: () {
                        final parsedStock = int.tryParse(stockController.text.trim());
                        final parsedPrice = double.tryParse(priceController.text.trim());
                        final parsedGold = double.tryParse(goldQtyController.text.trim());
                        final parsedTotalWeight = double.tryParse(totalWeightController.text.trim());

                        context.read<AdminBloc>().add(
                          UpdateProductStockEvent(
                            designId: task.id,
                            title: titleController.text.trim(),
                            stock: parsedStock,
                            stockStatus: selectedStatus,
                            price: parsedPrice,
                            goldQuantity: parsedGold,
                            totalWeight: parsedTotalWeight,
                          ),
                        );

                        Navigator.pop(ctx);
                        CommonSnackbar.success(
                          context,
                          title: 'Stock Updated Successfully',
                          message: 'Updated stock and pricing for ${task.designCode}.',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final pendingTasks = store.cadTasks
            .where((task) => task.hasStlFile)
            .toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Review 3D CAD Models & Stock',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: AppColors.ink,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Inspect CAD design specs, gem breakdown & update stock',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.muted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: BlocBuilder<CadBloc, CadState>(
                  builder: (context, cadState) {
                    if (cadState is CadLoading) {
                      return const Center(
                        child: CommonProgressIndicator.admin(
                          label: 'Syncing Admin 3D CAD Models...',
                        ),
                      );
                    }
                    return CommonRefreshIndicator(
                      theme: IndicatorTheme.cad,
                      onRefresh: () async => context.read<CadBloc>().add(
                        const FetchCadTasksEvent(),
                      ),
                      child: pendingTasks.isEmpty
                          ? ListView(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 70,
                                    bottom: 40,
                                  ),
                                  child: AnimatedEmptyStateWidget(
                                    icon: Icons.view_in_ar_rounded,
                                    title: 'No CAD Approvals Pending',
                                    subtitle:
                                        'All 3D CAD models and specs have been reviewed and signed off for production!',
                                    accentColor: AppColors.goldDark,
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: pendingTasks.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (ctx, index) {
                          final task = pendingTasks[index];
                          final isApproved =
                              task.status == CadTaskStatus.completed ||
                              task.specs.contains('(Approved)');
                          final pb = task.priceBreakdown;
                          final calculatedPriceVal = (task.calculatedPrice != null && task.calculatedPrice! > 0)
                              ? task.calculatedPrice
                              : (pb?.finalPrice != null && pb!.finalPrice > 0 ? pb.finalPrice : null);

                          return CommonCard(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header: Title & Status Badge
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        task.productTitle,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isApproved
                                            ? AppColors.emeraldLight
                                            : AppColors.goldLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isApproved
                                                ? Icons.check_circle
                                                : Icons.view_in_ar,
                                            size: 11,
                                            color: isApproved
                                                ? AppColors.emeraldDark
                                                : AppColors.goldDark,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isApproved
                                                ? 'APPROVED'
                                                : 'PENDING SIGN-OFF',
                                            style: TextStyle(
                                              color: isApproved
                                                  ? AppColors.emeraldDark
                                                  : AppColors.goldDark,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Code: ${task.designCode} · Designer: ${task.assignedTo}',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // 1. Metal & Gem Specifications Card
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F8FA),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.fitness_center, size: 14, color: AppColors.goldDark),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Metal: ${task.sizeDimensions.isNotEmpty ? task.sizeDimensions : 'Gold'} · Weight: ${task.goldQuantity}g (Gross: ${task.estimatedWeightGrams}g)',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.ink,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (task.makingCode.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          'Making Code: ${task.makingCode}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.muted),
                                        ),
                                      ],
                                      const Divider(height: 12),
                                      Row(
                                        children: [
                                          const Icon(Icons.diamond_outlined, size: 14, color: Colors.blueAccent),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Gems: ${task.gemQuantity} Pcs · Total Gem Weight: ${task.gemWeightTw} Tw',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.ink,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // 2. Expandable Gem Breakdown Table
                                if (task.gemBreakdown.isNotEmpty)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.outline),
                                    ),
                                    child: Theme(
                                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                      child: ExpansionTile(
                                        dense: true,
                                        tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                        title: Text(
                                          '💎 Detailed Gem Breakdown (${task.gemBreakdown.length} Shapes)',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                                            child: Table(
                                              columnWidths: const {
                                                0: FlexColumnWidth(2),
                                                1: FlexColumnWidth(2),
                                                2: FlexColumnWidth(1.5),
                                                3: FlexColumnWidth(2),
                                              },
                                              border: TableBorder.all(
                                                color: AppColors.outline.withValues(alpha: 0.4),
                                                width: 0.8,
                                              ),
                                              children: [
                                                const TableRow(
                                                  decoration: BoxDecoration(color: Color(0xFFF2F4F7)),
                                                  children: [
                                                    Padding(padding: EdgeInsets.all(4), child: Text('Shape', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                                                    Padding(padding: EdgeInsets.all(4), child: Text('Dim (mm)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                                                    Padding(padding: EdgeInsets.all(4), child: Text('Count', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                                                    Padding(padding: EdgeInsets.all(4), child: Text('Weight (Tw)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                                                  ],
                                                ),
                                                ...task.gemBreakdown.map((gb) {
                                                  return TableRow(
                                                    children: [
                                                      Padding(padding: const EdgeInsets.all(4), child: Text(gb.shape, style: const TextStyle(fontSize: 10))),
                                                      Padding(padding: const EdgeInsets.all(4), child: Text(gb.dimensions, style: const TextStyle(fontSize: 10))),
                                                      Padding(padding: const EdgeInsets.all(4), child: Text('${gb.count}', style: const TextStyle(fontSize: 10))),
                                                      Padding(padding: const EdgeInsets.all(4), child: Text('${gb.weightTw}', style: const TextStyle(fontSize: 10))),
                                                    ],
                                                  );
                                                }),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 8),

                                // 3. Calculated Price & Price Breakdown Card
                                if (calculatedPriceVal != null || pb != null)
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF9EE),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFFFD18A)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Total Calculated Price:',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.ink,
                                              ),
                                            ),
                                            Text(
                                              '₹${(calculatedPriceVal ?? 0).toInt()}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.goldDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (pb != null) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            '• Gold Cost (${pb.netGoldWeight}g @ ₹${pb.goldRatePerGram.toInt()}/g): ₹${pb.totalGoldCost.toInt()}',
                                            style: const TextStyle(fontSize: 11, color: AppColors.muted),
                                          ),
                                          Text(
                                            '• Gem Cost (${pb.gemQuantity} pcs @ ₹${pb.gemRate.toInt()}/ct): ₹${pb.totalGemCost.toInt()}',
                                            style: const TextStyle(fontSize: 11, color: AppColors.muted),
                                          ),
                                          Text(
                                            '• Subtotal: ₹${pb.subtotal.toInt()} + GST (${pb.gstPercent}%): ₹${pb.gstAmount.toInt()}',
                                            style: const TextStyle(fontSize: 11, color: AppColors.muted),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                                               // 4. Action Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: CommonButton.outlined(
                                        height: 34,
                                        icon: Icons.view_in_ar,
                                        label: 'View 3D',
                                        onPressed: () {
                                          showModalBottomSheet<void>(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (viewCtx) =>
                                                Common3DViewer(
                                                  designCode: task.designCode,
                                                  productTitle:
                                                      task.productTitle,
                                                  modelUrl: task.modelFileUrl,
                                                ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    if (!isApproved)
                                      Expanded(
                                        child: CommonButton.primary(
                                          height: 34,
                                          backgroundColor: AppColors.emerald,
                                          icon: Icons.check_circle_outline,
                                          label: 'Approve 3D',
                                          onPressed: () =>
                                              _approveTask(context, task),
                                        ),
                                      )
                                    else
                                      Expanded(
                                        child: CommonButton.primary(
                                          height: 34,
                                          backgroundColor: AppColors.goldDark,
                                          icon: Icons.edit_note_outlined,
                                          label: 'Edit Product Stock',
                                          onPressed: () => _openUpdateStockModal(context, task),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: CommonButton.primary(
                  onPressed: () => _openDirectCadBriefModal(context),
                  label: '+ Direct CAD Brief / New Task',
                  icon: Icons.add_box_outlined,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Bottom sheet to create a direct CAD Design Task

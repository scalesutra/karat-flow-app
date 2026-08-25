import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/common_button.dart';
import '../../core/widgets/common_snackbar.dart';
import '../../data/demo_store.dart';
import '../../domain/models.dart';
import '../admin/bloc/admin_bloc.dart';

Future<Instruction?> showInstructionComposer(
  BuildContext context, {
  required DemoStore store,
  WorkItem? target,
}) async {
  return showModalBottomSheet<Instruction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: _InstructionComposerSheet(
        store: store,
        target: target,
      ),
    ),
  );
}

class _InstructionComposerSheet extends StatefulWidget {
  const _InstructionComposerSheet({
    required this.store,
    this.target,
  });

  final DemoStore store;
  final WorkItem? target;

  @override
  State<_InstructionComposerSheet> createState() =>
      __InstructionComposerSheetState();
}

class __InstructionComposerSheetState
    extends State<_InstructionComposerSheet> {
  late final TextEditingController _textController;
  String _selectedRecipient = 'CAD Designer';

  final List<String> _recipients = const [
    'CAD Designer',
    'Goldsmith (Artisans)',
    'QC Team',
    'Vault / Store Keeper',
    'Sales & Orders',
  ];

  final List<String> _quickTags = const [
    '⚡ Priority Processing',
    '🔍 BIS Hallmarking Audit',
    '⚖️ Metal Scrap Balance Check',
    '📞 Client Revision Request',
  ];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _sendDirective() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      CommonSnackbar.error(
        context,
        title: 'Empty Directive',
        message: 'Please enter instructions for the recipient team.',
      );
      return;
    }

    final targetInfo = widget.target != null
        ? '[ ${widget.target!.title} ] '
        : '';
    final fullMessage = '$targetInfo$text';

    // 1. Save to DemoStore for real-time local sync across role dashboards
    widget.store.addAdminDirective(_selectedRecipient, fullMessage);

    // 2. Also dispatch BLoC event if AdminBloc is present in context
    try {
      context.read<AdminBloc>().add(
            SendDirectiveEvent(
              recipient: _selectedRecipient,
              directive: fullMessage,
            ),
          );
    } catch (_) {
      // Safe fallback if invoked outside AdminBloc tree
    }

    CommonSnackbar.success(
      context,
      title: 'Directive Dispatched',
      message: 'Successfully sent to $_selectedRecipient',
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final targetLabel = widget.target?.title ?? 'General Workshop Directive';

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'New Admin Directive',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Target: $targetLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.emeraldDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
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
            const SizedBox(height: 16),
            const Text(
              'Recipient Team',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _recipients.map((r) {
                  final isSelected = _selectedRecipient == r;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        r,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.ink,
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.emerald,
                      backgroundColor: AppColors.canvas,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedRecipient = r);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Quick Directive Tags',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _quickTags.map((tag) {
                return InkWell(
                  onTap: () {
                    final current = _textController.text;
                    if (current.isEmpty) {
                      _textController.text = tag;
                    } else {
                      _textController.text = '$current · $tag';
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Directive Instructions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _textController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Enter specific production, quality, or CAD directives...',
                hintStyle: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                ),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            CommonButton.primary(
              label: 'Dispatch Directive',
              icon: Icons.send_rounded,
              onPressed: _sendDirective,
            ),
          ],
        ),
      ),
    );
  }
}

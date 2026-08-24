import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/widgets.dart';
import '../../data/demo_store.dart';
import '../../domain/models.dart';

Future<Instruction?> showInstructionComposer(
  BuildContext context, {
  required DemoStore store,
  WorkItem? target,
}) {
  final fallbackTarget =
      target ??
      store.workItemsFor(StatusPivot.orders).firstOrNull ??
      store.workItemsFor(StatusPivot.stages).first;

  return Navigator.of(context).push<Instruction>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) =>
          InstructionComposerPage(store: store, initialTarget: fallbackTarget),
    ),
  );
}

class InstructionComposerPage extends StatefulWidget {
  const InstructionComposerPage({
    super.key,
    required this.store,
    required this.initialTarget,
  });

  final DemoStore store;
  final WorkItem initialTarget;

  @override
  State<InstructionComposerPage> createState() =>
      _InstructionComposerPageState();
}

class _InstructionComposerPageState extends State<InstructionComposerPage> {
  late WorkItem _currentTarget;
  final _message = TextEditingController();
  InstructionUrgency _urgency = InstructionUrgency.today;
  String _assignedManager = 'Arjun · Process Manager';
  bool _hasPhoto = false;
  bool _hasVoice = false;
  Instruction? _sent;

  final List<String> _quickDirectives = const [
    'Confirm stone replacement before 4 PM',
    'Hold lot for CAD design recheck',
    'Expedite final polish for delivery',
    'Re-verify net gold weight on balance',
    'Check prong alignment under microscope',
  ];

  final List<_ManagerOption> _managerList = const [
    _ManagerOption(
      name: 'Arjun',
      role: 'Process Manager (Setting/Casting)',
      initial: 'A',
      fullName: 'Arjun · Process Manager',
    ),
    _ManagerOption(
      name: 'Neha',
      role: 'Process Manager (Polish/QC)',
      initial: 'N',
      fullName: 'Neha · Process Manager',
    ),
    _ManagerOption(
      name: 'Prakash',
      role: 'QC Inspector & Hallmarking',
      initial: 'P',
      fullName: 'Prakash · QC Incharge',
    ),
    _ManagerOption(
      name: 'Dilip',
      role: 'Floor & Pouch Supervisor',
      initial: 'D',
      fullName: 'Dilip · Floor Supervisor',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentTarget = widget.initialTarget;
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_sent != null) return _SuccessView(instruction: _sent!);

    final (toneLabel, toneColor, toneIcon) = _toneInfo(_currentTarget.tone);

    return Scaffold(
      appBar: CommonAppBar(
        title: 'New Instruction & Directive',
        showBrand: false,
        leading: IconButton(
          tooltip: 'Close instruction',
          onPressed: () => Get.back(),
          icon: const Icon(Icons.close),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
          children: [
            // STEP 1: TARGET SELECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _StepLabel(number: '1', label: 'Target Item / Order'),
                TextButton.icon(
                  onPressed: () => _openTargetPicker(context),
                  icon: const Icon(
                    Icons.swap_horiz,
                    size: 18,
                    color: AppColors.emerald,
                  ),
                  label: const Text(
                    'Change Target',
                    style: TextStyle(
                      color: AppColors.emerald,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            CommonCard(
              backgroundColor: AppColors.sage.withValues(alpha: 0.5),
              borderColor: AppColors.sage,
              onTap: () => _openTargetPicker(context),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: toneColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMedium,
                      ),
                    ),
                    child: Icon(toneIcon, color: toneColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.ink,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _currentTarget.id,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: toneColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                toneLabel,
                                style: TextStyle(
                                  color: toneColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentTarget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${_currentTarget.subtitle} · ${_currentTarget.status}',
                          maxLines: 1,
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
                  const Icon(Icons.arrow_drop_down, color: AppColors.muted),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // STEP 2: MESSAGE & MEDIA DIRECTIVE
            const _StepLabel(number: '2', label: 'Message & Instructions'),
            const SizedBox(height: 6),
            CommonTextField(
              controller: _message,
              onChanged: (_) => setState(() {}),
              minLines: 3,
              maxLines: 5,
              hintText: 'What should the workshop team or manager execute?',
            ),
            const SizedBox(height: 10),

            // Quick Directives
            const CommonText.bodySmall(
              'Quick Suggestions:',
              color: AppColors.muted,
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickDirectives.map((directive) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      backgroundColor: AppColors.paper,
                      side: const BorderSide(color: AppColors.outline),
                      label: Text(
                        directive,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.ink,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _message.text = directive;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // Media Attachment Buttons
            Row(
              children: [
                Expanded(
                  child: _MediaAttachmentButton(
                    selected: _hasVoice,
                    icon: Icons.mic,
                    activeLabel: 'Voice Note Attached (0:18)',
                    inactiveLabel: 'Record Voice Directive',
                    onPressed: () => setState(() => _hasVoice = !_hasVoice),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MediaAttachmentButton(
                    selected: _hasPhoto,
                    icon: Icons.camera_alt,
                    activeLabel: 'Photo Attached',
                    inactiveLabel: 'Attach Defect Photo',
                    onPressed: () => setState(() => _hasPhoto = !_hasPhoto),
                  ),
                ),
              ],
            ),

            if (_hasVoice || _hasPhoto) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.emeraldLight,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.emerald,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _hasVoice && _hasPhoto
                            ? 'Voice directive and pouch photo queued.'
                            : (_hasVoice
                                  ? 'Audio directive attached (0:18s).'
                                  : 'Workshop photo attached.'),
                        style: const TextStyle(
                          color: AppColors.emeraldDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // STEP 3: PROMINENT PRIORITY & URGENCY BUTTONS
            const _StepLabel(number: '3', label: 'Select Urgency & Priority'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _PriorityButton(
                    urgency: InstructionUrgency.routine,
                    label: 'Routine',
                    sublabel: 'Standard flow',
                    icon: Icons.schedule,
                    isSelected: _urgency == InstructionUrgency.routine,
                    color: AppColors.emerald,
                    bgColor: AppColors.emeraldLight,
                    onTap: () =>
                        setState(() => _urgency = InstructionUrgency.routine),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PriorityButton(
                    urgency: InstructionUrgency.today,
                    label: 'Today',
                    sublabel: 'Due by shift end',
                    icon: Icons.today,
                    isSelected: _urgency == InstructionUrgency.today,
                    color: AppColors.warning,
                    bgColor: AppColors.warningLight,
                    onTap: () =>
                        setState(() => _urgency = InstructionUrgency.today),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PriorityButton(
                    urgency: InstructionUrgency.urgent,
                    label: 'Urgent',
                    sublabel: 'Hold line now',
                    icon: Icons.error_outline,
                    isSelected: _urgency == InstructionUrgency.urgent,
                    color: AppColors.danger,
                    bgColor: AppColors.dangerLight,
                    onTap: () =>
                        setState(() => _urgency = InstructionUrgency.urgent),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // STEP 4: ASSIGNEE SELECTION
            const _StepLabel(
              number: '4',
              label: 'Assign To Workshop Supervisor',
            ),
            const SizedBox(height: 8),
            for (final mgr in _managerList)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AssigneeCard(
                  manager: mgr,
                  isSelected: _assignedManager == mgr.fullName,
                  onTap: () => setState(() => _assignedManager = mgr.fullName),
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
          child: SizedBox(
            width: double.infinity,
            child: CommonButton.primary(
              onPressed: _canSend ? _send : null,
              icon: Icons.send_outlined,
              label: 'Dispatch Instruction to Workshop',
            ),
          ),
        ),
      ),
    );
  }

  bool get _canSend => _message.text.trim().isNotEmpty || _hasVoice;

  void _send() {
    final instruction = widget.store.addInstruction(
      target: _currentTarget,
      message: _message.text,
      urgency: _urgency,
      hasPhoto: _hasPhoto,
      hasVoice: _hasVoice,
    );
    setState(() => _sent = instruction);
  }

  void _openTargetPicker(BuildContext context) {
    final allWorkItems = [
      ...widget.store.workItemsFor(StatusPivot.orders),
      ...widget.store.workItemsFor(StatusPivot.people),
      ...widget.store.workItemsFor(StatusPivot.stages),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
            const CommonText.headlineMedium('Select Instruction Target'),
            const SizedBox(height: 4),
            const CommonText.bodySmall(
              'Assign directive to an Order, Employee, or Stage',
              color: AppColors.muted,
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: allWorkItems.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (c, idx) {
                  final item = allWorkItems[idx];
                  final isSelected = item.id == _currentTarget.id;
                  final (toneL, toneC, _) = _toneInfo(item.tone);

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.id,
                        style: const TextStyle(
                          color: AppColors.emerald,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      '${item.subtitle} · ${item.status}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppColors.emerald)
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: toneC.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              toneL,
                              style: TextStyle(
                                color: toneC,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                    onTap: () {
                      setState(() => _currentTarget = item);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, Color, IconData) _toneInfo(HealthTone tone) => switch (tone) {
    HealthTone.critical => (
      'Critical Hold',
      AppColors.danger,
      Icons.error_outline,
    ),
    HealthTone.warning => ('Needs Review', AppColors.warning, Icons.schedule),
    HealthTone.healthy => (
      'Normal Flow',
      AppColors.emerald,
      Icons.check_circle_outline,
    ),
  };
}

class _ManagerOption {
  const _ManagerOption({
    required this.name,
    required this.role,
    required this.initial,
    required this.fullName,
  });

  final String name;
  final String role;
  final String initial;
  final String fullName;
}

class _AssigneeCard extends StatelessWidget {
  const _AssigneeCard({
    required this.manager,
    required this.isSelected,
    required this.onTap,
  });

  final _ManagerOption manager;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.emeraldLight : AppColors.paper,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(
            color: isSelected ? AppColors.emerald : AppColors.outline,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.emerald.withValues(alpha: 0.22),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isSelected ? AppColors.emerald : AppColors.sage,
              child: Text(
                manager.initial,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.emeraldDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    manager.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: isSelected ? AppColors.emeraldDark : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    manager.role,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.emeraldDark.withValues(alpha: 0.8)
                          : AppColors.muted,
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.emerald,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              )
            else
              const Icon(
                Icons.radio_button_unchecked,
                color: AppColors.outline,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _PriorityButton extends StatelessWidget {
  const _PriorityButton({
    required this.urgency,
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  final InstructionUrgency urgency;
  final String label;
  final String sublabel;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : AppColors.paper,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(
            color: isSelected ? color : AppColors.outline,
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 10,
                    spreadRadius: 1.5,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? color : AppColors.muted,
                  size: 24,
                ),
                if (isSelected)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: isSelected ? color : AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? color : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(
        radius: 12,
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        child: Text(
          number,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ),
      const SizedBox(width: 8),
      CommonText.titleMedium(label),
    ],
  );
}

class _MediaAttachmentButton extends StatelessWidget {
  const _MediaAttachmentButton({
    required this.selected,
    required this.icon,
    required this.activeLabel,
    required this.inactiveLabel,
    required this.onPressed,
  });

  final bool selected;
  final IconData icon;
  final String activeLabel;
  final String inactiveLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.emeraldLight : AppColors.paper,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(
            color: selected ? AppColors.emerald : AppColors.outline,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? Icons.check_circle : icon,
              size: 18,
              color: selected ? AppColors.emerald : AppColors.muted,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                selected ? activeLabel : inactiveLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? AppColors.emerald : AppColors.ink,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.instruction});

  final Instruction instruction;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.emeraldLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.emerald,
                size: 52,
              ),
            ),
            const SizedBox(height: 20),
            const CommonText.headlineLarge(
              'Instruction Dispatched',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            CommonText.bodyLarge(
              '${instruction.id} has been transmitted to ${instruction.assignedTo}. Acknowledgement and workshop progress will appear in Tasks.',
              textAlign: TextAlign.center,
              color: AppColors.muted,
            ),
            const Spacer(),
            CommonButton.primary(
              onPressed: () => Navigator.pop(context, instruction),
              label: 'Done',
            ),
          ],
        ),
      ),
    ),
  );
}

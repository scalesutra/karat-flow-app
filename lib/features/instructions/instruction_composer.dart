import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/common_button.dart';
import '../../core/widgets/common_snackbar.dart';
import '../../data/demo_store.dart';
import '../../domain/directive_recipients.dart';
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _InstructionComposerSheet(store: store, target: target),
    ),
  );
}

class _InstructionComposerSheet extends StatefulWidget {
  const _InstructionComposerSheet({required this.store, this.target});

  final DemoStore store;
  final WorkItem? target;

  @override
  State<_InstructionComposerSheet> createState() =>
      __InstructionComposerSheetState();
}

class __InstructionComposerSheetState extends State<_InstructionComposerSheet> {
  late final TextEditingController _textController;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final ImagePicker _imagePicker = ImagePicker();
  StreamSubscription<void>? _playerCompleteSubscription;

  String _selectedRecipient = DirectiveRecipients.allTeams;
  Timer? _timer;
  String? _recordingPath;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  Duration _elapsed = Duration.zero;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isSubmitting = false;

  final List<String> _recipients = DirectiveRecipients.options;

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
    _playerCompleteSubscription = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
    _recoverLostImage();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _playerCompleteSubscription?.cancel();
    _textController.dispose();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
      return;
    }

    if (!await _recorder.hasPermission()) {
      if (!mounted) return;
      CommonSnackbar.error(
        context,
        title: 'Microphone Permission Required',
        message: 'Please allow microphone access to record a voice directive.',
      );
      return;
    }

    await _player.stop();
    final directory = await getTemporaryDirectory();
    final filePath =
        '${directory.path}${Platform.pathSeparator}directive_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: filePath,
    );

    if (!mounted) return;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });

    setState(() {
      _recordingPath = null;
      _elapsed = Duration.zero;
      _isRecording = true;
      _isPlaying = false;
    });
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    _timer?.cancel();
    if (!mounted) return;
    setState(() {
      _recordingPath = path;
      _isRecording = false;
    });
  }

  Future<void> _togglePreview() async {
    final path = _recordingPath;
    if (path == null) return;
    try {
      if (_isPlaying) {
        await _player.pause();
        if (mounted) setState(() => _isPlaying = false);
        return;
      }
      await _player.stop();
      await _player.play(DeviceFileSource(path));
      if (mounted) setState(() => _isPlaying = true);
    } catch (_) {
      if (mounted) {
        CommonSnackbar.error(
          context,
          title: 'Playback Error',
          message: 'Could not play voice preview.',
        );
      }
    }
  }

  Future<void> _sendDirective() async {
    if (_isRecording) await _stopRecording();
    if (!mounted) return;
    final text = _textController.text.trim();
    final path = _recordingPath;

    if (text.isEmpty && path == null && _selectedImageBytes == null) {
      CommonSnackbar.error(
        context,
        title: 'Empty Directive',
        message: 'Enter instructions, record voice, or attach an image.',
      );
      return;
    }

    final navigator = Navigator.of(context);
    final bloc = context.read<AdminBloc>();

    if (_isPlaying) {
      await _player.stop();
      if (mounted) setState(() => _isPlaying = false);
    }

    setState(() => _isSubmitting = true);
    final Uint8List? bytes = path == null
        ? null
        : await File(path).readAsBytes();

    final targetInfo = widget.target != null
        ? '[ ${widget.target!.title} ] '
        : '';
    final messageBody = text.isNotEmpty
        ? text
        : path != null
        ? 'Voice Directive Note Attached'
        : 'Image Directive Note Attached';
    final fullMessage = '$targetInfo$messageBody';

    try {
      bloc.add(
        SendDirectiveEvent(
          recipient: _selectedRecipient,
          directive: fullMessage,
          audioFileName: path?.split(Platform.pathSeparator).last,
          audioBytes: bytes,
          imageFileName: _selectedImage?.name,
          imageBytes: _selectedImageBytes,
        ),
      );
    } catch (_) {}

    if (mounted) {
      CommonSnackbar.success(
        context,
        title: 'Directive Dispatched',
        message: 'Successfully sent to $_selectedRecipient',
      );
    }

    navigator.pop();
  }

  Future<void> _recoverLostImage() async {
    try {
      final response = await _imagePicker.retrieveLostData();
      final file = response.files?.firstOrNull;
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedImage = file;
        _selectedImageBytes = bytes;
      });
    } catch (error) {
      debugPrint('Could not recover interrupted image selection: $error');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1800,
        requestFullMetadata: false,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedImage = file;
        _selectedImageBytes = bytes;
      });
    } catch (error) {
      if (!mounted) return;
      CommonSnackbar.error(
        context,
        title: 'Image unavailable',
        message: 'Could not attach the selected image: $error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetLabel = widget.target?.title ?? 'General Workshop Directive';
    final seconds = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final minutes = _elapsed.inMinutes.toString().padLeft(2, '0');

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
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
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
              'Directive Instructions (Optional if voice recorded)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _textController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'Enter instructions or record voice directive below...',
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
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            if (_selectedImageBytes != null) ...[
              const SizedBox(height: 8),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      _selectedImageBytes!,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton.filled(
                      tooltip: 'Remove image',
                      onPressed: () => setState(() {
                        _selectedImage = null;
                        _selectedImageBytes = null;
                      }),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isRecording ? AppColors.dangerLight : AppColors.canvas,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isRecording ? AppColors.danger : AppColors.outline,
                ),
              ),
              child: Row(
                children: [
                  IconButton.filled(
                    onPressed: _isSubmitting ? null : _toggleRecording,
                    style: IconButton.styleFrom(
                      backgroundColor: _isRecording
                          ? AppColors.danger
                          : AppColors.emerald,
                    ),
                    icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isRecording
                              ? 'Recording $minutes:$seconds'
                              : _recordingPath == null
                              ? 'Tap Mic to record voice'
                              : 'Voice note ready · $minutes:$seconds',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: _isRecording
                                ? AppColors.danger
                                : AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _recordingPath != null && !_isRecording
                              ? 'Tap ▶️ on right to preview before sending'
                              : 'High quality M4A voice directive',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_recordingPath != null && !_isRecording)
                    IconButton.filled(
                      tooltip: _isPlaying ? 'Pause preview' : 'Play preview',
                      onPressed: _togglePreview,
                      style: IconButton.styleFrom(
                        backgroundColor: _isPlaying
                            ? AppColors.warning
                            : AppColors.emeraldLight,
                      ),
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: _isPlaying
                            ? AppColors.pureWhite
                            : AppColors.emerald,
                        size: 24,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            CommonButton.primary(
              label: _isSubmitting ? 'Dispatching...' : 'Dispatch Directive',
              icon: Icons.send_rounded,
              onPressed: _isSubmitting ? null : _sendDirective,
            ),
          ],
        ),
      ),
    );
  }
}

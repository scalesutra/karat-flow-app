import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/common_button.dart';
import '../../../core/widgets/common_snackbar.dart';
import '../../../domain/models.dart';
import '../bloc/admin_bloc.dart';

class SketchDirectiveDialog extends StatefulWidget {
  const SketchDirectiveDialog({super.key, required this.design});

  final JewelleryDesign design;

  static Future<void> show(BuildContext context, JewelleryDesign design) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SketchDirectiveDialog(design: design),
    );
  }

  @override
  State<SketchDirectiveDialog> createState() => _SketchDirectiveDialogState();
}

class _SketchDirectiveDialogState extends State<SketchDirectiveDialog> {
  late final TextEditingController _instructionsController;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<void>? _playerCompleteSubscription;
  Timer? _timer;
  String? _recordingPath;
  Duration _elapsed = Duration.zero;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _instructionsController = TextEditingController();
    _playerCompleteSubscription = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _playerCompleteSubscription?.cancel();
    _instructionsController.dispose();
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
        title: 'Microphone permission required',
        message: 'Allow microphone access to record a voice directive.',
      );
      return;
    }

    await _player.stop();
    final directory = await getTemporaryDirectory();
    final filePath =
        '${directory.path}${Platform.pathSeparator}sketch_${widget.design.id}_${DateTime.now().millisecondsSinceEpoch}.m4a';
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
    } catch (e) {
      if (mounted) {
        CommonSnackbar.error(
          context,
          title: 'Playback Error',
          message: 'Could not play voice preview.',
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_isRecording) await _stopRecording();
    final instructions = _instructionsController.text.trim();
    final path = _recordingPath;

    if (instructions.isEmpty && path == null) {
      CommonSnackbar.error(
        context,
        title: 'Directive Content Required',
        message:
            'Please enter text instructions or record a voice directive.',
      );
      return;
    }
    if (!mounted) return;
    final navigator = Navigator.of(context);
    final bloc = context.read<AdminBloc>();

    if (_isPlaying) {
      await _player.stop();
      if (mounted) setState(() => _isPlaying = false);
    }

    setState(() => _isSubmitting = true);
    final bytes = path == null ? null : await File(path).readAsBytes();
    if (!mounted) return;

    bloc.add(
      ReviewSketchDirectiveEvent(
        sketchId: widget.design.id,
        instructions: instructions.isNotEmpty
            ? instructions
            : 'Voice Directive Attached',
        audioFileName: path?.split(Platform.pathSeparator).last,
        audioBytes: bytes,
      ),
    );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final seconds =
        _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final minutes = _elapsed.inMinutes.toString().padLeft(2, '0');

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.paper,
      title: Text(
        'Sketch Directive - ${widget.design.code}',
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Correction instructions (Optional if voice recorded)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _instructionsController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter instructions or record voice directive below...',
                filled: true,
                fillColor: AppColors.canvas,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
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
                                  : 'Voice directive ready · $minutes:$seconds',
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
                              : 'High quality M4A audio directive',
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        CommonButton.primary(
          isFullWidth: false,
          height: 36,
          label: _isSubmitting ? 'Sending...' : 'Send Directive',
          icon: Icons.send,
          onPressed: _isSubmitting ? null : _submit,
        ),
      ],
    );
  }
}

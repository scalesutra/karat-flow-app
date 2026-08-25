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

  static Future<void> show(
    BuildContext context,
    JewelleryDesign design,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SketchDirectiveDialog(design: design),
    );
  }

  @override
  State<SketchDirectiveDialog> createState() =>
      _SketchDirectiveDialogState();
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
    _instructionsController = TextEditingController(
      text:
          'Please adjust prong height and check shank thickness for ${widget.design.name} (${widget.design.code}).',
    );
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
    if (_isPlaying) {
      await _player.pause();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }
    await _player.play(DeviceFileSource(path));
    if (mounted) setState(() => _isPlaying = true);
  }

  Future<void> _submit() async {
    final instructions = _instructionsController.text.trim();
    if (instructions.isEmpty) {
      CommonSnackbar.error(
        context,
        title: 'Instructions required',
        message: 'Enter correction instructions before sending.',
      );
      return;
    }
    if (_isRecording) await _stopRecording();
    if (!mounted) return;

    setState(() => _isSubmitting = true);
    final path = _recordingPath;
    final bytes = path == null ? null : await File(path).readAsBytes();
    if (!mounted) return;
    context.read<AdminBloc>().add(
      ReviewSketchDirectiveEvent(
        sketchId: widget.design.id,
        instructions: instructions,
        audioFileName: path == null ? null : path.split(Platform.pathSeparator).last,
        audioBytes: bytes,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final seconds = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
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
              'Correction instructions',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _instructionsController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter instructions for the CAD designer...',
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
                color: _isRecording
                    ? AppColors.dangerLight
                    : AppColors.canvas,
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
                              ? 'Add voice directive'
                              : 'Voice directive ready - $minutes:$seconds',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'M4A audio will be uploaded securely before review.',
                          style: TextStyle(color: AppColors.muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  if (_recordingPath != null && !_isRecording)
                    IconButton(
                      tooltip: _isPlaying ? 'Pause preview' : 'Play preview',
                      onPressed: _togglePreview,
                      icon: Icon(
                        _isPlaying ? Icons.pause_circle : Icons.play_circle,
                        color: AppColors.emerald,
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

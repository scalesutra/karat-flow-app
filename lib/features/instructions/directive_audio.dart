import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/common_snackbar.dart';
import '../../data/repositories/karatflow_api_repository.dart';

class DirectiveMessage {
  const DirectiveMessage({required this.text, this.audioUrl, this.imageUrl});

  static const voiceMarker = '[ 🎙️ Voice Note: ';
  static const imageMarker = '[ 🖼️ Image: ';

  factory DirectiveMessage.parse(String storedContent) {
    var cleanText = storedContent;

    String? extract(String marker) {
      final markerIndex = cleanText.indexOf(marker);
      if (markerIndex < 0) return null;
      final start = markerIndex + marker.length;
      final closingIndex = cleanText.indexOf(' ]', start);
      final end = closingIndex < 0 ? cleanText.length : closingIndex;
      final value = cleanText.substring(start, end).replaceAll(']', '').trim();
      cleanText = [
        cleanText.substring(0, markerIndex),
        if (closingIndex >= 0) cleanText.substring(closingIndex + 2),
      ].join(' ').trim();
      return value.isEmpty ? null : value;
    }

    final audioUrl = extract(voiceMarker);
    final imageUrl = extract(imageMarker);
    return DirectiveMessage(
      text: cleanText,
      audioUrl: audioUrl,
      imageUrl: imageUrl,
    );
  }

  final String text;
  final String? audioUrl;
  final String? imageUrl;

  bool get hasAudio => audioUrl?.isNotEmpty == true;
  bool get hasImage => imageUrl?.isNotEmpty == true;
}

class DirectiveImageAttachment extends StatefulWidget {
  const DirectiveImageAttachment({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  State<DirectiveImageAttachment> createState() =>
      _DirectiveImageAttachmentState();
}

class _DirectiveImageAttachmentState extends State<DirectiveImageAttachment> {
  final KaratFlowApiRepository _api = KaratFlowApiRepository();
  late Future<Uint8List> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _api.downloadStoredFile(widget.imageUrl);
  }

  @override
  void didUpdateWidget(covariant DirectiveImageAttachment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imageFuture = _api.downloadStoredFile(widget.imageUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 110,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final bytes = snapshot.data;
        if (snapshot.hasError || bytes == null || bytes.isEmpty) {
          return const Text(
            'Attached image could not be loaded.',
            style: TextStyle(color: Colors.redAccent, fontSize: 11),
          );
        }
        return InkWell(
          onTap: () => showDialog<void>(
            context: context,
            builder: (dialogContext) =>
                Dialog(child: InteractiveViewer(child: Image.memory(bytes))),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              bytes,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}

class DirectiveVoiceButton extends StatefulWidget {
  const DirectiveVoiceButton({super.key, required this.audioUrl});

  final String audioUrl;

  @override
  State<DirectiveVoiceButton> createState() => _DirectiveVoiceButtonState();
}

class _DirectiveVoiceButtonState extends State<DirectiveVoiceButton> {
  final AudioPlayer _player = AudioPlayer();
  final KaratFlowApiRepository _api = KaratFlowApiRepository();
  StreamSubscription<void>? _completeSubscription;
  Uint8List? _audioBytes;
  bool _canResume = false;
  bool _isLoading = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _completeSubscription = _player.onPlayerComplete.listen(
      (_) {
        if (!mounted) return;
        setState(() {
          _canResume = false;
          _isPlaying = false;
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!mounted) return;
        setState(() {
          _canResume = false;
          _isLoading = false;
          _isPlaying = false;
        });
      },
    );
  }

  @override
  void didUpdateWidget(covariant DirectiveVoiceButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioUrl != widget.audioUrl) {
      _player.stop();
      _audioBytes = null;
      _canResume = false;
      _isLoading = false;
      _isPlaying = false;
    }
  }

  @override
  void dispose() {
    _completeSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isLoading) return;
    try {
      if (_isPlaying) {
        await _player.pause();
        if (mounted) setState(() => _isPlaying = false);
        return;
      }
      if (_canResume) {
        await _player.resume();
        if (mounted) setState(() => _isPlaying = true);
        return;
      }

      setState(() => _isLoading = true);
      final bytes =
          _audioBytes ?? await _api.downloadStoredFile(widget.audioUrl);
      _audioBytes = bytes;
      await _player.play(BytesSource(bytes, mimeType: 'audio/mp4'));
      if (!mounted) return;
      setState(() {
        _canResume = true;
        _isLoading = false;
        _isPlaying = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _canResume = false;
        _isLoading = false;
        _isPlaying = false;
      });
      CommonSnackbar.error(
        context,
        title: 'Voice note unavailable',
        message: 'Could not download or play this voice note: $error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _toggle,
      icon: _isLoading
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
      label: Text(
        _isLoading
            ? 'Loading voice note'
            : _isPlaying
            ? 'Pause voice note'
            : 'Play voice note',
      ),
    );
  }
}

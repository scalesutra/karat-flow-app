import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/common_card.dart';
import '../../../core/widgets/common_snackbar.dart';
import '../../../data/models/api_models.dart';
import '../bloc/cad_bloc.dart';

import '../../../data/demo_store.dart';

class SketchDirectivesSection extends StatelessWidget {
  const SketchDirectivesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: DemoStore.instance,
      builder: (context, _) {
        return BlocBuilder<CadBloc, CadState>(
          builder: (context, state) {
            final sketchDirectives = state is CadLoaded
                ? state.sketchDirectives
                : const <ApiSketch>[];

            final storeDirectives = DemoStore.instance.adminDirectives
                .where((d) {
                  final r = d['recipient'] ?? '';
                  return r.contains('CAD') ||
                      r.contains('All') ||
                      r.contains('Designer');
                })
                .toList();

            final totalCount = sketchDirectives.length + storeDirectives.length;

            return CommonCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.campaign_outlined,
                        color: AppColors.goldDark,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Admin Directives & Instructions',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        '$totalCount Active',
                        style: const TextStyle(
                          color: AppColors.goldDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (state is CadLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (totalCount == 0)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'No active directives or voice notes from Admin.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else ...[
                    ...storeDirectives.map((d) => Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.goldLight.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.gavel,
                                    size: 14,
                                    color: AppColors.goldDark,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Governance Directive · ${d['recipient'] ?? 'CAD Designer'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                        color: AppColors.goldDark,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    d['timeLabel'] ?? 'Just now',
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                d['instruction'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        )),
                    ...sketchDirectives.map(_SketchDirectiveTile.new),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SketchDirectiveTile extends StatefulWidget {
  const _SketchDirectiveTile(this.sketch);

  final ApiSketch sketch;

  @override
  State<_SketchDirectiveTile> createState() => _SketchDirectiveTileState();
}

class _SketchDirectiveTileState extends State<_SketchDirectiveTile> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<void>? _completeSubscription;
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _completeSubscription = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _completeSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    final url = widget.sketch.feedbackAudioUrl?.trim();
    if (url == null || url.isEmpty || _isLoading) return;
    try {
      if (_isPlaying) {
        await _player.pause();
        if (mounted) setState(() => _isPlaying = false);
        return;
      }
      setState(() => _isLoading = true);
      await _player.play(UrlSource(url));
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isPlaying = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isPlaying = false;
      });
      CommonSnackbar.error(
        context,
        title: 'Audio unavailable',
        message: 'Could not play this directive: $error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sketch = widget.sketch;
    final instructions = sketch.adminInstructions?.trim() ?? '';
    final hasAudio = sketch.feedbackAudioUrl?.trim().isNotEmpty ?? false;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.goldLight.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sketch.designNumber.isEmpty
                      ? sketch.title
                      : sketch.designNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                sketch.status,
                style: const TextStyle(
                  color: AppColors.goldDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          if (sketch.title.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              sketch.title,
              style: const TextStyle(color: AppColors.muted, fontSize: 10),
            ),
          ],
          if (instructions.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              instructions,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
          if (hasAudio) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _toggleAudio,
              icon: _isLoading
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              label: Text(_isPlaying ? 'Pause voice note' : 'Play voice note'),
            ),
          ],
        ],
      ),
    );
  }
}

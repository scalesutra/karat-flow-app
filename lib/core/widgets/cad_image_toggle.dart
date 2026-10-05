import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'common_remote_image.dart';

/// A thumbnail image with an overlay toggle badge to switch between
/// the auto-cropped 3D render and the original full CAD spec sheet.
///
/// Only shows the toggle badge when both [croppedUrl] and [rawCadSheetUrl]
/// are non-empty and different from each other.
class CadImageToggle extends StatefulWidget {
  const CadImageToggle({
    super.key,
    required this.croppedUrl,
    required this.rawCadSheetUrl,
    this.width = 112,
    this.height = 112,
    this.borderRadius,
    this.fit = BoxFit.contain,
    this.fallbackWidget,
    this.heroTag,
  });

  /// The auto-cropped clean 3D render URL (cleanDesignUrl).
  final String croppedUrl;

  /// The original full CAD spec sheet URL (bomFileUrl).
  final String rawCadSheetUrl;

  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final Widget? fallbackWidget;
  final String? heroTag;

  @override
  State<CadImageToggle> createState() => _CadImageToggleState();
}

class _CadImageToggleState extends State<CadImageToggle> {
  bool _showingCropped = true;

  bool get _canToggle =>
      widget.croppedUrl.isNotEmpty &&
      widget.rawCadSheetUrl.isNotEmpty &&
      widget.croppedUrl != widget.rawCadSheetUrl;

  String get _activeUrl =>
      _showingCropped ? widget.croppedUrl : widget.rawCadSheetUrl;

  @override
  Widget build(BuildContext context) {
    final radius =
        widget.borderRadius ?? BorderRadius.circular(AppDimensions.radiusLarge);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Image ──
            Container(
              color: AppColors.canvas,
              child: CommonRemoteImage(
                imageUrl: _activeUrl,
                width: widget.width,
                height: widget.height,
                fit: widget.fit,
                borderRadius: radius,
                fallbackWidget: widget.fallbackWidget,
                heroTag: widget.heroTag,
              ),
            ),

            // ── Toggle Badge ──
            if (_canToggle)
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => setState(() => _showingCropped = !_showingCropped),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ink.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _showingCropped ? 'Full' : 'Crop',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

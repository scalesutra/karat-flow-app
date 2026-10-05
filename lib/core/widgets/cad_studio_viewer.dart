import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'common_remote_image.dart';

/// Full-size image viewer with tabbed switching between the auto-cropped
/// 3D design render and the original CAD spec sheet.
///
/// Used inside detail modals / bottom sheets for full inspection.
class CadStudioViewer extends StatefulWidget {
  const CadStudioViewer({
    super.key,
    required this.croppedUrl,
    required this.rawCadSheetUrl,
  });

  /// The auto-cropped clean 3D render URL (cleanDesignUrl).
  final String croppedUrl;

  /// The original full CAD spec sheet URL (bomFileUrl).
  final String rawCadSheetUrl;

  @override
  State<CadStudioViewer> createState() => _CadStudioViewerState();
}

enum _ImageTab { designRender, cadSheet }

class _CadStudioViewerState extends State<CadStudioViewer> {
  _ImageTab _activeTab = _ImageTab.designRender;

  bool get _hasBothImages =>
      widget.croppedUrl.isNotEmpty &&
      widget.rawCadSheetUrl.isNotEmpty &&
      widget.croppedUrl != widget.rawCadSheetUrl;

  String get _displayedUrl => _activeTab == _ImageTab.designRender
      ? widget.croppedUrl
      : widget.rawCadSheetUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Tab Switcher ──
        if (_hasBothImages) ...[
          Row(
            children: [
              _buildTab(
                label: '✨ 3D Design Render',
                tab: _ImageTab.designRender,
                activeColor: AppColors.emerald,
              ),
              const SizedBox(width: 8),
              _buildTab(
                label: '📄 CAD Spec Sheet',
                tab: _ImageTab.cadSheet,
                activeColor: const Color(0xFFF59E0B), // amber-500
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // ── Image Viewport ──
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 200),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            border: Border.all(color: AppColors.outline),
          ),
          padding: const EdgeInsets.all(12),
          child: AspectRatio(
            aspectRatio: 1,
            child: CommonRemoteImage(
              imageUrl: _displayedUrl,
              fit: BoxFit.contain,
              borderRadius: BorderRadius.circular(
                AppDimensions.radiusMedium,
              ),
              fallbackWidget: Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 48,
                  color: AppColors.muted,
                ),
              ),
            ),
          ),
        ),

        // ── Caption ──
        if (_hasBothImages) ...[
          const SizedBox(height: 8),
          Text(
            _activeTab == _ImageTab.designRender
                ? 'Auto-cropped 3D jewelry render isolated from CAD sheet'
                : 'Full original engineering CAD sheet with dimension specs and gem table',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.muted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildTab({
    required String label,
    required _ImageTab tab,
    required Color activeColor,
  }) {
    final isActive = _activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor
                : AppColors.paper,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            border: Border.all(
              color: isActive ? activeColor : AppColors.outline,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isActive ? Colors.white : AppColors.muted,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

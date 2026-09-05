import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'common_button.dart';
import 'remote_cad_mesh.dart';

class Common3DViewer extends StatefulWidget {
  const Common3DViewer({
    super.key,
    required this.designCode,
    required this.productTitle,
    this.modelUrl,
  });

  final String designCode;
  final String productTitle;
  final String? modelUrl;

  @override
  State<Common3DViewer> createState() => _Common3DViewerState();
}

class _Common3DViewerState extends State<Common3DViewer>
    with SingleTickerProviderStateMixin {
  double _rotationX = -0.6;
  double _rotationY = 0.5;
  bool _isAutoRotating = true;
  bool _isWireframe = false;
  String _selectedMaterial = 'Gold (22K)';
  Timer? _autoResumeTimer;

  late final AnimationController _autoRotateController;

  final Map<String, Color> _materials = {
    'Gold (22K)': const Color(0xFFB9812E),
    'Rose Gold': const Color(0xFFE5A990),
    'White Gold / Platinum': const Color(0xFFD4D8D2),
    'Emerald Green Gold': const Color(0xFF0D6252),
  };

  @override
  void initState() {
    super.initState();
    _autoRotateController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addListener(() {
            if (_isAutoRotating && mounted) {
              setState(() {
                _rotationY += 0.015;
              });
            }
          });

    _autoRotateController.repeat();
  }

  @override
  void dispose() {
    _autoResumeTimer?.cancel();
    _autoRotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ringColor = _materials[_selectedMaterial] ?? const Color(0xFFB9812E);
    final hasModel = widget.modelUrl?.trim().isNotEmpty ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.productTitle} - 3D STL',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      'Interactive CAD Rendering · ${widget.designCode}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3D Visualizer Render Area
          GestureDetector(
            onPanStart: (_) {
              if (!hasModel) return;
              _autoResumeTimer?.cancel();
              setState(() => _isAutoRotating = false);
            },
            onPanUpdate: (details) {
              if (!hasModel) return;
              setState(() {
                _rotationY += details.delta.dx * 0.01;
                _rotationX = (_rotationX - details.delta.dy * 0.01).clamp(-1.4, 1.4);
              });
            },
            onPanEnd: (_) {
              if (!hasModel) return;
              _autoResumeTimer?.cancel();
              _autoResumeTimer = Timer(const Duration(milliseconds: 2500), () {
                if (mounted) setState(() => _isAutoRotating = true);
              });
            },
            child: Container(
              height: 320,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.outlineLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  if (hasModel) ...[
                    Positioned.fill(
                      child: RemoteCadMesh(
                        modelUrl: widget.modelUrl!,
                        rotationX: _rotationX,
                        rotationY: _rotationY,
                        metalColor: ringColor,
                        isWireframe: _isWireframe,
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.paper.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isAutoRotating ? Icons.sync : Icons.touch_app,
                              size: 12,
                              color: _isAutoRotating
                                  ? AppColors.emerald
                                  : AppColors.muted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isAutoRotating
                                  ? 'Auto Rotating (Drag to adjust)'
                                  : 'Drag to rotate 3D mesh',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _isAutoRotating
                                    ? AppColors.emeraldDark
                                    : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.view_in_ar_outlined,
                              size: 48,
                              color: AppColors.muted,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No CAD 3D Model Attached',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.ink,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'An STL or 3D CAD file has not been uploaded for this design yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (hasModel) ...[
            const SizedBox(height: 16),

            // Controls panel
            Row(
              children: [
                // Wireframe toggle
                Expanded(
                  child: CommonButton.outlined(
                    height: 40,
                    icon: _isWireframe ? Icons.blur_on : Icons.grid_3x3,
                    label: _isWireframe ? 'Shaded View' : 'Wireframe View',
                    onPressed: () {
                      setState(() {
                        _isWireframe = !_isWireframe;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Auto-rotate toggle
                Expanded(
                  child: CommonButton.outlined(
                    height: 40,
                    icon: _isAutoRotating
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                    label: _isAutoRotating ? 'Pause Rotate' : 'Auto Rotate',
                    onPressed: () {
                      _autoResumeTimer?.cancel();
                      setState(() {
                        _isAutoRotating = !_isAutoRotating;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Material dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Material / Metal Shader:',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedMaterial,
                  dropdownColor: AppColors.paper,
                  underline: const SizedBox.shrink(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.emeraldDark,
                  ),
                  items: _materials.keys.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedMaterial = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

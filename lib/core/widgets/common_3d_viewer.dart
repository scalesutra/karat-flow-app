import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'common_button.dart';

class Common3DViewer extends StatefulWidget {
  const Common3DViewer({
    super.key,
    required this.designCode,
    required this.productTitle,
  });

  final String designCode;
  final String productTitle;

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
    _autoRotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        if (_isAutoRotating) {
          setState(() {
            _rotationY += 0.015;
          });
        }
      });

    _autoRotateController.repeat();
  }

  @override
  void dispose() {
    _autoRotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ringColor = _materials[_selectedMaterial] ?? const Color(0xFFB9812E);

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
            onPanUpdate: (details) {
              setState(() {
                _isAutoRotating = false;
                _rotationY += details.delta.dx * 0.01;
                _rotationX -= details.delta.dy * 0.01;
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
                  CustomPaint(
                    painter: Ring3DPainter(
                      rotationX: _rotationX,
                      rotationY: _rotationY,
                      metalColor: ringColor,
                      isWireframe: _isWireframe,
                    ),
                    size: Size.infinite,
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
                      child: const Row(
                        children: [
                          Icon(Icons.touch_app, size: 12, color: AppColors.muted),
                          SizedBox(width: 4),
                          Text(
                            'Drag to rotate 3D mesh',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
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
                  icon: _isAutoRotating ? Icons.pause : Icons.play_arrow,
                  label: _isAutoRotating ? 'Pause Rotate' : 'Auto Rotate',
                  onPressed: () {
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
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Custom painter to draw a wireframe solitaire ring projected in 3D
// ═══════════════════════════════════════════════════════════════════
class Ring3DPainter extends CustomPainter {
  Ring3DPainter({
    required this.rotationX,
    required this.rotationY,
    required this.metalColor,
    required this.isWireframe,
  });

  final double rotationX;
  final double rotationY;
  final Color metalColor;
  final bool isWireframe;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = min(size.width, size.height) * 0.38;

    final paintMetal = Paint()
      ..color = metalColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final paintDiamond = Paint()
      ..color = const Color(0xFF80DEEA)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final fillDiamond = Paint()
      ..color = const Color(0xFFE0F7FA).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    // Helper: projection of a 3D point to 2D
    Offset project(double x, double y, double z) {
      // Rotate around Y axis
      double x1 = x * cos(rotationY) - z * sin(rotationY);
      double z1 = x * sin(rotationY) + z * cos(rotationY);

      // Rotate around X axis
      double y2 = y * cos(rotationX) - z1 * sin(rotationX);

      // Simple orthographic projection
      return Offset(center.dx + x1 * scale, center.dy + y2 * scale);
    }

    // 1. Draw Ring Band (Circle path in 3D space)
    final List<Offset> bandPoints = [];
    const int segments = 32;
    for (int i = 0; i <= segments; i++) {
      double angle = (2 * pi * i) / segments;
      // Circle on YZ plane, offset a bit on X to give thickness
      bandPoints.add(project(0.0, sin(angle), cos(angle)));
    }

    final Path bandPath = Path()..moveTo(bandPoints[0].dx, bandPoints[0].dy);
    for (int i = 1; i < bandPoints.length; i++) {
      bandPath.lineTo(bandPoints[i].dx, bandPoints[i].dy);
    }
    canvas.drawPath(bandPath, paintMetal);

    // Give some thickness to the ring band by drawing a second circle slightly offset
    final List<Offset> bandInnerPoints = [];
    for (int i = 0; i <= segments; i++) {
      double angle = (2 * pi * i) / segments;
      bandInnerPoints.add(project(0.08, sin(angle) * 0.9, cos(angle) * 0.9));
    }
    final Path bandInnerPath = Path()
      ..moveTo(bandInnerPoints[0].dx, bandInnerPoints[0].dy);
    for (int i = 1; i < bandInnerPoints.length; i++) {
      bandInnerPath.lineTo(bandInnerPoints[i].dx, bandInnerPoints[i].dy);
    }
    canvas.drawPath(bandInnerPath, paintMetal);

    // Cross-connect the band thickness rings (draw wireframe lines)
    if (isWireframe) {
      for (int i = 0; i < segments; i += 4) {
        canvas.drawLine(bandPoints[i], bandInnerPoints[i], paintMetal);
      }
    }

    // 2. Draw Crown Collet (Holds the Diamond Solitaire on top of the ring, i.e., y = -1.0)
    // The base of collet sits on the ring top, prong tips rise up
    final colletBaseCenter = project(0.04, -0.9, 0.0);
    final p1 = project(-0.15, -1.15, -0.15);
    final p2 = project(0.15, -1.15, -0.15);
    final p3 = project(0.15, -1.15, 0.15);
    final p4 = project(-0.15, -1.15, 0.15);

    // Connect prongs to ring base
    canvas.drawLine(colletBaseCenter, p1, paintMetal);
    canvas.drawLine(colletBaseCenter, p2, paintMetal);
    canvas.drawLine(colletBaseCenter, p3, paintMetal);
    canvas.drawLine(colletBaseCenter, p4, paintMetal);

    // Connect prong tips loop
    final Path colletLoop = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();
    canvas.drawPath(colletLoop, paintMetal);

    // 3. Draw Solitaire Diamond Shape (Sitting on top of the collet)
    // Diamond top table
    final dTable1 = project(-0.12, -1.35, -0.12);
    final dTable2 = project(0.12, -1.35, -0.12);
    final dTable3 = project(0.12, -1.35, 0.12);
    final dTable4 = project(-0.12, -1.35, 0.12);

    // Diamond girdle (widest loop, matches prong tips p1, p2, p3, p4)
    // Diamond culet (bottom tip) sits inside the collet center
    final dCulet = project(0.04, -1.05, 0.0);

    // Shading facets (Draw filled polygons if not wireframe)
    if (!isWireframe) {
      // Crown facets
      final Path facet1 = Path()
        ..moveTo(dTable1.dx, dTable1.dy)
        ..lineTo(dTable2.dx, dTable2.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p1.dx, p1.dy)
        ..close();
      final Path facet2 = Path()
        ..moveTo(dTable2.dx, dTable2.dy)
        ..lineTo(dTable3.dx, dTable3.dy)
        ..lineTo(p3.dx, p3.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close();
      final Path facet3 = Path()
        ..moveTo(dTable3.dx, dTable3.dy)
        ..lineTo(dTable4.dx, dTable4.dy)
        ..lineTo(p4.dx, p4.dy)
        ..lineTo(p3.dx, p3.dy)
        ..close();
      final Path facet4 = Path()
        ..moveTo(dTable4.dx, dTable4.dy)
        ..lineTo(dTable1.dx, dTable1.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p4.dx, p4.dy)
        ..close();

      // Pavilion facets (Bottom culet cone)
      final Path pav1 = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(dCulet.dx, dCulet.dy)
        ..close();
      final Path pav2 = Path()
        ..moveTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..lineTo(dCulet.dx, dCulet.dy)
        ..close();
      final Path pav3 = Path()
        ..moveTo(p3.dx, p3.dy)
        ..lineTo(p4.dx, p4.dy)
        ..lineTo(dCulet.dx, dCulet.dy)
        ..close();
      final Path pav4 = Path()
        ..moveTo(p4.dx, p4.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(dCulet.dx, dCulet.dy)
        ..close();

      canvas.drawPath(facet1, fillDiamond);
      canvas.drawPath(facet2, fillDiamond);
      canvas.drawPath(facet3, fillDiamond);
      canvas.drawPath(facet4, fillDiamond);

      canvas.drawPath(pav1, fillDiamond);
      canvas.drawPath(pav2, fillDiamond);
      canvas.drawPath(pav3, fillDiamond);
      canvas.drawPath(pav4, fillDiamond);
    }

    // Draw diamond wireframe lines
    // Girdle loop lines
    canvas.drawLine(p1, p2, paintDiamond);
    canvas.drawLine(p2, p3, paintDiamond);
    canvas.drawLine(p3, p4, paintDiamond);
    canvas.drawLine(p4, p1, paintDiamond);

    // Table loop lines
    final Path tablePath = Path()
      ..moveTo(dTable1.dx, dTable1.dy)
      ..lineTo(dTable2.dx, dTable2.dy)
      ..lineTo(dTable3.dx, dTable3.dy)
      ..lineTo(dTable4.dx, dTable4.dy)
      ..close();
    canvas.drawPath(tablePath, paintDiamond);

    // Connect table to girdle (facets)
    canvas.drawLine(dTable1, p1, paintDiamond);
    canvas.drawLine(dTable2, p2, paintDiamond);
    canvas.drawLine(dTable3, p3, paintDiamond);
    canvas.drawLine(dTable4, p4, paintDiamond);

    // Connect girdle to culet (bottom point)
    canvas.drawLine(p1, dCulet, paintDiamond);
    canvas.drawLine(p2, dCulet, paintDiamond);
    canvas.drawLine(p3, dCulet, paintDiamond);
    canvas.drawLine(p4, dCulet, paintDiamond);
  }

  @override
  bool shouldRepaint(Ring3DPainter oldDelegate) {
    return oldDelegate.rotationX != rotationX ||
        oldDelegate.rotationY != rotationY ||
        oldDelegate.metalColor != metalColor ||
        oldDelegate.isWireframe != isWireframe;
  }
}

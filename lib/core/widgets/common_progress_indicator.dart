import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

enum IndicatorTheme { universal, workshop, frontOffice, cad }

/// Ultra-Modern 3D Luxury Progress Indicator with Dedicated Workshop, CAD & Front Office Modes
class CommonProgressIndicator extends StatefulWidget {
  const CommonProgressIndicator({
    super.key,
    this.size = 40.0,
    this.strokeWidth = 2.8,
    this.theme = IndicatorTheme.universal,
    this.primaryColor,
    this.secondaryColor,
    this.label,
  });

  const CommonProgressIndicator.workshop({
    super.key,
    this.size = 44.0,
    this.strokeWidth = 3.0,
    this.theme = IndicatorTheme.workshop,
    this.primaryColor,
    this.secondaryColor,
    this.label = 'Syncing Live Workshop Floor & Benches...',
  });

  const CommonProgressIndicator.frontOffice({
    super.key,
    this.size = 44.0,
    this.strokeWidth = 3.0,
    this.theme = IndicatorTheme.frontOffice,
    this.primaryColor,
    this.secondaryColor,
    this.label = 'Refreshing Customer Orders & Pipeline...',
  });

  const CommonProgressIndicator.cad({
    super.key,
    this.size = 46.0,
    this.strokeWidth = 3.0,
    this.theme = IndicatorTheme.cad,
    this.primaryColor,
    this.secondaryColor,
    this.label = 'Rendering 3D CAD Mesh & STL Geometry...',
  });

  const CommonProgressIndicator.admin({
    super.key,
    this.size = 46.0,
    this.strokeWidth = 3.0,
    this.theme = IndicatorTheme.universal,
    this.primaryColor = AppColors.emerald,
    this.secondaryColor = AppColors.gold,
    this.label = 'Synchronizing Admin Factory ERP...',
  });

  const CommonProgressIndicator.small({
    super.key,
    this.size = 22.0,
    this.strokeWidth = 2.0,
    this.theme = IndicatorTheme.universal,
    this.primaryColor,
    this.secondaryColor,
    this.label,
  });

  const CommonProgressIndicator.medium({
    super.key,
    this.size = 42.0,
    this.strokeWidth = 2.8,
    this.theme = IndicatorTheme.universal,
    this.primaryColor,
    this.secondaryColor,
    this.label,
  });

  const CommonProgressIndicator.large({
    super.key,
    this.size = 68.0,
    this.strokeWidth = 3.4,
    this.theme = IndicatorTheme.universal,
    this.primaryColor,
    this.secondaryColor,
    this.label = 'Synchronizing KaratFlow Cloud...',
  });

  final double size;
  final double strokeWidth;
  final IndicatorTheme theme;
  final Color? primaryColor;
  final Color? secondaryColor;
  final String? label;

  @override
  State<CommonProgressIndicator> createState() =>
      _CommonProgressIndicatorState();
}

class _CommonProgressIndicatorState extends State<CommonProgressIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _pulseController;
  late final AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.theme == IndicatorTheme.workshop
            ? 2000
            : (widget.theme == IndicatorTheme.cad ? 2200 : 2500),
      ),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.theme) {
      IndicatorTheme.workshop => _buildWorkshopIndicator(),
      IndicatorTheme.frontOffice => _buildFrontOfficeIndicator(),
      IndicatorTheme.cad => _buildCadIndicator(),
      IndicatorTheme.universal => _buildUniversalIndicator(),
    };
  }

  // =========================================================================
  // 1. CAD 3D DESIGN DASHBOARD INDICATOR (Holographic Wireframe, Laser & STL Mesh)
  // =========================================================================
  Widget _buildCadIndicator() {
    final cyanNeon = widget.primaryColor ?? const Color(0xFF00E5FF);
    final blueLaser = widget.secondaryColor ?? const Color(0xFF2979FF);
    final cadGold = const Color(0xFFFFD700);

    final loader = SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _spinController,
          _pulseController,
          _sparkleController,
        ]),
        builder: (context, _) {
          final spin = _spinController.value * 2 * math.pi;
          final pulse = Curves.easeInOutCubic.transform(_pulseController.value);
          final spark = _sparkleController.value * 2 * math.pi;

          return Stack(
            alignment: Alignment.center,
            children: [
              // 1. Holographic Viewport Grid Bloom
              Container(
                width: widget.size * 0.95,
                height: widget.size * 0.95,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      cyanNeon.withValues(alpha: 0.28 * pulse),
                      blueLaser.withValues(alpha: 0.15 * pulse),
                      Colors.transparent,
                    ],
                    stops: const [0.1, 0.6, 1.0],
                  ),
                ),
              ),

              // 2. CAD Coordinate Axes & Grid Bezel (X, Y, Z Ticks)
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _CadCoordinateBezelPainter(
                  cyanColor: cyanNeon,
                  pulse: pulse,
                ),
              ),

              // 3. 3D Isometric CAD Wireframe Orbit (Primary Laser Axis)
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0025)
                  ..rotateX(0.78)
                  ..rotateY(0.4)
                  ..rotateZ(spin),
                child: CustomPaint(
                  size: Size(widget.size * 0.92, widget.size * 0.92),
                  painter: _CadLaserOrbitPainter(
                    color1: blueLaser,
                    color2: cyanNeon,
                    strokeWidth: widget.strokeWidth,
                    progress: 0.75,
                  ),
                ),
              ),

              // 4. Counter 3D Gold CAD Mesh Orbit
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0025)
                  ..rotateX(-0.68)
                  ..rotateY(-0.45)
                  ..rotateZ(-spin * 1.25),
                child: CustomPaint(
                  size: Size(widget.size * 0.72, widget.size * 0.72),
                  painter: _CadLaserOrbitPainter(
                    color1: cadGold,
                    color2: const Color(0xFFFFF9C4),
                    strokeWidth: widget.strokeWidth * 0.85,
                    progress: 0.65,
                  ),
                ),
              ),

              // 5. Center 3D Holographic CAD Viewport Cube / Mesh
              if (widget.size >= 24)
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.003)
                    ..rotateY(spark)
                    ..rotateX(0.35)
                    ..scaleByDouble(
                      0.85 + 0.25 * pulse,
                      0.85 + 0.25 * pulse,
                      1.0,
                      1.0,
                    ),
                  child: Container(
                    width: widget.size * 0.38,
                    height: widget.size * 0.38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.pureWhite,
                          const Color(0xFFE1F5FE),
                          cyanNeon,
                        ],
                        stops: const [0.2, 0.65, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cyanNeon.withValues(alpha: 0.75),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.view_in_ar_outlined,
                      size: widget.size * 0.24,
                      color: AppColors.ink,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );

    if (widget.label != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          loader,
          const SizedBox(height: 14),
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 3),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.view_in_ar, size: 12, color: Color(0xFF00E5FF)),
              SizedBox(width: 4),
              Text(
                '3D Mesh Viewport · Rhino & MatrixGold Live Sync',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return loader;
  }

  // =========================================================================
  // 2. WORKSHOP / PROCESS MANAGER INDICATOR (Molten Gold, CAD Mesh & Kiln Pulse)
  // =========================================================================
  Widget _buildWorkshopIndicator() {
    final goldHot = widget.primaryColor ?? const Color(0xFFFFB300);
    final goldBright = const Color(0xFFFFE57F);
    final furnaceOrange = widget.secondaryColor ?? const Color(0xFFFF5722);
    final emeraldDark = AppColors.emeraldDark;

    final loader = SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _spinController,
          _pulseController,
          _sparkleController,
        ]),
        builder: (context, _) {
          final spin = _spinController.value * 2 * math.pi;
          final pulse = Curves.easeInOutSine.transform(_pulseController.value);
          final spark = _sparkleController.value * 2 * math.pi;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Molten Heat Aura
              Container(
                width: widget.size * 0.95,
                height: widget.size * 0.95,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      goldHot.withValues(alpha: 0.35 * pulse),
                      furnaceOrange.withValues(alpha: 0.15 * pulse),
                      Colors.transparent,
                    ],
                    stops: const [0.1, 0.6, 1.0],
                  ),
                ),
              ),

              // Outer Workshop Kiln Gear & Notches
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _WorkshopGearBezelPainter(
                  accentColor: goldHot,
                  pulse: pulse,
                ),
              ),

              // 3D Molten Gold Flow Arc
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002)
                  ..rotateX(0.7)
                  ..rotateY(0.2)
                  ..rotateZ(spin),
                child: CustomPaint(
                  size: Size(widget.size * 0.9, widget.size * 0.9),
                  painter: _WorkshopMoltenFlowPainter(
                    color1: goldHot,
                    color2: furnaceOrange,
                    strokeWidth: widget.strokeWidth,
                    progress: 0.78,
                  ),
                ),
              ),

              // Counter 3D Laser Pulse Track
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002)
                  ..rotateX(-0.6)
                  ..rotateY(-0.3)
                  ..rotateZ(-spin * 1.3),
                child: CustomPaint(
                  size: Size(widget.size * 0.7, widget.size * 0.7),
                  painter: _WorkshopMoltenFlowPainter(
                    color1: emeraldDark,
                    color2: const Color(0xFF00E676),
                    strokeWidth: widget.strokeWidth * 0.8,
                    progress: 0.68,
                  ),
                ),
              ),

              // Center 3D Floating Casting Crucible / CAD Micro Spark
              if (widget.size >= 24)
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.003)
                    ..rotateY(spark)
                    ..rotateX(0.25)
                    ..scaleByDouble(
                      0.85 + 0.25 * pulse,
                      0.85 + 0.25 * pulse,
                      1.0,
                      1.0,
                    ),
                  child: Container(
                    width: widget.size * 0.38,
                    height: widget.size * 0.38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.pureWhite,
                          goldBright,
                          furnaceOrange,
                        ],
                        stops: const [0.2, 0.65, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: goldHot.withValues(alpha: 0.8),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.precision_manufacturing_outlined,
                      size: widget.size * 0.24,
                      color: AppColors.ink,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );

    if (widget.label != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          loader,
          const SizedBox(height: 14),
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 3),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flash_on, size: 12, color: Color(0xFFFFB300)),
              SizedBox(width: 4),
              Text(
                'Live Benches & Karigar Stage Engine',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return loader;
  }

  // =========================================================================
  // 3. FRONT OFFICE INDICATOR (Luxury Diamond Solitaire & Emerald Velvet Shimmer)
  // =========================================================================
  Widget _buildFrontOfficeIndicator() {
    final goldLuxury = widget.primaryColor ?? const Color(0xFFD4AF37);
    final emeraldLuxe = widget.secondaryColor ?? const Color(0xFF00A86B);
    final goldBright = const Color(0xFFFFF6D6);

    final loader = SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _spinController,
          _pulseController,
          _sparkleController,
        ]),
        builder: (context, _) {
          final spin = _spinController.value * 2 * math.pi;
          final pulse = Curves.easeInOutCubic.transform(_pulseController.value);
          final spark = _sparkleController.value * 2 * math.pi;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Velvet Emerald Bloom
              Container(
                width: widget.size * 0.95,
                height: widget.size * 0.95,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      emeraldLuxe.withValues(alpha: 0.28 * pulse),
                      goldLuxury.withValues(alpha: 0.15 * pulse),
                      Colors.transparent,
                    ],
                    stops: const [0.1, 0.55, 1.0],
                  ),
                ),
              ),

              // Outer Luxury Diamond Micro-Bezel
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _FrontOfficeDiamondBezelPainter(
                  goldColor: goldLuxury,
                  pulse: pulse,
                ),
              ),

              // 3D Polished Gold Solitaire Ring Orbit
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0025)
                  ..rotateX(0.75)
                  ..rotateY(0.35)
                  ..rotateZ(spin),
                child: CustomPaint(
                  size: Size(widget.size * 0.9, widget.size * 0.9),
                  painter: _FrontOfficeLuxuryOrbitPainter(
                    color1: goldLuxury,
                    color2: goldBright,
                    strokeWidth: widget.strokeWidth,
                    progress: 0.76,
                  ),
                ),
              ),

              // Counter 3D Emerald Crown Orbit
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0025)
                  ..rotateX(-0.65)
                  ..rotateY(-0.45)
                  ..rotateZ(-spin * 1.2),
                child: CustomPaint(
                  size: Size(widget.size * 0.72, widget.size * 0.72),
                  painter: _FrontOfficeLuxuryOrbitPainter(
                    color1: emeraldLuxe,
                    color2: const Color(0xFF66FFA6),
                    strokeWidth: widget.strokeWidth * 0.85,
                    progress: 0.65,
                  ),
                ),
              ),

              // Center 3D Floating Solitaire Diamond
              if (widget.size >= 24)
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.003)
                    ..rotateY(spark)
                    ..rotateX(0.35)
                    ..scaleByDouble(
                      0.88 + 0.22 * pulse,
                      0.88 + 0.22 * pulse,
                      1.0,
                      1.0,
                    ),
                  child: Container(
                    width: widget.size * 0.38,
                    height: widget.size * 0.38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.pureWhite,
                          const Color(0xFFE0F7FA),
                          goldLuxury,
                        ],
                        stops: const [0.3, 0.7, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: emeraldLuxe.withValues(alpha: 0.6),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.diamond_outlined,
                      size: widget.size * 0.24,
                      color: AppColors.ink,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );

    if (widget.label != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          loader,
          const SizedBox(height: 14),
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 3),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified, size: 12, color: Color(0xFF00A86B)),
              SizedBox(width: 4),
              Text(
                'Client Orders & Dispatch Pipeline Live',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return loader;
  }

  // =========================================================================
  // 4. UNIVERSAL INDICATOR (Tourbillon Gyroscope)
  // =========================================================================
  Widget _buildUniversalIndicator() {
    final goldMain = widget.primaryColor ?? const Color(0xFFD4AF37);
    final goldGlow = const Color(0xFFFFE082);
    final emeraldNeon = widget.secondaryColor ?? const Color(0xFF00A86B);

    final loader = SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _spinController,
          _pulseController,
          _sparkleController,
        ]),
        builder: (context, _) {
          final spinVal = _spinController.value * 2 * math.pi;

          return Stack(
            alignment: Alignment.center,
            children: [
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002)
                  ..rotateX(0.7)
                  ..rotateY(0.3)
                  ..rotateZ(spinVal),
                child: CustomPaint(
                  size: Size(widget.size * 0.92, widget.size * 0.92),
                  painter: _FrontOfficeLuxuryOrbitPainter(
                    color1: goldMain,
                    color2: goldGlow,
                    strokeWidth: widget.strokeWidth,
                    progress: 0.72,
                  ),
                ),
              ),
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002)
                  ..rotateX(-0.65)
                  ..rotateY(-0.4)
                  ..rotateZ(-spinVal * 1.25),
                child: CustomPaint(
                  size: Size(widget.size * 0.72, widget.size * 0.72),
                  painter: _FrontOfficeLuxuryOrbitPainter(
                    color1: emeraldNeon,
                    color2: const Color(0xFF66FFA6),
                    strokeWidth: widget.strokeWidth * 0.85,
                    progress: 0.65,
                  ),
                ),
              ),
              if (widget.size >= 24)
                Icon(
                  Icons.auto_awesome,
                  size: widget.size * 0.28,
                  color: goldMain,
                ),
            ],
          );
        },
      ),
    );

    if (widget.label != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          loader,
          const SizedBox(height: 14),
          Text(
            widget.label!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 3),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_outlined, size: 12, color: AppColors.emerald),
              SizedBox(width: 4),
              Text(
                'KaratFlow Admin Cloud & ERP Engine',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return loader;
  }
}

/// CAD Coordinate Viewport Bezel
class _CadCoordinateBezelPainter extends CustomPainter {
  _CadCoordinateBezelPainter({required this.cyanColor, required this.pulse});

  final Color cyanColor;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * math.pi / 180;
      final innerX = center.dx + (radius - 3.5) * math.cos(angle);
      final innerY = center.dy + (radius - 3.5) * math.sin(angle);
      final outerX = center.dx + radius * math.cos(angle);
      final outerY = center.dy + radius * math.sin(angle);

      final isMajorAxis = i % 2 == 0;
      tickPaint.color = isMajorAxis
          ? cyanColor.withValues(alpha: 0.6 + 0.4 * pulse)
          : cyanColor.withValues(alpha: 0.25);

      canvas.drawLine(
        Offset(innerX, innerY),
        Offset(outerX, outerY),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CadCoordinateBezelPainter oldDelegate) =>
      oldDelegate.pulse != pulse;
}

/// CAD Laser Orbit Arc
class _CadLaserOrbitPainter extends CustomPainter {
  _CadLaserOrbitPainter({
    required this.color1,
    required this.color2,
    required this.strokeWidth,
    required this.progress,
  });

  final Color color1;
  final Color color2;
  final double strokeWidth;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final sweepAngle = progress * 2 * math.pi;

    final gradient = SweepGradient(
      startAngle: 0.0,
      endAngle: sweepAngle,
      colors: [color1.withValues(alpha: 0.0), color1, color2],
      stops: const [0.0, 0.45, 1.0],
    );

    final arcPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0.0, sweepAngle, false, arcPaint);

    final headX = center.dx + radius * math.cos(sweepAngle);
    final headY = center.dy + radius * math.sin(sweepAngle);

    final laserGlow = Paint()
      ..color = color2.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(headX, headY), strokeWidth * 1.3, laserGlow);

    final coreNode = Paint()
      ..color = AppColors.pureWhite
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(headX, headY), strokeWidth * 0.7, coreNode);
  }

  @override
  bool shouldRepaint(covariant _CadLaserOrbitPainter oldDelegate) => true;
}

/// Workshop Gear Bezel with Industrial Notch Teeth
class _WorkshopGearBezelPainter extends CustomPainter {
  _WorkshopGearBezelPainter({required this.accentColor, required this.pulse});

  final Color accentColor;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final notchPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.25 + 0.3 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < 16; i++) {
      final angle = (i * 22.5) * math.pi / 180;
      final innerX = center.dx + (radius - 4) * math.cos(angle);
      final innerY = center.dy + (radius - 4) * math.sin(angle);
      final outerX = center.dx + (radius - 1) * math.cos(angle);
      final outerY = center.dy + (radius - 1) * math.sin(angle);

      canvas.drawLine(
        Offset(innerX, innerY),
        Offset(outerX, outerY),
        notchPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WorkshopGearBezelPainter oldDelegate) =>
      oldDelegate.pulse != pulse;
}

/// Workshop Molten Gold Flow Arc Painter
class _WorkshopMoltenFlowPainter extends CustomPainter {
  _WorkshopMoltenFlowPainter({
    required this.color1,
    required this.color2,
    required this.strokeWidth,
    required this.progress,
  });

  final Color color1;
  final Color color2;
  final double strokeWidth;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final sweepAngle = progress * 2 * math.pi;

    final gradient = SweepGradient(
      startAngle: 0.0,
      endAngle: sweepAngle,
      colors: [color1.withValues(alpha: 0.0), color1, color2],
      stops: const [0.0, 0.45, 1.0],
    );

    final arcPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0.0, sweepAngle, false, arcPaint);

    final headX = center.dx + radius * math.cos(sweepAngle);
    final headY = center.dy + radius * math.sin(sweepAngle);

    final glowPaint = Paint()
      ..color = color2.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(headX, headY), strokeWidth * 1.3, glowPaint);

    final corePaint = Paint()
      ..color = AppColors.pureWhite
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(headX, headY), strokeWidth * 0.7, corePaint);
  }

  @override
  bool shouldRepaint(covariant _WorkshopMoltenFlowPainter oldDelegate) => true;
}

/// Front Office Luxury Diamond Bezel
class _FrontOfficeDiamondBezelPainter extends CustomPainter {
  _FrontOfficeDiamondBezelPainter({
    required this.goldColor,
    required this.pulse,
  });

  final Color goldColor;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final dotPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final x = center.dx + (radius - 2.5) * math.cos(angle);
      final y = center.dy + (radius - 2.5) * math.sin(angle);

      final isCardinal = i % 3 == 0;
      dotPaint.color = isCardinal
          ? goldColor.withValues(alpha: 0.5 + 0.4 * pulse)
          : goldColor.withValues(alpha: 0.25);

      final dotSize = isCardinal ? 1.6 : 1.0;
      canvas.drawCircle(Offset(x, y), dotSize, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FrontOfficeDiamondBezelPainter oldDelegate) =>
      oldDelegate.pulse != pulse;
}

/// Front Office Luxury Orbit Painter
class _FrontOfficeLuxuryOrbitPainter extends CustomPainter {
  _FrontOfficeLuxuryOrbitPainter({
    required this.color1,
    required this.color2,
    required this.strokeWidth,
    required this.progress,
  });

  final Color color1;
  final Color color2;
  final double strokeWidth;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final sweepAngle = progress * 2 * math.pi;

    final gradient = SweepGradient(
      startAngle: 0.0,
      endAngle: sweepAngle,
      colors: [
        color1.withValues(alpha: 0.0),
        color1.withValues(alpha: 0.6),
        color2,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final arcPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0.0, sweepAngle, false, arcPaint);

    final headX = center.dx + radius * math.cos(sweepAngle);
    final headY = center.dy + radius * math.sin(sweepAngle);

    final glarePaint = Paint()
      ..color = color2.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(headX, headY), strokeWidth * 1.2, glarePaint);

    final diamondTip = Paint()
      ..color = AppColors.pureWhite
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(headX, headY), strokeWidth * 0.7, diamondTip);
  }

  @override
  bool shouldRepaint(covariant _FrontOfficeLuxuryOrbitPainter oldDelegate) =>
      true;
}

/// Custom KaratFlow Pull to Refresh wrapper with Theme support & Center 3D Progress Loader
class CommonRefreshIndicator extends StatefulWidget {
  const CommonRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.theme = IndicatorTheme.universal,
    this.showIndicator = true,
    this.enabled = true,
  });

  final Widget child;
  final Future<void> Function() onRefresh;
  final IndicatorTheme theme;
  final bool showIndicator;
  final bool enabled;

  @override
  State<CommonRefreshIndicator> createState() => _CommonRefreshIndicatorState();
}

class _CommonRefreshIndicatorState extends State<CommonRefreshIndicator> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() => _isRefreshing = true);
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Stack(
      children: [
        RefreshIndicator(
          color: Colors.transparent,
          backgroundColor: Colors.transparent,
          elevation: 0,
          strokeWidth: 0.01,
          onRefresh: _handleRefresh,
          child: widget.child,
        ),
        if (_isRefreshing)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: AppColors.paper.withValues(alpha: 0.82),
                child: Center(
                  child: CommonProgressIndicator(
                    theme: widget.theme,
                    label: switch (widget.theme) {
                      IndicatorTheme.workshop =>
                        'Synchronizing Workshop Live Benches & Batches...',
                      IndicatorTheme.frontOffice =>
                        'Synchronizing Vault Inventory & Client Orders...',
                      IndicatorTheme.cad =>
                        'Synchronizing 3D CAD Mesh & Solitaire Models...',
                      IndicatorTheme.universal =>
                        'Synchronizing KaratFlow Cloud & Factory ERP...',
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Full screen or section loading overlay with themed 3D KaratFlow production spinner
class CommonLoadingState extends StatelessWidget {
  const CommonLoadingState({
    super.key,
    this.theme = IndicatorTheme.universal,
    this.message,
  });

  final IndicatorTheme theme;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final effectiveMessage =
        message ??
        switch (theme) {
          IndicatorTheme.workshop =>
            'Syncing Live Workshop Benches & RFID Batches...',
          IndicatorTheme.frontOffice =>
            'Connecting to Jewelry Vault & Orders Pipeline...',
          IndicatorTheme.cad =>
            'Compiling 3D CAD Mesh & Solitaire Wireframes...',
          IndicatorTheme.universal => 'Synchronizing KaratFlow Cloud Engine...',
        };

    final subtitle = switch (theme) {
      IndicatorTheme.workshop =>
        '24K Molten Casting, CAD 3D & Bench Karigar Live Engine',
      IndicatorTheme.frontOffice =>
        'Solitaire Diamonds, Real-time Pricing & Dispatch Tracker',
      IndicatorTheme.cad =>
        'Rhino, MatrixGold STL Mesh & 3D Interactive Viewport',
      IndicatorTheme.universal =>
        'Real-time RFID, scale & bench synchronization',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: AppColors.outlineLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CommonProgressIndicator(size: 64, theme: theme),
              const SizedBox(height: 18),
              Text(
                effectiveMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

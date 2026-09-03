import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AnimatedEmptyStateWidget extends StatefulWidget {
  const AnimatedEmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accentColor,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? accentColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<AnimatedEmptyStateWidget> createState() =>
      _AnimatedEmptyStateWidgetState();
}

class _AnimatedEmptyStateWidgetState extends State<AnimatedEmptyStateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.1, end: 0.35).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.accentColor ?? AppColors.emerald;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: themeColor.withOpacity(0.08),
                      boxShadow: [
                        BoxShadow(
                          color: themeColor.withOpacity(_glowAnimation.value),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                      border: Border.all(
                        color: themeColor.withOpacity(0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 44,
                      color: themeColor,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.muted,
                height: 1.4,
              ),
            ),
            if (widget.actionLabel != null && widget.onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: widget.onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: AppColors.pureWhite,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(
                  widget.actionLabel!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

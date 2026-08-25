import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'common_app_bar.dart';
import 'common_button.dart';

/// A premium, beautiful "Coming Soon" screen widget for KaratFlow.
/// Can be used as a full screen route or embedded as a tab/widget.
class ComingSoonScreen extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final String? featureTag;
  final bool showAppBar;
  final VoidCallback? onBackPressed;

  const ComingSoonScreen({
    super.key,
    this.title = 'Feature Coming Soon',
    this.subtitle,
    this.icon = Icons.auto_awesome_rounded,
    this.featureTag = 'UNDER DEVELOPMENT',
    this.showAppBar = true,
    this.onBackPressed,
  });

  @override
  State<ComingSoonScreen> createState() => _ComingSoonScreenState();
}

class _ComingSoonScreenState extends State<ComingSoonScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isNotified = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.15, end: 0.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bodyContent = ComingSoonWidget(
      title: widget.title,
      subtitle: widget.subtitle,
      icon: widget.icon,
      featureTag: widget.featureTag,
      isNotified: _isNotified,
      onNotifyTap: () {
        setState(() {
          _isNotified = !_isNotified;
        });
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: _isNotified ? AppColors.emerald : AppColors.ink,
            content: Row(
              children: [
                Icon(
                  _isNotified
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_outlined,
                  color: AppColors.pureWhite,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isNotified
                        ? 'Awesome! You will be notified as soon as ${widget.title} goes live.'
                        : 'Notification reminder turned off.',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.pureWhite,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      scaleAnimation: _scaleAnimation,
      glowAnimation: _glowAnimation,
    );

    if (!widget.showAppBar) {
      return bodyContent;
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: CommonAppBar(
        showBrand: false,
        showBackButton: true,
        title: widget.title,
        leading: widget.onBackPressed != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: widget.onBackPressed,
              )
            : null,
      ),
      body: SafeArea(child: bodyContent),
    );
  }
}

/// Embedded version of the Coming Soon widget layout
class ComingSoonWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final String? featureTag;
  final bool isNotified;
  final VoidCallback? onNotifyTap;
  final Animation<double>? scaleAnimation;
  final Animation<double>? glowAnimation;

  const ComingSoonWidget({
    super.key,
    this.title = 'Feature Coming Soon',
    this.subtitle,
    this.icon = Icons.auto_awesome_rounded,
    this.featureTag = 'UNDER DEVELOPMENT',
    this.isNotified = false,
    this.onNotifyTap,
    this.scaleAnimation,
    this.glowAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final double opacityGlow = glowAnimation?.value ?? 0.25;
    final double scale = scaleAnimation?.value ?? 1.0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space24,
          vertical: AppDimensions.space32,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Glowing Animated Hero Illustration
            AnimatedBuilder(
              animation: scaleAnimation ?? const AlwaysStoppedAnimation(1.0),
              builder: (context, child) {
                return Transform.scale(
                  scale: scale,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Glowing Aura
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.gold.withValues(alpha: opacityGlow),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.emerald.withValues(
                                alpha: opacityGlow * 0.8,
                              ),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),

                      // Glass Container Badge
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.paper,
                              AppColors.goldLight,
                              AppColors.sage,
                            ],
                          ),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.4),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [AppColors.emeraldDark, AppColors.gold],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: Icon(icon, size: 48, color: Colors.white),
                          ),
                        ),
                      ),

                      // Sparkle Pill Badge
                      Positioned(
                        bottom: 0,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldDark,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusFull,
                            ),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.6),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: AppColors.gold,
                                size: 12,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'SOON',
                                style: TextStyle(
                                  color: AppColors.pureWhite,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 9,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            // Feature Tag Pill
            if (featureTag != null && featureTag!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.emeraldLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(
                    color: AppColors.emerald.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  featureTag!.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.emeraldDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Main Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: AppColors.ink,
                height: 1.25,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 10),

            // Subtitle Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                subtitle ??
                    'We are crafting something extraordinary for your KaratFlow workflow. Stay tuned for the upcoming launch!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.paper,
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
              child: Column(
                children: [
                  CommonButton.primary(
                    label: isNotified
                        ? 'Notification Enabled ✓'
                        : 'Notify Me When Ready',
                    icon: isNotified
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    onPressed: onNotifyTap,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '✦ Crafting perfection for jewelry workshops ✦',
                    style: TextStyle(
                      color: AppColors.subtle,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

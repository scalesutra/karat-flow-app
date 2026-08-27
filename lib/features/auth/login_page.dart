import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/common_button.dart';
import '../../core/widgets/common_progress_indicator.dart';
import '../../core/widgets/common_snackbar.dart';
import '../../core/widgets/common_text_field.dart';
import '../../domain/models.dart';
import '../../routes/app_pages.dart';
import '../../routes/app_routes.dart';
import 'bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    context.read<AuthBloc>().add(
      AuthLoginSubmitted(username: email, password: password),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is AuthAuthenticated) {
            final roleController = Get.isRegistered<AppRoleController>()
                ? Get.find<AppRoleController>()
                : Get.put(AppRoleController(), permanent: true);
            final targetRole = AppRole.fromRoleString(state.role);
            roleController.setRole(targetRole);
            if (!context.mounted) return;

            CommonSnackbar.success(
              context,
              title: 'Welcome Back',
              message: 'Logged in as ${state.userName} (${targetRole.label})',
            );
            Get.offAllNamed(Routes.shell);
          } else if (state is AuthError) {
            CommonSnackbar.error(
              context,
              title: 'Authentication Failed',
              message: state.message,
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Stack(
            children: [
              // ── 0. Luxury Ambient Gradient Background ─────────────────────
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFFAF7F0),
                        Color(0xFFF3EDDF),
                        Color(0xFFE8DFC9),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Top Right Emerald Ambient Soft Glow
              Positioned(
                top: -80,
                right: -80,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.emerald.withValues(alpha: 0.12),
                  ),
                ),
              ),

              // Bottom Left Gold Ambient Soft Glow
              Positioned(
                bottom: -100,
                left: -100,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold.withValues(alpha: 0.15),
                  ),
                ),
              ),

              // ── Main Content Container ─────────────────────────────────────
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── 1. Luxury Brand Hero Emblem ───────────────────────
                          Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer Glow Aura Ring
                                Container(
                                  width: 108,
                                  height: 108,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        AppColors.gold.withValues(alpha: 0.4),
                                        AppColors.emerald.withValues(
                                          alpha: 0.15,
                                        ),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),

                                // Main Metallic Emblem Badge
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFFE899),
                                        Color(0xFFD4AF37),
                                        Color(0xFF0D6252),
                                        Color(0xFF083D33),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(
                                      color: const Color(0xFFFFF7DB),
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.emeraldDark.withValues(
                                          alpha: 0.35,
                                        ),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Main Diamond Icon
                                      const Icon(
                                        Icons.diamond_rounded,
                                        size: 46,
                                        color: Colors.white,
                                      ),
                                      // Top Right Sparkle Star
                                      const Positioned(
                                        top: 14,
                                        right: 14,
                                        child: Icon(
                                          Icons.auto_awesome_rounded,
                                          size: 16,
                                          color: Color(0xFFFFE899),
                                        ),
                                      ),
                                      // Bottom Left Small Sparkle Accent
                                      const Positioned(
                                        bottom: 16,
                                        left: 16,
                                        child: Icon(
                                          Icons.auto_awesome_rounded,
                                          size: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          Center(
                            child: Text(
                              'KARATFLOW',
                              style: GoogleFonts.cinzel(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 5.0,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),

                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.goldLight,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                'ENTERPRISE JEWELLERY MANUFACTURING ERP',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.goldDark,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ── 2. Login Card with Gradient Accent Bar ──────────
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.paper,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.ink.withValues(alpha: 0.08),
                                  blurRadius: 28,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                // Metallic Gold to Emerald Accent Line
                                Container(
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.gold,
                                        AppColors.emerald,
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(28),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    AppColors.emeraldLight,
                                                    AppColors.goldLight,
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: AppColors.gold
                                                      .withValues(alpha: 0.3),
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.shield_outlined,
                                                color: AppColors.emeraldDark,
                                                size: 22,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Sign In to Workspace',
                                                    style:
                                                        GoogleFonts.plusJakartaSans(
                                                          fontSize: 17,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color: AppColors.ink,
                                                        ),
                                                  ),
                                                  Text(
                                                    'Enter authorized credentials to proceed',
                                                    style:
                                                        GoogleFonts.plusJakartaSans(
                                                          fontSize: 12,
                                                          color:
                                                              AppColors.muted,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 24),

                                        // Email Field
                                        CommonTextField(
                                          controller: _emailController,
                                          label: 'Email Address *',
                                          hintText: 'e.g. admin@karratflow.com',
                                          prefixIcon: Icons.email_outlined,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          validator: (val) {
                                            if (val == null ||
                                                val.trim().isEmpty) {
                                              return 'Please enter your email';
                                            }
                                            if (!val.contains('@')) {
                                              return 'Please enter a valid email address';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 18),

                                        // Password Field
                                        Text(
                                          'Password *',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _passwordController,
                                          obscureText: _obscurePassword,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.ink,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: '••••••••',
                                            prefixIcon: const Icon(
                                              Icons.lock_outline,
                                              color: AppColors.muted,
                                              size: 20,
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons.visibility_outlined
                                                    : Icons
                                                          .visibility_off_outlined,
                                                color: AppColors.muted,
                                                size: 20,
                                              ),
                                              onPressed: () => setState(
                                                () => _obscurePassword =
                                                    !_obscurePassword,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: AppColors.canvas
                                                .withValues(alpha: 0.5),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 14,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: AppColors.outline,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: AppColors.outline,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: AppColors.gold,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                          validator: (val) {
                                            if (val == null ||
                                                val.trim().isEmpty) {
                                              return 'Please enter your password';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 26),

                                        // Login Submit Button
                                        if (isLoading)
                                          const Center(
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 8,
                                              ),
                                              child: CommonProgressIndicator(
                                                theme: IndicatorTheme.universal,
                                                size: 54,
                                                label:
                                                    'Authenticating with live server...',
                                              ),
                                            ),
                                          )
                                        else
                                          CommonButton.primary(
                                            height: 48,
                                            label: 'Sign In to Workspace',
                                            icon: Icons.arrow_forward_rounded,
                                            onPressed: _submitLogin,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

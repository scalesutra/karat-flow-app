import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jewellery_ops_mobile/routes/app_pages.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/app_data_sync_service.dart';
import '../../core/widgets/common_button.dart';
import '../../core/widgets/common_card.dart';
import '../../core/widgets/common_progress_indicator.dart';
import '../../core/widgets/common_snackbar.dart';
import '../../core/widgets/common_text_field.dart';
import '../../domain/models.dart';
import '../../data/demo_store.dart';
import '../../routes/app_routes.dart';
import 'bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'admin@karratflow.com');
  final _passwordController = TextEditingController(text: 'Admin@123');
  bool _obscurePassword = true;
  bool _isSyncingApiData = false;

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

  void _quickFill(String email, String password) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is AuthAuthenticated) {
            // Update role in AppRoleController
            final roleController = Get.find<AppRoleController>();
            final targetRole = switch (state.role.toUpperCase()) {
              'ADMIN' => AppRole.admin,
              'FRONTIER' => AppRole.frontOffice,
              'FRONT_OFFICE' => AppRole.frontOffice,
              'PRODUCTION_MANAGER' => AppRole.processManager,
              'RAW_DESIGNER' => AppRole.cadDesigner,
              'THREE_D_DESIGNER' => AppRole.cadDesigner,
              'CAD_DESIGNER' => AppRole.cadDesigner,
              'OTHER_EMPLOYEE' => AppRole.processManager,
              _ => AppRole.admin,
            };
            roleController.setRole(targetRole);

            // All protected APIs must run after the login token is saved.
            setState(() => _isSyncingApiData = true);
            await AppDataSyncService.syncForRole(
              Get.find<DemoStore>(),
              targetRole,
            );

            if (!context.mounted) return;

            CommonSnackbar.success(
              context,
              title: 'Login Successful',
              message: 'Welcome back, ${state.userName}!',
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
          final isLoading = state is AuthLoading || _isSyncingApiData;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── 1. Luxury Brand Header ───────────────────────
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [
                                Color(0xFFFFDF7A),
                                Color(0xFFD4AF37),
                                Color(0xFF0D6252),
                              ],
                              stops: [0.2, 0.6, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.35),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.diamond_outlined,
                            size: 42,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Center(
                        child: Text(
                          'KARATFLOW',
                          style: GoogleFonts.cinzel(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4.0,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      Center(
                        child: Text(
                          'Enterprise Jewellery Manufacturing ERP',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── 2. Login Card ────────────────────────────────
                      CommonCard(
                        padding: const EdgeInsets.all(24),
                        borderRadius: BorderRadius.circular(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sign In to Your Workspace',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Enter authorized credentials to access factory control',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Email Field
                              CommonTextField(
                                controller: _emailController,
                                label: 'Email Address *',
                                hintText: 'admin@karratflow.com',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!val.contains('@')) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

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
                                          : Icons.visibility_off_outlined,
                                      color: AppColors.muted,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.paper,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.outline,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.outline,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.gold,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Login Submit Button
                              if (isLoading)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
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
                                  label: 'Sign In to Workspace',
                                  icon: Icons.login_rounded,
                                  onPressed: _submitLogin,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── 3. Quick-Fill Testing Helper Chips ───────────
                      CommonCard(
                        backgroundColor: AppColors.paper,
                        padding: const EdgeInsets.all(16),
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.flash_on,
                                  size: 16,
                                  color: AppColors.gold,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Quick Fill Credentials',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                ActionChip(
                                  avatar: const Icon(
                                    Icons.admin_panel_settings,
                                    size: 14,
                                    color: AppColors.emeraldDark,
                                  ),
                                  label: const Text(
                                    '1. Admin (admin@karratflow.com)',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: AppColors.emeraldLight,
                                  onPressed: () => _quickFill(
                                    'admin@karratflow.com',
                                    'Admin@123',
                                  ),
                                ),
                                ActionChip(
                                  avatar: const Icon(
                                    Icons.storefront_outlined,
                                    size: 14,
                                    color: AppColors.goldDark,
                                  ),
                                  label: const Text(
                                    '2. Frontier / Front Office',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: AppColors.goldLight,
                                  onPressed: () => _quickFill(
                                    'frontier@karratflow.com',
                                    'Frontier@123',
                                  ),
                                ),
                                ActionChip(
                                  avatar: const Icon(
                                    Icons.precision_manufacturing_outlined,
                                    size: 14,
                                    color: AppColors.emeraldDark,
                                  ),
                                  label: const Text(
                                    '3. Production Manager',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: AppColors.sage,
                                  onPressed: () => _quickFill(
                                    'pm@karratflow.com',
                                    'Manager@123',
                                  ),
                                ),
                                ActionChip(
                                  avatar: const Icon(
                                    Icons.draw_outlined,
                                    size: 14,
                                    color: AppColors.goldDark,
                                  ),
                                  label: const Text(
                                    '4. Raw Designer (Sketcher)',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: AppColors.goldLight,
                                  onPressed: () => _quickFill(
                                    'sketcher@karratflow.com',
                                    'Sketcher@123',
                                  ),
                                ),
                                ActionChip(
                                  avatar: const Icon(
                                    Icons.view_in_ar_outlined,
                                    size: 14,
                                    color: AppColors.emerald,
                                  ),
                                  label: const Text(
                                    '5. 3D CAD Designer',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: AppColors.sage,
                                  onPressed: () => _quickFill(
                                    'cad@karratflow.com',
                                    'Designer@123',
                                  ),
                                ),
                                ActionChip(
                                  avatar: const Icon(
                                    Icons.engineering,
                                    size: 14,
                                    color: AppColors.goldDark,
                                  ),
                                  label: const Text(
                                    '6. Workshop Artisan',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: AppColors.goldLight,
                                  onPressed: () => _quickFill(
                                    'artisan@karratflow.com',
                                    'Artisan@123',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../localization/localization.dart';
import 'common_snackbar.dart';

abstract final class CommonLanguagePicker {
  static void show(BuildContext context) {
    final currentLocale = Get.locale ?? const Locale('en', 'US');

    final languages = [
      {
        'code': 'en',
        'country': 'US',
        'title': 'English',
        'native': 'English (Default)',
        'flag': '🇬🇧',
      },
      {
        'code': 'hi',
        'country': 'IN',
        'title': 'Hindi',
        'native': 'हिंदी (Indian Floor)',
        'flag': '🇮🇳',
      },
      {
        'code': 'gu',
        'country': 'IN',
        'title': 'Gujarati',
        'native': 'ગુજરાતી (Surat/Rajkot Diamond Hub)',
        'flag': '🇮🇳',
      },
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.goldLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.translate_rounded,
                      color: AppColors.goldDark,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.selectLanguage.tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.ink,
                        ),
                      ),
                      const Text(
                        'Instant multilingual interface switching',
                        style: TextStyle(color: AppColors.muted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (final lang in languages) ...[
                Builder(
                  builder: (context) {
                    final isSelected =
                        currentLocale.languageCode == lang['code'];
                    return InkWell(
                      onTap: () {
                        final newLocale = Locale(
                          lang['code']!,
                          lang['country']!,
                        );
                        Get.updateLocale(newLocale);
                        Navigator.pop(ctx);
                        CommonSnackbar.success(
                          context,
                          title: 'Language Updated',
                          message:
                              'Switched to ${lang['title']} (${lang['native']}).',
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.emeraldLight.withValues(alpha: 0.5)
                              : AppColors.canvas,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.emerald
                                : AppColors.outline,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              lang['flag']!,
                              style: const TextStyle(fontSize: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang['title']!,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: isSelected
                                          ? AppColors.emeraldDark
                                          : AppColors.ink,
                                    ),
                                  ),
                                  Text(
                                    lang['native']!,
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.emerald,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

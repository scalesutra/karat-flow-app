import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

enum _TextVariant {
  headlineLarge,
  headlineMedium,
  headlineSmall,
  titleLarge,
  titleMedium,
  titleSmall,
  bodyLarge,
  bodyMedium,
  bodySmall,
  labelLarge,
  labelMedium,
  labelSmall,
}

class CommonText extends StatelessWidget {
  const CommonText(
    this.text, {
    super.key,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.letterSpacing,
    this.height,
    this.decoration,
  }) : _variant = _TextVariant.bodyMedium;

  const CommonText.headlineLarge(
    this.text, {
    super.key,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.letterSpacing,
    this.height,
    this.decoration,
  }) : _variant = _TextVariant.headlineLarge;

  const CommonText.headlineMedium(
    this.text, {
    super.key,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.letterSpacing,
    this.height,
    this.decoration,
  }) : _variant = _TextVariant.headlineMedium;

  const CommonText.headlineSmall(
    this.text, {
    super.key,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.letterSpacing,
    this.height,
    this.decoration,
  }) : _variant = _TextVariant.headlineSmall;

  const CommonText.titleLarge(
    this.text, {
    super.key,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.letterSpacing,
    this.height,
    this.decoration,
  }) : _variant = _TextVariant.titleLarge;

  const CommonText.titleMedium(
    this.text, {
    super.key,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.letterSpacing,
    this.height,
    this.decoration,
  }) : _variant = _TextVariant.titleMedium;

  const CommonText.titleSmall(
    this.text, {
    super.key,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.letterSpacing,
    this.height,
    this.decoration,
  }) : _variant = _TextVariant.titleSmall;

  const CommonText.bodyLarge(
    this.text, {
    super.key,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.letterSpacing,
    this.height,
    this.decoration,
  }) : _variant = _TextVariant.bodyLarge;

  const CommonText.bodyMedium(
    this.text, {
    super.key,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.letterSpacing,
    this.height,
    this.decoration,
  }) : _variant = _TextVariant.bodyMedium;

  const CommonText.bodySmall(
    this.text, {
    super.key,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.letterSpacing,
    this.height,
    this.decoration,
  }) : _variant = _TextVariant.bodySmall;

  const CommonText.labelLarge(
    this.text, {
    super.key,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.letterSpacing,
    this.height,
    this.decoration,
  }) : _variant = _TextVariant.labelLarge;

  const CommonText.labelMedium(
    this.text, {
    super.key,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.letterSpacing,
    this.height,
    this.decoration,
  }) : _variant = _TextVariant.labelMedium;

  const CommonText.labelSmall(
    this.text, {
    super.key,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.letterSpacing,
    this.height,
    this.decoration,
  }) : _variant = _TextVariant.labelSmall;

  final String text;
  final _TextVariant _variant;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? letterSpacing;
  final double? height;
  final TextDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    TextStyle style = switch (_variant) {
      _TextVariant.headlineLarge => GoogleFonts.outfit(
          fontSize: fontSize ?? 32,
          fontWeight: fontWeight ?? FontWeight.w700,
          letterSpacing: letterSpacing ?? -0.8,
          height: height ?? 1.1,
          color: color ?? AppColors.ink,
          decoration: decoration,
        ),
      _TextVariant.headlineMedium => GoogleFonts.outfit(
          fontSize: fontSize ?? 26,
          fontWeight: fontWeight ?? FontWeight.w700,
          letterSpacing: letterSpacing ?? -0.5,
          height: height ?? 1.15,
          color: color ?? AppColors.ink,
          decoration: decoration,
        ),
      _TextVariant.headlineSmall => GoogleFonts.outfit(
          fontSize: fontSize ?? 22,
          fontWeight: fontWeight ?? FontWeight.w700,
          letterSpacing: letterSpacing ?? -0.3,
          height: height ?? 1.2,
          color: color ?? AppColors.ink,
          decoration: decoration,
        ),
      _TextVariant.titleLarge => GoogleFonts.outfit(
          fontSize: fontSize ?? 20,
          fontWeight: fontWeight ?? FontWeight.w700,
          letterSpacing: letterSpacing,
          height: height,
          color: color ?? AppColors.ink,
          decoration: decoration,
        ),
      _TextVariant.titleMedium => GoogleFonts.outfit(
          fontSize: fontSize ?? 16,
          fontWeight: fontWeight ?? FontWeight.w700,
          letterSpacing: letterSpacing,
          height: height,
          color: color ?? AppColors.ink,
          decoration: decoration,
        ),
      _TextVariant.titleSmall => GoogleFonts.outfit(
          fontSize: fontSize ?? 14,
          fontWeight: fontWeight ?? FontWeight.w600,
          letterSpacing: letterSpacing,
          height: height,
          color: color ?? AppColors.ink,
          decoration: decoration,
        ),
      _TextVariant.bodyLarge => GoogleFonts.inter(
          fontSize: fontSize ?? 16,
          fontWeight: fontWeight ?? FontWeight.w400,
          letterSpacing: letterSpacing,
          height: height ?? 1.45,
          color: color ?? AppColors.ink,
          decoration: decoration,
        ),
      _TextVariant.bodyMedium => GoogleFonts.inter(
          fontSize: fontSize ?? 14,
          fontWeight: fontWeight ?? FontWeight.w400,
          letterSpacing: letterSpacing,
          height: height ?? 1.45,
          color: color ?? AppColors.ink,
          decoration: decoration,
        ),
      _TextVariant.bodySmall => GoogleFonts.inter(
          fontSize: fontSize ?? 12,
          fontWeight: fontWeight ?? FontWeight.w400,
          letterSpacing: letterSpacing,
          height: height ?? 1.4,
          color: color ?? AppColors.muted,
          decoration: decoration,
        ),
      _TextVariant.labelLarge => GoogleFonts.inter(
          fontSize: fontSize ?? 14,
          fontWeight: fontWeight ?? FontWeight.w700,
          letterSpacing: letterSpacing,
          height: height,
          color: color ?? AppColors.ink,
          decoration: decoration,
        ),
      _TextVariant.labelMedium => GoogleFonts.inter(
          fontSize: fontSize ?? 12,
          fontWeight: fontWeight ?? FontWeight.w700,
          letterSpacing: letterSpacing,
          height: height,
          color: color ?? AppColors.ink,
          decoration: decoration,
        ),
      _TextVariant.labelSmall => GoogleFonts.inter(
          fontSize: fontSize ?? 11,
          fontWeight: fontWeight ?? FontWeight.w600,
          letterSpacing: letterSpacing ?? 0.5,
          height: height,
          color: color ?? AppColors.muted,
          decoration: decoration,
        ),
    };

    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

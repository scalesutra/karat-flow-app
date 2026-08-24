import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class CommonTextField extends StatelessWidget {
  const CommonTextField({
    super.key,
    this.controller,
    this.initialValue,
    String? hintText,
    String? hint,
    this.labelText,
    String? label,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.minLines,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.obscureText = false,
    this.onTap,
    this.focusNode,
  })  : hintText = hintText ?? hint,
        _effectiveLabel = labelText ?? label,
        _isSearch = false;

  const CommonTextField.search({
    super.key,
    this.controller,
    this.hintText = 'Search orders, lot, people...',
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.autofocus = false,
    this.focusNode,
  })  : initialValue = null,
        labelText = null,
        _effectiveLabel = null,
        errorText = null,
        prefixIcon = Icons.search,
        suffixIcon = null,
        validator = null,
        keyboardType = TextInputType.text,
        inputFormatters = null,
        textCapitalization = TextCapitalization.none,
        maxLines = 1,
        minLines = null,
        readOnly = false,
        enabled = true,
        obscureText = false,
        _isSearch = true;

  final TextEditingController? controller;
  final String? initialValue;
  final String? hintText;
  final String? labelText;
  final String? _effectiveLabel;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final int? minLines;
  final bool readOnly;
  final bool enabled;
  final bool autofocus;
  final bool obscureText;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool _isSearch;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      focusNode: focusNode,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      minLines: minLines,
      readOnly: readOnly,
      enabled: enabled,
      autofocus: autofocus,
      obscureText: obscureText,
      onTap: onTap,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: _effectiveLabel,
        errorText: errorText,
        hintStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.muted,
        ),
        filled: true,
        fillColor: _isSearch ? AppColors.paper : AppColors.paper,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 20, color: AppColors.muted)
            : null,
        suffixIcon: suffixIcon,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines > 1 ? 16 : 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            _isSearch ? AppDimensions.radiusFull : AppDimensions.radiusMedium,
          ),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            _isSearch ? AppDimensions.radiusFull : AppDimensions.radiusMedium,
          ),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            _isSearch ? AppDimensions.radiusFull : AppDimensions.radiusMedium,
          ),
          borderSide: const BorderSide(color: AppColors.emerald, width: 2),
        ),
      ),
    );
  }
}

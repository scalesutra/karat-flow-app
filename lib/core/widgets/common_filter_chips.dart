import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class CommonFilterChips<T> extends StatelessWidget {
  const CommonFilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.labelBuilder,
    this.iconBuilder,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppDimensions.space20,
    ),
  });

  final List<T> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final String Function(T) labelBuilder;
  final IconData? Function(T)? iconBuilder;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: options.map((option) {
          final isSelected = option == selected;
          final icon = iconBuilder?.call(option);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: icon != null
                  ? Icon(
                      icon,
                      size: 16,
                      color: isSelected ? AppColors.pureWhite : AppColors.muted,
                    )
                  : null,
              label: Text(labelBuilder(option)),
              selected: isSelected,
              onSelected: (val) {
                if (val) onSelected(option);
              },
              selectedColor: AppColors.emerald,
              backgroundColor: AppColors.paper,
              disabledColor: AppColors.canvas,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.pureWhite : AppColors.ink,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                side: BorderSide(
                  color: isSelected ? AppColors.emerald : AppColors.outline,
                ),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          );
        }).toList(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:jewellery_ops_mobile/core/constants/app_colors.dart';
import 'package:jewellery_ops_mobile/data/models/api_models.dart';

enum AttributePickerType { shape, color }

/// Premium Searchable Bottom Sheet for selecting Stone Shapes and Colors
class SearchableAttributePickerSheet extends StatefulWidget {
  const SearchableAttributePickerSheet({
    super.key,
    required this.type,
    required this.attributes,
    this.selectedName,
  });

  final AttributePickerType type;
  final List<ApiMasterAttribute> attributes;
  final String? selectedName;

  static Future<ApiMasterAttribute?> show(
    BuildContext context, {
    required AttributePickerType type,
    required List<ApiMasterAttribute> attributes,
    String? selectedName,
  }) {
    return showModalBottomSheet<ApiMasterAttribute>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SearchableAttributePickerSheet(
        type: type,
        attributes: attributes,
        selectedName: selectedName,
      ),
    );
  }

  @override
  State<SearchableAttributePickerSheet> createState() =>
      _SearchableAttributePickerSheetState();
}

class _SearchableAttributePickerSheetState
    extends State<SearchableAttributePickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _resolveColor(ApiMasterAttribute attr) {
    if (attr.hexCode.isNotEmpty) {
      try {
        final hex = attr.hexCode.replaceAll('#', '').trim();
        if (hex.length == 6) {
          return Color(int.parse('FF$hex', radix: 16));
        } else if (hex.length == 8) {
          return Color(int.parse(hex, radix: 16));
        }
      } catch (_) {}
    }
    final nameLower = attr.name.toLowerCase();
    if (nameLower.contains('white')) return const Color(0xFFF8F9FA);
    if (nameLower.contains('pink')) return const Color(0xFFF48FB1);
    if (nameLower.contains('green') || nameLower.contains('emerald')) {
      return const Color(0xFF4CAF50);
    }
    if (nameLower.contains('yellow') || nameLower.contains('gold')) {
      return const Color(0xFFFFD54F);
    }
    if (nameLower.contains('blue') || nameLower.contains('sapphire')) {
      return const Color(0xFF42A5F5);
    }
    if (nameLower.contains('red') || nameLower.contains('ruby')) {
      return const Color(0xFFE53935);
    }
    if (nameLower.contains('black')) return const Color(0xFF212121);
    if (nameLower.contains('purple') || nameLower.contains('amethyst')) {
      return const Color(0xFFAB47BC);
    }
    return AppColors.muted;
  }

  @override
  Widget build(BuildContext context) {
    final isShape = widget.type == AttributePickerType.shape;
    final title = isShape ? 'Select Stone Shape' : 'Select Stone Color';
    final subtitle = isShape
        ? 'Choose classic cut or fancy shape'
        : 'Choose authenticated shade or tint';

    final filtered = widget.attributes.where((attr) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return attr.name.toLowerCase().contains(q) ||
          attr.code.toLowerCase().contains(q) ||
          attr.description.toLowerCase().contains(q);
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isShape
                        ? Icons.diamond_outlined
                        : Icons.palette_outlined,
                    size: 20,
                    color: AppColors.emerald,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.muted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Live Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _query = val.trim()),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
              decoration: InputDecoration(
                hintText: isShape ? 'Search shape by name or code...' : 'Search color by name or code...',
                hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.subtle),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: AppColors.muted,
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.muted),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.paper,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.outlineLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.outlineLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.emerald, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Count indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filtered.length} ${isShape ? 'shapes' : 'colors'} available',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
                if (_query.isNotEmpty)
                  InkWell(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                    child: const Text(
                      'Clear Filter',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emerald,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // List
          Flexible(
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isShape ? Icons.diamond_outlined : Icons.palette_outlined,
                          size: 40,
                          color: AppColors.muted.withOpacity(0.5),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _query.isNotEmpty
                              ? 'No ${isShape ? 'shapes' : 'colors'} match "$_query"'
                              : 'No items loaded from server',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final item = filtered[idx];
                      final isSelected = widget.selectedName != null &&
                          widget.selectedName!.trim().toLowerCase() ==
                              item.name.trim().toLowerCase();

                      return InkWell(
                        onTap: () => Navigator.of(context).pop(item),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.emerald.withOpacity(0.08)
                                : AppColors.paper,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.emerald
                                  : AppColors.outlineLight,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Visual Swatch or Shape Icon
                              if (isShape) ...[
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.emerald.withOpacity(0.18)
                                        : AppColors.canvas,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.diamond_rounded,
                                    size: 18,
                                    color: isSelected
                                        ? AppColors.emerald
                                        : AppColors.muted,
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: _resolveColor(item),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.outline,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(width: 12),

                              // Name & Description / Code
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          item.name,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w700,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                        if (item.code.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 1.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.canvas,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item.code,
                                              style: const TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.muted,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (item.description.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        item.description,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: AppColors.muted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Selected Checkmark
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: AppColors.emerald,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 14,
                                    color: AppColors.pureWhite,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jewellery_ops_mobile/core/constants/app_colors.dart';
import 'package:jewellery_ops_mobile/data/models/api_models.dart';
import 'package:jewellery_ops_mobile/data/repositories/karatflow_api_repository.dart';

/// Searchable Bottom Sheet Picker for Workshop Craftsmen (Karigars)
/// Supports local instant filtering + live backend search API with debouncing.
class SearchableCraftsmanPickerSheet extends StatefulWidget {
  const SearchableCraftsmanPickerSheet({
    super.key,
    required this.initialCraftsmen,
    this.selectedCraftsmanId,
  });

  final List<ApiEmployee> initialCraftsmen;
  final String? selectedCraftsmanId;

  static Future<ApiEmployee?> show(
    BuildContext context, {
    required List<ApiEmployee> initialCraftsmen,
    String? selectedCraftsmanId,
  }) {
    return showModalBottomSheet<ApiEmployee>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SearchableCraftsmanPickerSheet(
        initialCraftsmen: initialCraftsmen,
        selectedCraftsmanId: selectedCraftsmanId,
      ),
    );
  }

  @override
  State<SearchableCraftsmanPickerSheet> createState() =>
      _SearchableCraftsmanPickerSheetState();
}

class _SearchableCraftsmanPickerSheetState
    extends State<SearchableCraftsmanPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  final KaratFlowApiRepository _repo = KaratFlowApiRepository();
  Timer? _debounceTimer;

  late List<ApiEmployee> _displayedCraftsmen;
  bool _isSearchingApi = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _displayedCraftsmen = List.from(widget.initialCraftsmen);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value.trim());
    _debounceTimer?.cancel();

    // 1. Instant local filter
    final lower = value.trim().toLowerCase();
    final localMatches = widget.initialCraftsmen.where((c) {
      return c.name.toLowerCase().contains(lower) ||
          c.role.toLowerCase().contains(lower) ||
          c.phone.toLowerCase().contains(lower) ||
          c.specialty.toLowerCase().contains(lower);
    }).toList();

    setState(() {
      _displayedCraftsmen = localMatches;
    });

    // 2. Debounced API search for server-side lookup
    if (value.trim().length >= 2) {
      _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
        if (!mounted) return;
        setState(() => _isSearchingApi = true);
        try {
          final serverEmployees = await _repo.getCraftsmen(search: value.trim());
          if (!mounted) return;
          final karigars = serverEmployees.where((e) {
            final r = e.role.toUpperCase();
            return r.contains('CRAFTSMAN') ||
                r.contains('ARTISAN') ||
                r.contains('WORKER') ||
                r.contains('GOLDSMITH') ||
                r.contains('SETTER') ||
                r.contains('POLISHER') ||
                r.contains('FILER');
          }).toList();

          final merged = <String, ApiEmployee>{
            for (final c in _displayedCraftsmen) c.id: c,
            for (final c in (karigars.isNotEmpty ? karigars : serverEmployees))
              c.id: c,
          }.values.toList();

          setState(() {
            _displayedCraftsmen = merged;
            _isSearchingApi = false;
          });
        } catch (_) {
          if (mounted) setState(() => _isSearchingApi = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 18,
                      color: AppColors.emerald,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Select Worker',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              autofocus: false,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search worker by name, role, phone...',
                hintStyle: const TextStyle(
                  fontSize: 12,
                  color: AppColors.subtle,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 16,
                  color: AppColors.muted,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 34,
                  minHeight: 34,
                ),
                suffixIcon: _isSearchingApi
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _query.isNotEmpty
                    ? IconButton(
                        iconSize: 16,
                        icon: const Icon(
                          Icons.cancel_rounded,
                          color: AppColors.muted,
                        ),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.paper,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
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
                  borderSide: const BorderSide(
                    color: AppColors.emerald,
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),

          const Divider(height: 1, color: AppColors.outlineLight),

          // Craftsmen List
          Expanded(
            child: _displayedCraftsmen.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person_search_rounded,
                            size: 32,
                            color: AppColors.muted,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _query.isEmpty
                                ? 'No workers available'
                                : 'No worker matching "$_query"',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: _displayedCraftsmen.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final craftsman = _displayedCraftsmen[index];
                      final isSelected =
                          widget.selectedCraftsmanId == craftsman.id;

                      final initials = craftsman.name.trim().isNotEmpty
                          ? craftsman.name
                              .trim()
                              .split(' ')
                              .map((w) => w.isNotEmpty ? w[0] : '')
                              .take(2)
                              .join()
                              .toUpperCase()
                          : 'K';

                      return InkWell(
                        onTap: () => Navigator.of(context).pop(craftsman),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.emerald.withValues(alpha: 0.08)
                                : AppColors.paper,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.emerald.withValues(alpha: 0.4)
                                  : AppColors.outlineLight,
                              width: isSelected ? 1.2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Avatar circle
                              Container(
                                width: 30,
                                height: 30,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.emerald
                                      : AppColors.emerald.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  initials,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? AppColors.pureWhite
                                        : AppColors.emerald,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      craftsman.name,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? AppColors.emerald
                                            : AppColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.canvas,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                              color: AppColors.outlineLight,
                                            ),
                                          ),
                                          child: Text(
                                            craftsman.role,
                                            style: const TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.muted,
                                            ),
                                          ),
                                        ),
                                        if (craftsman.phone.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            craftsman.phone,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.subtle,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.emerald,
                                  size: 18,
                                )
                              else
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.subtle,
                                  size: 18,
                                ),
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

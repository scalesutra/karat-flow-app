import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/localization.dart';
import '../../core/widgets/widgets.dart';

class CadWeightCalculator extends StatefulWidget {
  const CadWeightCalculator({
    super.key,
    required this.initialVolume,
    required this.onCalculate,
  });

  final double initialVolume;
  final Function(double volume, double weightGrams, String metalType)
  onCalculate;

  @override
  State<CadWeightCalculator> createState() => _CadWeightCalculatorState();
}

class _CadWeightCalculatorState extends State<CadWeightCalculator> {
  late TextEditingController _volumeController;
  String _selectedMetal = '22K Yellow Gold';
  double _calculatedWeight = 0.0;

  // Density values in g/mm³ (g/cm³ / 1000)
  final Map<String, double> _densities = {
    '24K Pure Gold': 0.01932, // g/mm³
    '22K Yellow Gold': 0.01750,
    '18K Yellow Gold': 0.01550,
    '18K White Gold': 0.01600,
    '14K Gold': 0.01310,
    '925 Sterling Silver': 0.01040,
    'Platinum 950': 0.02145,
  };

  @override
  void initState() {
    super.initState();
    _volumeController = TextEditingController(
      text: widget.initialVolume > 0
          ? widget.initialVolume.toStringAsFixed(1)
          : '',
    );
    if (widget.initialVolume > 0) {
      _calculate();
    }
  }

  @override
  void dispose() {
    _volumeController.dispose();
    super.dispose();
  }

  void _calculate() {
    final double? vol = double.tryParse(_volumeController.text);
    if (vol == null || vol <= 0) {
      setState(() {
        _calculatedWeight = 0.0;
      });
      return;
    }
    final density = _densities[_selectedMetal] ?? 0.01750;
    setState(() {
      _calculatedWeight = vol * density;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          CommonText.titleMedium(AppStrings.weightCalculator.trClean),
          const SizedBox(height: 4),
          const Text(
            'Auto-calculate metal casting weights using exact density equations.',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 16),

          // Volume Input
          CommonTextField(
            controller: _volumeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            labelText: '3D STL Model Volume (mm³)',
            hintText: 'Enter cubic volume from CAD software',
            prefixIcon: Icons.view_in_ar,
            onChanged: (_) => _calculate(),
          ),
          const SizedBox(height: 12),

          // Metal Type selector
          const Text(
            'Target Metal Alloy Purity:',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outline),
            ),
            child: DropdownButton<String>(
              value: _selectedMetal,
              dropdownColor: AppColors.paper,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.ink,
              ),
              items: _densities.keys.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedMetal = newValue;
                  });
                  _calculate();
                }
              },
            ),
          ),
          const SizedBox(height: 16),

          // Results Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.emeraldLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTIMATED CASTING WEIGHT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.emeraldDark.withValues(alpha: 0.8),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedMetal,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.emeraldDark,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_calculatedWeight.toStringAsFixed(2)} g',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.emeraldDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Save button
          CommonButton.primary(
            label: 'Apply & Confirm Weight Specs',
            onPressed: () {
              final double vol = double.tryParse(_volumeController.text) ?? 0.0;
              widget.onCalculate(vol, _calculatedWeight, _selectedMetal);
            },
          ),
        ],
      ),
    );
  }
}

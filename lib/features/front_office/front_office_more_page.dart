import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/widgets.dart';
import '../../data/demo_store.dart';
import '../auth/widgets/authenticated_profile_card.dart';

class FrontOfficeMorePage extends StatefulWidget {
  const FrontOfficeMorePage({super.key, required this.store});

  final DemoStore store;

  @override
  State<FrontOfficeMorePage> createState() => _FrontOfficeMorePageState();
}

class _FrontOfficeMorePageState extends State<FrontOfficeMorePage> {
  final _calcWeight = TextEditingController(text: '24.5');
  final _calcMaking = TextEditingController(text: '550');
  final _calcDiamondCts = TextEditingController(text: '0.00');
  String _calcPurity = '22KT';

  @override
  void dispose() {
    _calcWeight.dispose();
    _calcMaking.dispose();
    _calcDiamondCts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goldRates = widget.store.goldRates;

    final weight = double.tryParse(_calcWeight.text) ?? 0.0;
    final making = double.tryParse(_calcMaking.text) ?? 0.0;
    final diamondCts = double.tryParse(_calcDiamondCts.text) ?? 0.0;

    final ratePerGram = _calcPurity == '18KT'
        ? goldRates.gold18KPerGram
        : (_calcPurity == '24KT'
              ? goldRates.gold24KPerGram
              : goldRates.gold22KPerGram);

    final goldCost = weight * ratePerGram;
    final makingCost = weight * making;
    final diamondCost =
        diamondCts * 45000.0; // ₹45,000 / ct average wholesale diamond rate
    final subtotal = goldCost + makingCost + diamondCost;
    final gst = subtotal * 0.03; // 3% GST on jewellery in India
    final total = subtotal + gst;

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
        children: [
          const CommonText.headlineLarge('Tools & Settings'),
          const SizedBox(height: 1),
          CommonText.bodySmall(
            'Front Office live rates, estimators and configuration',
            color: AppColors.muted,
          ),
          const SizedBox(height: 10),

          const AuthenticatedProfileCard(),
          const SizedBox(height: 14),

          // 1. LIVE GOLD & SILVER TICKER
          CommonCard(
            backgroundColor: AppColors.ink,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          color: Color(0xFFFFD18A),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Live Gold & Silver Ticker',
                          style: TextStyle(
                            color: Color(0xFFFFD18A),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.emerald,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          goldRates.lastUpdatedTime,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _rateCol(
                        '24KT Pure',
                        '₹${goldRates.gold24KPerGram.toStringAsFixed(0)}/g',
                      ),
                    ),
                    Expanded(
                      child: _rateCol(
                        '22KT 916',
                        '₹${goldRates.gold22KPerGram.toStringAsFixed(0)}/g',
                      ),
                    ),
                    Expanded(
                      child: _rateCol(
                        '18KT 750',
                        '₹${goldRates.gold18KPerGram.toStringAsFixed(0)}/g',
                      ),
                    ),
                    Expanded(
                      child: _rateCol(
                        'Silver 999',
                        '₹${(goldRates.silverPerKg / 1000).toStringAsFixed(0)}/g',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: Colors.white12),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'MCX Spot Reference: Bullion Active',
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                    InkWell(
                      onTap: () {
                        CommonSnackbar.info(
                          context,
                          title: 'Ticker Refreshed',
                          message: 'Latest MCX bullion rates synced.',
                        );
                      },
                      child: const Row(
                        children: [
                          Icon(
                            Icons.refresh,
                            size: 12,
                            color: Color(0xFFFFD18A),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Sync Rates',
                            style: TextStyle(
                              color: Color(0xFFFFD18A),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 2. QUICK JEWELLERY PRICE ESTIMATOR
          const CommonText.titleMedium('Quick Wholesale Quotation Estimator'),
          const SizedBox(height: 8),
          CommonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Presets Row
                Row(
                  children: [
                    const Text(
                      'Presets: ',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    _presetChip('10g Ring', '10.0', '450'),
                    _presetChip('24g Chain', '24.0', '400'),
                    _presetChip('50g Necklace', '50.0', '520'),
                    _presetChip('80g Kada', '80.0', '380'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CommonTextField(
                        controller: _calcWeight,
                        label: 'Gross Weight (g)',
                        hintText: 'e.g. 24.5',
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CommonTextField(
                        controller: _calcMaking,
                        label: 'Making Charge (₹/g)',
                        hintText: 'e.g. 550',
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: CommonTextField(
                        controller: _calcDiamondCts,
                        label: 'Diamond Carats (cts)',
                        hintText: 'e.g. 0.85',
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Purity Selection',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.paper,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusSmall,
                              ),
                              border: Border.all(color: AppColors.outline),
                            ),
                            child: Row(
                              children: [
                                for (final p in ['18KT', '22KT', '24KT'])
                                  Expanded(
                                    child: InkWell(
                                      onTap: () =>
                                          setState(() => _calcPurity = p),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _calcPurity == p
                                              ? AppColors.emerald
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          p,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: _calcPurity == p
                                                ? Colors.white
                                                : AppColors.ink,
                                            fontWeight: _calcPurity == p
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gold: ₹${goldCost.toStringAsFixed(0)} · Making: ₹${makingCost.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                          if (diamondCost > 0)
                            Text(
                              'Diamond (${diamondCts}ct): ₹${diamondCost.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          Text(
                            '+3% GST: ₹${gst.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Estimated Total',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.muted,
                          ),
                        ),
                        Text(
                          '₹${total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.emerald,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: CommonButton.outlined(
                    height: 36,
                    icon: Icons.copy,
                    label: 'Copy Estimate Quotation',
                    onPressed: () {
                      CommonSnackbar.info(
                        context,
                        title: 'Quotation Copied',
                        message:
                            '₹${total.toStringAsFixed(0)} estimate copied to clipboard.',
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 3. OPERATIONAL QUICK ACTIONS
          const CommonText.titleMedium('Wholesale Operations & Utilities'),
          const SizedBox(height: 8),
          _menuTile(
            icon: Icons.calculate_outlined,
            title: 'Gold Purity & Weight Unit Converter',
            subtitle: 'Tola, Sovereign/Pavan, Grams, Carats & Ounces',
            badge: 'Converter',
            onTap: () => _showUnitConverterModal(context),
          ),
          const SizedBox(height: 8),
          _menuTile(
            icon: Icons.bookmark_border,
            title: 'Saved Draft Orders & Cart Holds',
            subtitle: '2 uncommitted design custom batches',
            badge: '2 Drafts',
            onTap: () => _showDraftOrdersModal(context),
          ),
          const SizedBox(height: 8),
          _menuTile(
            icon: Icons.support_agent,
            title: 'Workshop Coordinators & Desk Leads',
            subtitle: 'Direct call/WhatsApp to Floor Manager & QC lead',
            badge: '4 Leads',
            onTap: () => _showDeskLeadsModal(context),
          ),
          const SizedBox(height: 8),
          _menuTile(
            icon: Icons.auto_awesome_rounded,
            title: 'B2B Client Portal & Credit Scoring',
            subtitle: 'AI-driven credit limits & live customer portal',
            badge: 'SOON',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ComingSoonScreen(
                    title: 'B2B Client Portal & Credit Scoring',
                    subtitle:
                        'Empower your wholesale clients with direct order tracking, live gold balance ledgers, and automated credit scoring.',
                    icon: Icons.storefront_rounded,
                    featureTag: 'B2B ENTERPRISE MODULE',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _menuTile(
            icon: Icons.translate_rounded,
            title: 'App Language / भाषा (i18n)',
            subtitle: 'Switch between English, हिंदी and ગુજરાતી',
            badge: 'i18n',
            onTap: () => CommonLanguagePicker.show(context),
          ),
          const SizedBox(height: 8),
          _menuTile(
            icon: Icons.logout_rounded,
            title: 'Sign Out / Switch User',
            subtitle: 'End active session & return to login screen',
            badge: 'Auth',
            onTap: () => CommonLogoutDialog.show(context),
          ),
        ],
      ),
    );
  }

  Widget _presetChip(String label, String wt, String mc) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () {
          setState(() {
            _calcWeight.text = wt;
            _calcMaking.text = mc;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.sage,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.outlineLight),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.emeraldDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _rateCol(String purity, String rate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          purity,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          rate,
          style: const TextStyle(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
  }) {
    return CommonCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.emeraldLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Icon(icon, color: AppColors.emerald, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.sage,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: AppColors.emeraldDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          const Icon(Icons.chevron_right, color: AppColors.muted, size: 18),
        ],
      ),
    );
  }

  // ==========================================
  // UNIT CONVERTER MODAL
  // ==========================================
  void _showUnitConverterModal(BuildContext context) {
    final gramsCtrl = TextEditingController(text: '10');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final g = double.tryParse(gramsCtrl.text) ?? 0.0;
          final tola = g / 11.6638; // 1 Tola = 11.6638 grams
          final pavan = g / 8.0; // 1 Sovereign / Pavan = 8 grams
          final carats = g * 5.0; // 1 Gram = 5 Carats
          final troyOz = g / 31.1035; // 1 Troy Oz = 31.1035 grams

          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
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
                const Text(
                  'Gold Purity & Weight Unit Converter',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Instant conversion across Indian & Global bullion units',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                const SizedBox(height: 14),
                CommonTextField(
                  controller: gramsCtrl,
                  label: 'Weight in Grams (g)',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setModalState(() {}),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _unitBox(
                        'Tola (Indian)',
                        '${tola.toStringAsFixed(3)} tola',
                        '1 Tola = 11.664g',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _unitBox(
                        'Sovereign (Pavan)',
                        '${pavan.toStringAsFixed(3)} pavan',
                        '1 Pavan = 8.000g',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _unitBox(
                        'Gemstone Carats',
                        '${carats.toStringAsFixed(2)} cts',
                        '1g = 5.00 cts',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _unitBox(
                        'Troy Ounce (oz)',
                        '${troyOz.toStringAsFixed(4)} oz',
                        '1 oz = 31.1035g',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: CommonButton.primary(
                    label: 'Done',
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _unitBox(String label, String val, String sub) {
    return CommonCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            val,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppColors.emerald,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            sub,
            style: const TextStyle(color: AppColors.muted, fontSize: 9),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DRAFT ORDERS MODAL
  // ==========================================
  void _showDraftOrdersModal(BuildContext context) {
    final drafts = [
      {
        'title': 'Surat Diamond Mart · Bridal Set Draft',
        'date': 'Today, 02:15 PM',
        'items': '3 Items (182.5g GW)',
        'status': 'Pending Approval',
      },
      {
        'title': 'Zaveri Jewellers · 22K Kada Batch',
        'date': 'Yesterday, 05:40 PM',
        'items': '12 Pieces (96.0g GW)',
        'status': 'Hold on Purity',
      },
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
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
            const Text(
              'Saved Draft Orders',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 2),
            const Text(
              'Uncommitted wholesale batches saved in local cache',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 14),
            for (final d in drafts)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CommonCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d['title']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${d['items']} · ${d['date']}',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CommonButton.primary(
                        isFullWidth: false,
                        height: 32,
                        label: 'Resume',
                        onPressed: () {
                          Navigator.pop(ctx);
                          CommonSnackbar.success(
                            context,
                            title: 'Draft Loaded',
                            message: 'Loaded ${d['title']} into cart.',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WORKSHOP DESK LEADS MODAL
  // ==========================================
  void _showDeskLeadsModal(BuildContext context) {
    final leads = [
      {
        'name': 'Arjun Mehta',
        'role': 'Floor Supervisor & Shift Incharge',
        'phone': '+91 98200 11223',
        'bench': 'Main Floor Bench #01',
      },
      {
        'name': 'Dilip Kumar',
        'role': 'Master QC & Hallmarking Officer',
        'phone': '+91 98200 44556',
        'bench': 'Assay Lab Desk #03',
      },
      {
        'name': 'Prakash Soni',
        'role': 'Vault & Bullion Custodian',
        'phone': '+91 98200 77889',
        'bench': 'Vault Desk #01',
      },
      {
        'name': 'Neha Sharma',
        'role': 'Front Office Order Dispatcher',
        'phone': '+91 98200 99001',
        'bench': 'Client Relations Desk',
      },
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
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
            const Text(
              'Workshop Coordinators & Leads',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 2),
            const Text(
              'Direct desk intercom and WhatsApp for urgent job queries',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 14),
            for (final l in leads)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CommonCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.emeraldLight,
                        child: Text(
                          l['name']!.substring(0, 1),
                          style: const TextStyle(
                            color: AppColors.emerald,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l['name']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${l['role']} · ${l['bench']}',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.phone,
                          color: AppColors.emerald,
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          CommonSnackbar.info(
                            context,
                            title: 'Calling Lead',
                            message: 'Dialing ${l['name']} (${l['phone']})...',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

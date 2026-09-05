import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/widgets.dart';
import '../../data/demo_store.dart';
import '../../domain/models.dart';

class ClientDetailPage extends StatefulWidget {
  const ClientDetailPage({
    super.key,
    required this.client,
    required this.store,
  });

  final ClientInfo client;
  final DemoStore store;

  @override
  State<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends State<ClientDetailPage> {
  int _selectedTab =
      0; // 0: Financials & Orders, 1: Ledger Statement, 2: KYC & Profile

  @override
  Widget build(BuildContext context) {
    final client = widget.client;
    final limitRupees = client.creditLimitLakhs * 100000;
    final availableCredit = (limitRupees - client.outstandingBalance).clamp(
      0.0,
      limitRupees,
    );
    final percent =
        (client.outstandingBalance / (limitRupees > 0 ? limitRupees : 1)).clamp(
          0.0,
          1.0,
        );

    // Filter orders matching client or seed realistic client orders
    final clientOrders = widget.store.orders
        .where(
          (o) =>
              o.clientFirmName.toLowerCase().contains(
                client.firmName.toLowerCase(),
              ) ||
              client.firmName.toLowerCase().contains(
                o.clientFirmName.toLowerCase(),
              ),
        )
        .toList();

    return Scaffold(
      appBar: CommonAppBar(
        title: client.firmName,
        subtitle: '${client.city} · ${client.id}',
        showBrand: false,
        showBackButton: true,
        actions: [
          IconButton(
            tooltip: 'Call Client',
            icon: const Icon(Icons.phone_outlined, color: AppColors.emerald),
            onPressed: () => _showContactSnackbar('Calling ${client.phone}...'),
          ),
          IconButton(
            tooltip: 'Share Ledger via WhatsApp',
            icon: const Icon(Icons.share_outlined, color: AppColors.emerald),
            onPressed: () => _showContactSnackbar(
              'Exporting statement PDF for ${client.firmName}...',
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
          children: [
            // 1. FIRM PROFILE CARD
            CommonCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.emeraldLight,
                        child: Text(
                          client.firmName.isNotEmpty ? client.firmName[0] : 'C',
                          style: const TextStyle(
                            color: AppColors.emerald,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              client.firmName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${client.city} · GSTIN: 24AAACR${client.id.replaceAll(RegExp(r'[^0-9]'), '')}92Z4',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Key Person: ${client.contactPerson} (${client.phone})',
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldLight,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull,
                          ),
                        ),
                        child: const Text(
                          'Tier 1 Wholesale',
                          style: TextStyle(
                            color: AppColors.emeraldDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: CommonButton.outlined(
                          height: 36,
                          icon: Icons.phone,
                          label: 'Call Direct',
                          onPressed: () => _showContactSnackbar(
                            'Dialing ${client.phone}...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CommonButton.tonal(
                          height: 36,
                          icon: Icons.chat_bubble_outline,
                          label: 'WhatsApp',
                          onPressed: () => _showContactSnackbar(
                            'Opening WhatsApp chat for ${client.contactPerson}...',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 2. FINANCIAL & CREDIT HEALTH CARD
            CommonCard(
              backgroundColor: AppColors.ink,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Credit Allocation & Ledger Balance',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFFFFD18A),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: percent > 0.8
                              ? AppColors.danger
                              : AppColors.emerald,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          percent > 0.8 ? 'Near Cap' : 'Good Standing',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _darkStat(
                          label: 'Outstanding Due',
                          value:
                              '₹${(client.outstandingBalance / 100000).toStringAsFixed(2)} L',
                          color: const Color(0xFFFFA88D),
                        ),
                      ),
                      Expanded(
                        child: _darkStat(
                          label: 'Credit Limit',
                          value:
                              '₹${client.creditLimitLakhs.toStringAsFixed(1)} L',
                          color: Colors.white,
                        ),
                      ),
                      Expanded(
                        child: _darkStat(
                          label: 'Free Headroom',
                          value:
                              '₹${(availableCredit / 100000).toStringAsFixed(2)} L',
                          color: const Color(0xFFA9DDD0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 6,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        percent > 0.8
                            ? const Color(0xFFFFA88D)
                            : const Color(0xFFA9DDD0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Terms: Net 15 Days (RTGS/Cheque)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white60, fontSize: 10),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Last: 18 Aug (₹12.5L)',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. SEGMENTED TABS
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(color: AppColors.outline),
              ),
              child: Row(
                children: [
                  _tabButton(
                    0,
                    'Orders (${clientOrders.isNotEmpty ? clientOrders.length : client.activeOrdersCount})',
                  ),
                  _tabButton(1, 'Ledger'),
                  _tabButton(2, 'Terms & KYC'),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 4. TAB CONTENTS
            if (_selectedTab == 0) ...[
              if (clientOrders.isEmpty)
                CommonCard(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.muted,
                          size: 40,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No ongoing workshop orders for ${client.firmName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'All prior batches have been dispatched and settled.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                for (final order in clientOrders)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ClientOrderTile(order: order),
                  ),
            ] else if (_selectedTab == 1) ...[
              _buildLedgerStatement(client),
            ] else ...[
              _buildKycAndTerms(client),
            ],
          ],
        ),
      ),
      bottomSheet: SafeArea(
        top: false,
        child: Container(
          color: AppColors.canvas,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: CommonButton.outlined(
                  height: 42,
                  label: 'Credit Limit',
                  icon: Icons.edit_note,
                  onPressed: () => _openAdjustCreditSheet(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: CommonButton.primary(
                  height: 42,
                  label: 'New Order for Client',
                  icon: Icons.add_shopping_cart,
                  onPressed: () {
                    CommonSnackbar.info(
                      context,
                      title: 'Create Order',
                      message:
                          'Opening catalogue with client ${client.firmName} pre-selected.',
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabButton(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.emerald : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.ink,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _darkStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildLedgerStatement(ClientInfo client) {
    final transactions = [
      {
        'date': '18 Aug 2026',
        'type': 'Payment Received (RTGS)',
        'amount': '₹12,50,000',
        'isCredit': true,
        'ref': 'UTR: HDFC8492049',
      },
      {
        'date': '12 Aug 2026',
        'type': 'Invoice #INV-10479 (Necklace Batch)',
        'amount': '₹18,40,000',
        'isCredit': false,
        'ref': '248.5 g 22K Finished',
      },
      {
        'date': '04 Aug 2026',
        'type': 'Gold Bar Deposit (24K Bullion)',
        'amount': '200.000 g',
        'isCredit': true,
        'ref': 'Assay Voucher #AV-892',
      },
      {
        'date': '28 Jul 2026',
        'type': 'Invoice #INV-10452 (Bangle Batch)',
        'amount': '₹14,20,000',
        'isCredit': false,
        'ref': '190.0 g 22K Finished',
      },
    ];

    return Column(
      children: [
        for (final tx in transactions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: CommonCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: (tx['isCredit'] as bool)
                          ? AppColors.emeraldLight
                          : AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      (tx['isCredit'] as bool)
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      color: (tx['isCredit'] as bool)
                          ? AppColors.emerald
                          : AppColors.danger,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx['type'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${tx['date']} · ${tx['ref']}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(tx['isCredit'] as bool) ? "+" : "-"} ${tx['amount']}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: (tx['isCredit'] as bool)
                          ? AppColors.emerald
                          : AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildKycAndTerms(ClientInfo client) {
    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Commercial Terms & Governance',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          const SizedBox(height: 10),
          _kycRow('Business Category', 'B2B Wholesale Jeweller & Retail Chain'),
          _kycRow('Billing Currency', 'INR (₹) · Making Charges + Purity Base'),
          _kycRow(
            'GST Verification',
            'Verified Active (State Jurisdiction 24)',
          ),
          _kycRow('Cheque Bounce History', '0 Incidents · Tier 1 Trust Record'),
          _kycRow(
            'Delivery Location',
            '${client.city} Wholesale Jewellery Complex',
          ),
          _kycRow('Assigned Account Exec', 'Neha Sharma (Front Office Senior)'),
        ],
      ),
    );
  }

  Widget _kycRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAdjustCreditSheet(BuildContext context) {
    final limitCtrl = TextEditingController(
      text: widget.client.creditLimitLakhs.toStringAsFixed(0),
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
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
            Text(
              'Adjust Credit Limit · ${widget.client.firmName}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'Set approved borrowing & WIP order cap in Lakhs (₹)',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 14),
            CommonTextField(
              controller: limitCtrl,
              label: 'Approved Limit (₹ Lakhs)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CommonButton.primary(
                label: 'Save & Broadcast Cap',
                onPressed: () {
                  Navigator.pop(ctx);
                  CommonSnackbar.success(
                    context,
                    title: 'Limit Updated',
                    message:
                        'Credit cap for ${widget.client.firmName} updated to ₹${limitCtrl.text}L.',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactSnackbar(String msg) {
    CommonSnackbar.info(context, title: 'Client Contact', message: msg);
  }
}

class _ClientOrderTile extends StatelessWidget {
  const _ClientOrderTile({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final statusColor = order.status == OrderStatus.inWorkshop
        ? AppColors.emerald
        : (order.status == OrderStatus.pending
              ? AppColors.warning
              : AppColors.goldDark);

    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.emeraldLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  order.id,
                  style: const TextStyle(
                    color: AppColors.emerald,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  order.status.label,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            order.itemsSummary,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (order.totalGrossGrams > 0)
                Text(
                  '${order.totalGrossGrams} g GW',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Delivery: ${order.promiseDate}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.emeraldDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

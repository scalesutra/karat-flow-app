import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/localization/localization.dart';
import '../../core/widgets/widgets.dart';
import '../../data/demo_store.dart';
import '../../data/repositories/karatflow_api_repository.dart';
import '../../domain/models.dart';
import 'client_detail_page.dart';
import 'bloc/orders_bloc.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key, required this.store});

  final DemoStore store;

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchLiveCustomers();
  }

  Future<void> _fetchLiveCustomers() async {
    context.read<OrdersBloc>().add(const FetchFrontOfficeDataEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final clients = widget.store.clients.where((client) {
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            return client.firmName.toLowerCase().contains(q) ||
                client.city.toLowerCase().contains(q) ||
                client.contactPerson.toLowerCase().contains(q) ||
                client.phone.contains(q);
          }
          return true;
        }).toList();

        return Scaffold(
          body: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CommonText.headlineLarge(
                                  AppStrings.clientAccounts.trClean,
                                ),
                                const SizedBox(height: 1),
                                CommonText.bodySmall(
                                  '${widget.store.clients.length} registered jewellery firms',
                                  color: AppColors.muted,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          CommonButton.primary(
                            isFullWidth: false,
                            height: 36,
                            icon: Icons.add_business,
                            label: AppStrings.registerClient.trClean,
                            onPressed: () => _openAddClientSheet(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      CommonSearchBar(
                        controller: _searchController,
                        hintText:
                            'Search by firm name, city or contact person...',
                        onChanged: (val) => setState(() => _searchQuery = val),
                        onClear: () => setState(() => _searchQuery = ''),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: context.watch<OrdersBloc>().state is OrdersLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: CommonProgressIndicator(
                              theme: IndicatorTheme.frontOffice,
                              size: 54,
                              label: 'Fetching live client accounts...',
                            ),
                          ),
                        )
                      : CommonRefreshIndicator(
                          theme: IndicatorTheme.frontOffice,
                          onRefresh: _fetchLiveCustomers,
                          child: clients.isEmpty
                              ? SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  child: CommonEmptyState(
                                    icon: Icons.storefront_outlined,
                                    title: 'No clients found',
                                    description:
                                        'No firms match the searched keyword.',
                                    actionLabel: 'Add New Client',
                                    onAction: () =>
                                        _openAddClientSheet(context),
                                  ),
                                )
                              : ListView.separated(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    4,
                                    20,
                                    28,
                                  ),
                                  itemCount: clients.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) => _ClientCard(
                                    client: clients[index],
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => ClientDetailPage(
                                            client: clients[index],
                                            store: widget.store,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openAddClientSheet(BuildContext context) {
    final firmController = TextEditingController();
    final cityController = TextEditingController();
    final contactController = TextEditingController();
    final phoneController = TextEditingController();
    final limitController = TextEditingController();

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
            const CommonText.headlineMedium('Register New Client'),
            const SizedBox(height: 14),
            CommonTextField(
              controller: firmController,
              label: 'Firm Name (e.g. Navratna Jewellers)',
              hintText: 'Enter trade name',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: CommonTextField(
                    controller: cityController,
                    label: 'City',
                    hintText: 'e.g. Mumbai',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CommonTextField(
                    controller: limitController,
                    label: 'Credit Limit (â‚¹ Lakhs)',
                    hintText: 'e.g. 50',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            CommonTextField(
              controller: contactController,
              label: 'Contact Person Name',
              hintText: 'e.g. Shailesh Mehta',
            ),
            const SizedBox(height: 10),
            CommonTextField(
              controller: phoneController,
              label: 'Phone Number',
              hintText: 'e.g. +91 98250 12345',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 18),
            CommonButton.primary(
              label: 'Save & Open Account',
              onPressed: () {
                final firm = firmController.text.trim();
                final city = cityController.text.trim();
                final contact = contactController.text.trim();
                final phone = phoneController.text.trim();
                final limit = double.tryParse(limitController.text.trim());
                if (firm.isEmpty ||
                    city.isEmpty ||
                    contact.isEmpty ||
                    phone.isEmpty ||
                    limit == null) {
                  CommonSnackbar.error(
                    context,
                    title: 'Validation Error',
                    message: 'Please enter all required client details.',
                  );
                  return;
                }
                context.read<OrdersBloc>().add(
                  RegisterFrontOfficeCustomerEvent(
                    name: firm,
                    city: city,
                    contactPerson: contact,
                    phone: phone,
                    creditLimitLakhs: limit,
                  ),
                );
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.client, required this.onTap});

  final ClientInfo client;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final limitRupees = client.creditLimitLakhs * 100000;
    final percent =
        (client.outstandingBalance / (limitRupees > 0 ? limitRupees : 1)).clamp(
          0.0,
          1.0,
        );

    return CommonCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.emeraldLight,
                      radius: 20,
                      child: Text(
                        client.firmName.isNotEmpty ? client.firmName[0] : 'C',
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
                            client.firmName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${client.city} Â· ${client.contactPerson}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (client.activeOrdersCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.goldLight,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                    border: Border.all(color: AppColors.gold),
                  ),
                  child: Text(
                    '${client.activeOrdersCount} in WIP',
                    style: const TextStyle(
                      color: AppColors.goldDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: AppColors.muted, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _financeStat(
                'Credit Limit',
                'â‚¹${client.creditLimitLakhs.toStringAsFixed(0)} L',
              ),
              _financeStat(
                'Outstanding',
                client.outstandingBalance > 0
                    ? 'â‚¹${(client.outstandingBalance / 100000).toStringAsFixed(2)} L'
                    : 'Clear',
                color: client.outstandingBalance > 0
                    ? (percent > 0.8 ? AppColors.danger : AppColors.warning)
                    : AppColors.success,
              ),
              _financeStat('Phone', client.phone),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 4,
              backgroundColor: AppColors.outlineLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                percent > 0.8 ? AppColors.danger : AppColors.emerald,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _financeStat(
    String label,
    String value, {
    Color color = AppColors.ink,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: color,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 10),
        ),
      ],
    );
  }
}

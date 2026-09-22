import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../providers/buyer_provider.dart';
import '../../models/payment_status.dart';
import '../../utils/formatters.dart';
import '../../widgets/animated_content.dart';
import '../../widgets/buyer_list_tile.dart';
import '../../widgets/custom_draggable_sheet.dart';
import '../../widgets/buyer_form.dart';
import 'buyer_details_screen.dart';

class BuyersScreen extends StatefulWidget {
  const BuyersScreen({super.key});
  @override
  State<BuyersScreen> createState() => _BuyersScreenState();
}

class _BuyersScreenState extends State<BuyersScreen> {
  String query = '';
  bool endingOnly = false;
  PaymentStatus? paymentFilter;
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BuyerProvider>();
    final buyers = provider.buyers.where((b) {
      final left = b.warrantyEndDate == null
          ? null
          : day(b.warrantyEndDate!).difference(day(DateTime.now())).inDays;
      return '${b.name} ${b.phone} ${b.productName}'.toLowerCase().contains(
            query,
          ) &&
          (paymentFilter == null || b.paymentStatus == paymentFilter) &&
          (!endingOnly || (left != null && left >= 0 && left <= 30));
    }).toList();
    return Column(
      children: [
        Padding(
          padding: AppSizes.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add buyer'),
                onPressed: () => CustomDraggableSheet.show(
                  context,
                  title: AppStrings.addBuyer,
                  builder: (_, scroll) => BuyerForm(scrollController: scroll),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search buyers or products',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) =>
                    setState(() => query = value.trim().toLowerCase()),
              ),
              const SizedBox(height: 12),
              SegmentedButton<PaymentStatus?>(
                segments: const [
                  ButtonSegment(value: null, label: Text('All')),
                  ButtonSegment(value: PaymentStatus.paid, label: Text('Paid')),
                  ButtonSegment(
                    value: PaymentStatus.credit,
                    label: Text('Credit'),
                  ),
                ],
                selected: {paymentFilter},
                onSelectionChanged: (value) =>
                    setState(() => paymentFilter = value.single),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All warranties'),
                    selected: !endingOnly,
                    onSelected: (_) => setState(() => endingOnly = false),
                  ),
                  FilterChip(
                    label: const Text('Ending soon'),
                    selected: endingOnly,
                    onSelected: (v) => setState(() => endingOnly = v),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedContent(
            loading: provider.loading,
            error: provider.error,
            empty: buyers.isEmpty,
            retry: provider.subscribe,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: buyers.length,
              itemBuilder: (context, i) => BuyerListTile(
                buyer: buyers[i],
                onTap: () => Navigator.push(
                  context,
                  smoothRoute(BuyerDetailsScreen(buyerId: buyers[i].id)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

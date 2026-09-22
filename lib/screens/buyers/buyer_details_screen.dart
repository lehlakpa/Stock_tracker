import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_sizes.dart';
import '../../models/user_model.dart';
import '../../models/payment_status.dart';
import '../../providers/buyer_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/animated_content.dart';
import '../../widgets/buyer_form.dart';
import '../../widgets/buyer_list_tile.dart';
import '../../widgets/custom_draggable_sheet.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/shared_widgets.dart';

class BuyerDetailsScreen extends StatelessWidget {
  final String buyerId;
  const BuyerDetailsScreen({super.key, required this.buyerId});
  Future<void> delete(BuildContext context) async {
    final user = context.read<UserModel>();
    final provider = context.read<BuyerProvider>();
    if (!user.isAdmin || !user.isActive || provider.saving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete buyer purchase?'),
        content: const Text(
          'This removes the purchase and restores its quantity if the product still exists. Sales reports will be recalculated. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete purchase'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.delete(buyerId, user);
    if (!context.mounted) return;
    if (ok) navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Purchase deleted. Stock updated if the product still exists.'
              : provider.saveError ?? 'Could not delete purchase.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BuyerProvider>();
    final user = context.watch<UserModel>();
    final b = provider.buyers.where((b) => b.id == buyerId).firstOrNull;
    if (b == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Buyer')),
        body: const ErrorStateWidget(
          message: 'This buyer record no longer exists.',
        ),
      );
    }
    String date(DateTime? d) => d == null ? 'Not available' : dateLabel(d);
    final left = b.warrantyEndDate == null
        ? null
        : day(b.warrantyEndDate!).difference(day(DateTime.now())).inDays;
    final start = b.warrantyStartDate ?? b.purchaseDate;
    final duration = start == null || b.warrantyEndDate == null
        ? 0
        : b.warrantyEndDate!.difference(start).inDays;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warranty Profile'),
        actions: [
          if (user.isAdmin)
            IconButton(
              tooltip: 'Edit buyer',
              icon: const Icon(Icons.edit_outlined),
              onPressed: provider.saving
                  ? null
                  : () => CustomDraggableSheet.show(
                      context,
                      title: 'Edit buyer',
                      builder: (_, scroll) =>
                          BuyerForm(scrollController: scroll, existing: b),
                    ),
            ),
        ],
      ),
      body: AnimatedContent(
        error: provider.error,
        child: ListView(
          padding: AppSizes.pagePadding,
          children: [
            Center(child: InitialTile(b.name)),
            const SizedBox(height: 16),
            Text(
              b.name,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(b.phone, textAlign: TextAlign.center),
            if (b.address.isNotEmpty)
              Text(
                b.address,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [buyerPaymentStatus(b), buyerWarrantyStatus(b)],
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    b.productName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: left == null || duration <= 0
                        ? 0
                        : (left / duration).clamp(0, 1),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    left == null
                        ? 'No warranty recorded'
                        : left < 0
                        ? 'Expired ${-left} days ago'
                        : '$left days left',
                  ),
                  const SizedBox(height: 12),
                  DetailLine('Purchase date', date(b.purchaseDate)),
                  DetailLine('Warranty start', date(b.warrantyStartDate)),
                  DetailLine('Expires date', date(b.warrantyEndDate)),
                  DetailLine('Quantity', '${b.quantity} units'),
                  DetailLine('Unit price', money(b.unitPrice)),
                  DetailLine('Payment status', b.paymentStatus.label),
                  DetailLine(
                    b.paymentStatus == PaymentStatus.credit
                        ? 'Amount due'
                        : 'Total paid',
                    money(b.totalAmount),
                  ),
                  DetailLine('Recorded by', b.recordedByName),
                  if (b.notes.isNotEmpty) DetailLine('Notes', b.notes),
                ],
              ),
            ),
            if (user.isAdmin && user.isActive) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: provider.saving ? null : () => delete(context),
                icon: const Icon(Icons.delete_outline),
                label: Text(provider.saving ? 'Deleting...' : 'Delete buyer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

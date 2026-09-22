import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../providers/stock_provider.dart';
import '../../providers/buyer_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/animated_content.dart';
import '../../widgets/custom_draggable_sheet.dart';
import '../../widgets/stock_form.dart';
import '../../widgets/stock_list_tile.dart';
import '../../widgets/buyer_form.dart';
import '../../widgets/history_list.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/shared_widgets.dart';
import '../buyers/buyer_details_screen.dart';

class ProductDetailsScreen extends StatelessWidget {
  final String productId;
  const ProductDetailsScreen({super.key, required this.productId});
  Future<void> deleteProduct(BuildContext context, String name) async {
    final provider = context.read<StockProvider>();
    if (!provider.user.isAdmin || !provider.user.isActive || provider.saving) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text(
          'Delete "$name" and its remaining inventory? Existing buyer, warranty, and payment records will be kept. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete product'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted || provider.saving) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.deleteProduct(productId);
    if (!context.mounted) return;
    if (ok) navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Product deleted.'
              : provider.saveError ?? 'Could not delete product.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StockProvider>();
    final p = provider.products.where((p) => p.id == productId).firstOrNull;
    if (p == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.product)),
        body: const ErrorStateWidget(message: 'This product no longer exists.'),
      );
    }
    final buyers = context
        .watch<BuyerProvider>()
        .buyers
        .where((b) => b.productId == p.id)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product details'),
        actions: [
          if (provider.user.isAdmin && provider.user.isActive)
            IconButton(
              tooltip: 'Delete product',
              icon: const Icon(Icons.delete_outline),
              color: Theme.of(context).colorScheme.error,
              onPressed: provider.saving
                  ? null
                  : () => deleteProduct(context, p.name),
            ),
        ],
      ),
      body: AnimatedContent(
        error: provider.error,
        child: ListView(
          padding: AppSizes.pagePadding,
          children: [
            Center(
              child: Hero(
                tag: 'product-${p.id}',
                child: ProductImage(
                  stock: p,
                  size: p.imageUrl.isEmpty ? 72 : 220,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              p.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              '${p.sku} · ${p.category}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            AppCard(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Remaining stock'),
                  const SizedBox(height: 8),
                  Text(
                    '${p.remainingQuantity}',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: p.addedQuantity == 0
                        ? 0
                        : (p.remainingQuantity / p.addedQuantity).clamp(0, 1),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 10),
                  Text('of ${p.addedQuantity} units received'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                children: [
                  DetailLine('Sold', '${p.soldQuantity} units'),
                  DetailLine('Selling price', money(p.sellingPrice)),
                  if (provider.user.isAdmin) ...[
                    DetailLine('Purchase price', money(p.purchasePrice)),
                    DetailLine(
                      'Income',
                      money(
                        buyers.fold<double>(0, (sum, b) => sum + b.totalAmount),
                      ),
                    ),
                  ],
                  DetailLine('Low stock limit', '${p.lowStockLimit} units'),
                  if (p.description.isNotEmpty)
                    DetailLine('Description', p.description),
                  DetailLine('Last updated by', p.lastUpdatedByName),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => CustomDraggableSheet.show(
                context,
                title: AppStrings.updateStock,
                builder: (_, scroll) =>
                    StockForm(scrollController: scroll, product: p),
              ),
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text(AppStrings.updateStock),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: p.remainingQuantity <= 0
                  ? null
                  : () => CustomDraggableSheet.show(
                      context,
                      title: AppStrings.addBuyer,
                      builder: (_, scroll) =>
                          BuyerForm(scrollController: scroll, productId: p.id),
                    ),
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Add buyer for this product'),
            ),
            const SizedBox(height: 28),
            Text(
              'Buyers (${buyers.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (buyers.isEmpty) const Text('No purchases recorded yet.'),
            ...buyers.map(
              (b) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: InitialTile(b.name),
                title: Text(b.name),
                subtitle: Text('${b.quantity} units · ${money(b.totalAmount)}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  smoothRoute(BuyerDetailsScreen(buyerId: b.id)),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Recent stock activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            HistoryList(
              updates: provider.history
                  .where((u) => u.productId == p.id)
                  .toList(),
              error: provider.historyError,
            ),
            if (provider.hasMoreHistory)
              TextButton(
                onPressed: provider.loadMoreHistory,
                child: const Text('Load older activity'),
              ),
          ],
        ),
      ),
    );
  }
}

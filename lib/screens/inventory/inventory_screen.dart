import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../providers/stock_provider.dart';
import '../../widgets/animated_content.dart';
import '../../widgets/custom_draggable_sheet.dart';
import '../../widgets/stock_form.dart';
import '../../widgets/stock_list_tile.dart';
import 'product_details_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key, this.initialLowOnly = false});
  final bool initialLowOnly;
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String query = '', category = 'All';
  late bool lowOnly = widget.initialLowOnly;
  @override
  Widget build(BuildContext context) {
    final stock = context.watch<StockProvider>();
    final products = stock.products
        .where(
          (p) =>
              (p.name.toLowerCase().contains(query) ||
                  p.sku.toLowerCase().contains(query)) &&
              (category == 'All' || p.category == category) &&
              (!lowOnly || p.isLow),
        )
        .toList();
    return Column(
      children: [
        Padding(
          padding: AppSizes.pagePadding,
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search products or SKU',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => query = v.toLowerCase()),
              ),
              const SizedBox(height: AppSizes.md),
              Wrap(
                spacing: AppSizes.sm,
                runSpacing: AppSizes.sm,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.tune),
                    label: Text(category == 'All' ? 'Filters' : category),
                    onPressed: () => _filters(context, stock),
                  ),
                  if (stock.user.isAdmin)
                    FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text(AppStrings.addStock),
                      onPressed: () => CustomDraggableSheet.show(
                        context,
                        title: AppStrings.addStock,
                        builder: (_, scroll) =>
                            StockForm(scrollController: scroll),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedContent(
            loading: stock.loading,
            error: stock.error,
            empty: products.isEmpty,
            retry: stock.subscribe,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              itemCount: products.length,
              itemBuilder: (context, i) => StockListTile(
                stock: products[i],
                onTap: () => Navigator.of(context).push(
                  smoothRoute(ProductDetailsScreen(productId: products[i].id)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _filters(BuildContext context, StockProvider stock) {
    CustomDraggableSheet.show(
      context,
      title: 'Product filters',
      builder: (context, scroll) => StatefulBuilder(
        builder: (context, setSheetState) => ListView(
          controller: scroll,
          padding: AppSizes.pagePadding,
          children: [
            Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.sm,
              children:
                  ['All', ...stock.products.map((p) => p.category).toSet()]
                      .map(
                        (v) => InkWell(
                          onTap: () {
                            setState(() => category = v);
                            setSheetState(() {});
                          },
                          child: AnimatedContainer(
                            duration: AppSizes.duration,
                            curve: AppSizes.curve,
                            padding: const EdgeInsets.all(AppSizes.md),
                            decoration: BoxDecoration(
                              color: category == v
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                  : Theme.of(context).colorScheme.surface,
                              border: Border.all(
                                color: category == v
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radius,
                              ),
                            ),
                            child: Text(v),
                          ),
                        ),
                      )
                      .toList(),
            ),
            SwitchListTile(
              title: const Text('Low stock only'),
              value: lowOnly,
              onChanged: (v) {
                setState(() => lowOnly = v);
                setSheetState(() {});
              },
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Apply filters'),
            ),
          ],
        ),
      ),
    );
  }
}

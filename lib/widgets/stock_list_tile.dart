import 'package:flutter/material.dart';
import '../models/stock_model.dart';
import '../utils/formatters.dart' show money;
import 'shared_widgets.dart';
import 'product_image_picker.dart' as images;

class StockListTile extends StatelessWidget {
  final StockModel stock;
  final VoidCallback onTap;
  const StockListTile({super.key, required this.stock, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Hero(
                    tag: 'product-${stock.id}',
                    child: ProductImage(stock: stock),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stock.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${stock.sku} · ${stock.category}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: stock.addedQuantity == 0
                    ? 0
                    : (stock.remainingQuantity / stock.addedQuantity).clamp(
                        0,
                        1,
                      ),
                minHeight: 5,
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                runSpacing: 6,
                children: [
                  Text(
                    '${stock.remainingQuantity} of ${stock.addedQuantity} units left',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (stock.isLow)
                    const StatusPill('Low stock', color: Color(0xFFB07613))
                  else
                    Text(
                      money(stock.sellingPrice),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ProductImage extends StatelessWidget {
  final StockModel stock;
  final double size;
  const ProductImage({super.key, required this.stock, this.size = 46});
  @override
  Widget build(BuildContext context) =>
      images.ProductImage(name: stock.name, url: stock.imageUrl, size: size);
}

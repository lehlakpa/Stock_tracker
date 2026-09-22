import 'package:flutter/material.dart';
import '../models/buyer_model.dart';
import '../models/payment_status.dart';
import '../utils/formatters.dart' show day;
import 'shared_widgets.dart';

Widget buyerPaymentStatus(BuyerModel buyer) => StatusPill(
  buyer.paymentStatus.label,
  color: buyer.paymentStatus == PaymentStatus.paid
      ? const Color(0xFF26805C)
      : const Color(0xFFB07613),
);

Widget buyerWarrantyStatus(BuyerModel buyer) {
  final expiry = buyer.warrantyEndDate;
  if (expiry == null) return const StatusPill('No warranty');
  final today = day(DateTime.now());
  final days = day(expiry).difference(today).inDays;
  final months =
      (expiry.year - today.year) * 12 +
      expiry.month -
      today.month +
      (expiry.day > today.day ? 1 : 0);
  return days < 0
      ? const StatusPill('Expired', color: Color(0xFFD44A55))
      : days <= 30
      ? StatusPill('Ends in $days days', color: const Color(0xFFB07613))
      : StatusPill(
          'Warranty ${months.clamp(1, 1200)} months left',
          color: const Color(0xFF26805C),
        );
}

class BuyerListTile extends StatelessWidget {
  final BuyerModel buyer;
  final VoidCallback onTap;
  const BuyerListTile({super.key, required this.buyer, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InitialTile(buyer.name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buyer.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${buyer.productName} · ${buyer.quantity} units',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      buyer.purchaseDate == null
                          ? buyer.phone
                          : dateLabel(buyer.purchaseDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        buyerPaymentStatus(buyer),
                        buyerWarrantyStatus(buyer),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    ),
  );
}

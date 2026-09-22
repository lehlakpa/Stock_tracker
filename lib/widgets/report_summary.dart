import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/formatters.dart';
import '../models/user_model.dart';
import '../models/payment_status.dart';
import '../providers/buyer_provider.dart';
import 'animated_content.dart';
import 'summary_card.dart';

class ReportSummary extends StatelessWidget {
  final int? totalProducts;
  const ReportSummary({super.key, this.totalProducts});

  @override
  Widget build(BuildContext context) {
    if (!context.watch<UserModel>().isAdmin) return const SizedBox.shrink();
    final provider = context.watch<BuyerProvider>();
    var sales = 0;
    var paid = 0.0;
    var credit = 0.0;
    for (final buyer in provider.buyers) {
      sales += buyer.quantity;
      if (buyer.paymentStatus == PaymentStatus.credit) {
        credit += buyer.totalAmount;
      } else {
        paid += buyer.totalAmount;
      }
    }
    final cards = <Widget>[
      if (totalProducts != null)
        SummaryCard(
          label: 'Total products',
          value: '$totalProducts',
          icon: Icons.category_outlined,
        ),
      SummaryCard(
        label: 'Total sales (units)',
        value: '$sales',
        icon: Icons.shopping_bag_outlined,
      ),
      SummaryCard(
        label: 'Total paid income',
        value: money(paid),
        icon: Icons.payments_outlined,
      ),
      SummaryCard(
        label: 'Credit income',
        value: money(credit),
        icon: Icons.schedule,
      ),
    ];
    return AnimatedContent(
      loading: provider.loading,
      error: provider.error,
      retry: provider.subscribe,
      child: LayoutBuilder(
        builder: (context, constraints) => Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards
              .map(
                (card) => SizedBox(
                  width: (constraints.maxWidth - 16) / 2,
                  child: card,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

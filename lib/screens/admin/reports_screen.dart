import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/formatters.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../models/user_model.dart';

import '../../providers/buyer_provider.dart';
import '../../widgets/animated_content.dart';
import '../../widgets/report_summary.dart';
import '../access_denied_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    if (!context.watch<UserModel>().isAdmin) {
      return const AccessDeniedScreen(message: AppStrings.adminRequired);
    }
    final buyers = context.watch<BuyerProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.reports)),
      body: ListView(
        padding: AppSizes.pagePadding,
        children: [
          Text(
            'Sales & income',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const ReportSummary(),
          const Text(
            'Paid income is collected revenue. Credit income is the outstanding amount. Total sales includes both.',
          ),
          const SizedBox(height: AppSizes.lg),
          Text(
            'Purchase ledger',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          AnimatedContent(
            loading: buyers.loading,
            error: buyers.error,
            empty: buyers.buyers.isEmpty,
            child: Column(
              children: buyers.buyers
                  .map(
                    (b) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text('${b.name} · ${b.productName}'),
                        subtitle: Text(
                          '${b.quantity} units · ${b.recordedByName}',
                        ),
                        trailing: Text(money(b.totalAmount)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

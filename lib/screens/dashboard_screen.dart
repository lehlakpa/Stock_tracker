import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../models/user_model.dart';
import '../providers/stock_provider.dart';
import '../providers/buyer_provider.dart';
import '../widgets/animated_content.dart';
import '../widgets/custom_bottom_navigation.dart';
import '../widgets/summary_card.dart';
import '../widgets/report_summary.dart';
import '../widgets/history_list.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/sales_week_chart.dart';
import 'inventory/inventory_screen.dart';
import 'buyers/buyers_screen.dart';
import 'profile_screen.dart';
import 'admin/staff_management_screen.dart';
import 'admin/reports_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selected = 0;
  bool lowOnly = false;
  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel>();
    final labels = CustomBottomNavigation.getLabels(user.isAdmin);
    if (selected >= labels.length) selected = labels.length - 1;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 86,
        titleSpacing: 24,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                selected == 0 ? AppStrings.appName : labels[selected],
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              DateFormat('EEEE, d MMM yyyy').format(DateTime.now()),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'My Profile',
            onPressed: () => Navigator.push(
              context,
              smoothRoute(
                Scaffold(
                  appBar: AppBar(title: const Text('My Profile')),
                  body: const ProfileScreen(),
                ),
              ),
            ),
            icon: InitialTile(user.name),
          ),
          if (user.isAdmin)
            IconButton(
              tooltip: 'Reports',
              icon: const Icon(Icons.bar_chart_rounded),
              onPressed: () =>
                  Navigator.push(context, smoothRoute(const ReportsScreen())),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.maxContent),
            child: AnimatedSwitcher(
              duration: AppSizes.duration,
              child: switch (labels[selected]) {
                AppStrings.dashboard => _Overview(
                  key: const ValueKey(0),
                  onLowStock: () => setState(() {
                    selected = 1;
                    lowOnly = true;
                  }),
                ),
                AppStrings.inventory => InventoryScreen(
                  key: ValueKey('inventory-$lowOnly'),
                  initialLowOnly: lowOnly,
                ),
                AppStrings.buyers => const BuyersScreen(key: ValueKey(2)),
                AppStrings.team => const StaffManagementScreen(
                  key: ValueKey(3),
                  embedded: true,
                ),
                _ => const ProfileScreen(key: ValueKey(4)),
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selected: selected,
        onSelected: (v) => setState(() {
          selected = v;
          if (v != 1) lowOnly = false;
        }),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({super.key, required this.onLowStock});
  final VoidCallback onLowStock;
  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel>();
    final stock = context.watch<StockProvider>();
    final buyers = context.watch<BuyerProvider>();
    final low = stock.products.where((p) => p.isLow).length;
    return AnimatedContent(
      loading: stock.loading,
      error: stock.error,
      retry: stock.subscribe,
      child: ListView(
        padding: AppSizes.pagePadding,
        children: [
          if (user.isAdmin)
            ReportSummary(totalProducts: stock.products.length)
          else
            SummaryCard(
              label: 'Total products',
              value: '${stock.products.length}',
              icon: Icons.category_outlined,
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              avatar: const Icon(Icons.warning_amber_rounded, size: 16),
              label: Text('$low low on stock'),
              onPressed: onLowStock,
            ),
          ),

          const SizedBox(height: 24),
          Text(
            'Sales this week',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          AppCard(
            child: AnimatedContent(
              loading: buyers.loading,
              error: buyers.error,
              retry: buyers.subscribe,
              child: SalesWeekChart(buyers: buyers.buyers),
            ),
          ),
          if (user.isAdmin) ...[
            const SizedBox(height: 28),
            Text(
              'Recent activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            HistoryList(updates: stock.history, error: stock.historyError),
            if (stock.hasMoreHistory)
              TextButton(
                onPressed: stock.loadMoreHistory,
                child: const Text('Load older activity'),
              ),
          ],
        ],
      ),
    );
  }
}

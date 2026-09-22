import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/stock_model.dart';
import 'error_state_widget.dart';

class HistoryList extends StatelessWidget {
  final List<StockUpdate> updates;
  final String? error;
  const HistoryList({super.key, required this.updates, this.error});
  @override
  Widget build(BuildContext context) {
    if (error != null) return ErrorStateWidget(message: error!);
    if (updates.isEmpty) {
      return const ErrorStateWidget(message: 'No stock changes yet.');
    }
    return Column(
      children: updates
          .map(
            (u) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(
                  '${u.productName}: ${u.previousQuantity} → ${u.newQuantity}',
                ),
                subtitle: Text(
                  '${u.updatedByName} · ${u.updateType}\n${u.note}\n${u.createdAt == null ? "Syncing…" : DateFormat.yMMMd().add_jm().format(u.createdAt!)}',
                ),
                isThreeLine: true,
              ),
            ),
          )
          .toList(),
    );
  }
}

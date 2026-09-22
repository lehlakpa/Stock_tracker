import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/app_sizes.dart';
import '../utils/formatters.dart';
import '../constants/app_strings.dart';
import '../models/buyer_model.dart';
import '../models/payment_status.dart';
import '../models/user_model.dart';
import '../providers/buyer_provider.dart';
import '../providers/stock_provider.dart';
import 'custom_text_field.dart';
import 'custom_button.dart';
import 'custom_notification.dart';

class BuyerForm extends StatefulWidget {
  final ScrollController scrollController;
  final String? productId;
  final BuyerModel? existing; // non-null → edit mode
  const BuyerForm({
    super.key,
    required this.scrollController,
    this.productId,
    this.existing,
  });
  @override
  State<BuyerForm> createState() => _BuyerFormState();
}

class _BuyerFormState extends State<BuyerForm> {
  final form = GlobalKey<FormState>();
  late final fields = {
    'name': TextEditingController(text: widget.existing?.name),
    'phone': TextEditingController(text: widget.existing?.phone),
    'address': TextEditingController(text: widget.existing?.address),
    'quantity': TextEditingController(
      text: widget.existing?.quantity.toString(),
    ),
    'notes': TextEditingController(text: widget.existing?.notes),
  };
  late String? productId = widget.existing?.productId ?? widget.productId;
  late PaymentStatus paymentStatus =
      widget.existing?.paymentStatus ?? PaymentStatus.paid;
  late final String operationId = FirebaseFirestore.instance
      .collection('buyers')
      .doc()
      .id;
  late DateTime purchase = widget.existing?.purchaseDate != null
      ? DateUtils.dateOnly(widget.existing!.purchaseDate!)
      : DateUtils.dateOnly(DateTime.now());
  late DateTime start = widget.existing?.warrantyStartDate != null
      ? DateUtils.dateOnly(widget.existing!.warrantyStartDate!)
      : DateUtils.dateOnly(DateTime.now());
  late DateTime end = widget.existing?.warrantyEndDate != null
      ? DateUtils.dateOnly(widget.existing!.warrantyEndDate!)
      : DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 365));

  bool get isEdit => widget.existing != null;

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> pickDate(String field) async {
    final value = await showDatePicker(
      context: context,
      initialDate: field == 'purchase'
          ? purchase
          : field == 'start'
          ? start
          : end,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (value != null && mounted) {
      setState(() {
        if (field == 'purchase') {
          purchase = value;
        } else if (field == 'start') {
          start = value;
        } else {
          end = value;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final buyers = context.watch<BuyerProvider>();
    final stock = context.watch<StockProvider>();
    final available = stock.products
        .where((p) => p.remainingQuantity > 0 || p.id == productId)
        .toList();
    return PopScope(
      canPop: !buyers.saving,
      child: AbsorbPointer(
        absorbing: buyers.saving,
        child: Form(
          key: form,
          child: ListView(
            controller: widget.scrollController,
            padding: AppSizes.pagePadding,
            children: [
              // In edit mode show the product name (read-only)
              if (isEdit)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.md),
                  child: Text(
                    'Product: ${widget.existing!.productName}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: available.any((p) => p.id == productId)
                      ? productId
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: AppStrings.product,
                  ),
                  items: available
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(
                            '${p.name} (${p.remainingQuantity} available)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => productId = v),
                  validator: (v) => v == null ? 'Select a product.' : null,
                ),
              const SizedBox(height: AppSizes.md),
              CustomTextField(controller: fields['name']!, label: 'Buyer name'),
              CustomTextField(
                controller: fields['phone']!,
                label: AppStrings.phone,
                keyboard: TextInputType.phone,
              ),
              CustomTextField(
                controller: fields['address']!,
                label: 'Address',
                lines: 2,
              ),
              // Quantity is read-only in edit mode
              if (!isEdit)
                CustomTextField(
                  controller: fields['quantity']!,
                  label: 'Quantity',
                  keyboard: TextInputType.number,
                  validator: (v) =>
                      validateNumber(v, integer: true, positive: true),
                ),
              if (!isEdit && stock.products.any((p) => p.id == productId))
                Text(
                  'Unit price: ${money(stock.products.firstWhere((p) => p.id == productId).sellingPrice)}. The current price is confirmed when saving.',
                ),
              if (isEdit)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.md),
                  child: Text(
                    'Qty: ${widget.existing!.quantity}  ·  Unit: ${money(widget.existing!.unitPrice)}  ·  Total: ${money(widget.existing!.totalAmount)}',
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Payment status',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SegmentedButton<PaymentStatus>(
                segments: PaymentStatus.values
                    .map(
                      (status) => ButtonSegment(
                        value: status,
                        label: Text(status.label),
                        icon: Icon(
                          status == PaymentStatus.paid
                              ? Icons.check_circle_outline
                              : Icons.schedule,
                        ),
                      ),
                    )
                    .toList(),
                selected: {paymentStatus},
                onSelectionChanged: (value) =>
                    setState(() => paymentStatus = value.single),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Purchase date'),
                subtitle: Text(DateFormat.yMMMd().format(purchase)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => pickDate('purchase'),
              ),
              ListTile(
                title: const Text('Warranty start'),
                subtitle: Text(DateFormat.yMMMd().format(start)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => pickDate('start'),
              ),
              ListTile(
                title: const Text('Warranty end'),
                subtitle: Text(DateFormat.yMMMd().format(end)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => pickDate('end'),
              ),
              CustomTextField(
                controller: fields['notes']!,
                label: 'Notes',
                requiredField: false,
                lines: 3,
              ),
              CustomButton(
                label: isEdit ? 'Update' : AppStrings.save,
                loading: buyers.saving,
                onPressed: () async {
                  if (!form.currentState!.validate()) return;
                  if (end.isBefore(start) || start.isBefore(purchase)) {
                    showNotice(
                      context,
                      'Warranty must start on or after purchase and end on or after its start.',
                      error: true,
                    );
                    return;
                  }

                  final messenger = ScaffoldMessenger.of(context);

                  if (isEdit) {
                    // --- EDIT MODE ---
                    final user = context.read<UserModel>();
                    final ok = await buyers.update(widget.existing!.id, {
                      'paymentStatus': paymentStatus.name,
                      for (final k in ['name', 'phone', 'address', 'notes'])
                        k: fields[k]!.text.trim(),
                      'purchaseDate': Timestamp.fromDate(purchase),
                      'warrantyStartDate': Timestamp.fromDate(start),
                      'warrantyEndDate': Timestamp.fromDate(end),
                    }, user);
                    if (!context.mounted) return;
                    if (ok) {
                      Navigator.pop(context);
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          successSnackBar('Buyer record updated.'),
                        );
                    } else {
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(errorSnackBar(buyers.saveError!));
                    }
                  } else {
                    // --- ADD MODE ---
                    final qty = int.tryParse(fields['quantity']!.text) ?? 0;
                    final selectedProduct = stock.products
                        .where((p) => p.id == productId)
                        .firstOrNull;
                    if (selectedProduct != null &&
                        qty > selectedProduct.remainingQuantity) {
                      showNotice(
                        context,
                        'Quantity ($qty) exceeds available stock (${selectedProduct.remainingQuantity}).',
                        error: true,
                      );
                      return;
                    }
                    final user = context.read<UserModel>();
                    final ok = await buyers.save(
                      () => buyers.service.recordPurchase(
                        {
                          'paymentStatus': paymentStatus.name,
                          for (final k in ['name', 'phone', 'address', 'notes'])
                            k: fields[k]!.text.trim(),
                          'purchaseDate': Timestamp.fromDate(purchase),
                          'warrantyStartDate': Timestamp.fromDate(start),
                          'warrantyEndDate': Timestamp.fromDate(end),
                        },
                        productId!,
                        qty,
                        user,
                        operationId: operationId,
                      ),
                    );
                    if (!context.mounted) return;
                    if (ok) {
                      Navigator.pop(context);
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(successSnackBar(AppStrings.saved));
                    } else {
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(errorSnackBar(buyers.saveError!));
                    }
                  }
                },
              ),
              const SizedBox(height: AppSizes.lg),
            ],
          ),
        ),
      ),
    );
  }
}

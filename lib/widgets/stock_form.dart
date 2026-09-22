import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../models/stock_model.dart';
import '../providers/stock_provider.dart';
import 'custom_button.dart';
import 'custom_text_field.dart';
import 'custom_notification.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import '../models/operation_id.dart';
import 'product_image_picker.dart';

class StockForm extends StatefulWidget {
  final ScrollController scrollController;
  final StockModel? product;
  const StockForm({super.key, required this.scrollController, this.product});
  @override
  State<StockForm> createState() => _StockFormState();
}

class _StockFormState extends State<StockForm> {
  final form = GlobalKey<FormState>();
  final operationId = newOperationId();
  XFile? selectedImage;
  UploadedImage? uploadedImage;
  late final fields = <String, TextEditingController>{
    'name': TextEditingController(text: widget.product?.name),
    'sku': TextEditingController(text: widget.product?.sku),
    'category': TextEditingController(text: widget.product?.category),
    'description': TextEditingController(text: widget.product?.description),
    'purchasePrice': TextEditingController(
      text: widget.product?.purchasePrice.toString() ?? '0',
    ),
    'sellingPrice': TextEditingController(
      text: widget.product?.sellingPrice.toString() ?? '0',
    ),
    'lowStockLimit': TextEditingController(
      text: widget.product?.lowStockLimit.toString() ?? '5',
    ),
    'quantity': TextEditingController(text: '0'),
    'note': TextEditingController(),
  };
  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StockProvider>();
    final admin = provider.user.isAdmin;
    return PopScope(
      canPop: !provider.saving,
      child: AbsorbPointer(
        absorbing: provider.saving,
        child: Form(
          key: form,
          child: ListView(
            controller: widget.scrollController,
            padding: AppSizes.pagePadding,
            children: [
              if (widget.product != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.md),
                  child: Text(
                    '${widget.product!.name} · changes apply to the latest available quantity.',
                  ),
                ),
              if (admin) ...[
                CustomTextField(
                  controller: fields['name']!,
                  label: 'Product name',
                ),
                CustomTextField(controller: fields['sku']!, label: 'SKU'),
                CustomTextField(
                  controller: fields['category']!,
                  label: 'Category',
                ),
                CustomTextField(
                  controller: fields['description']!,
                  label: 'Description',
                  requiredField: false,
                  lines: 3,
                ),
                ProductImagePicker(
                  initialUrl: widget.product?.imageUrl ?? '',
                  enabled: !provider.saving,
                  onChanged: (image) => setState(() {
                    selectedImage = image;
                    uploadedImage = null;
                  }),
                ),
                const SizedBox(height: AppSizes.md),
                CustomTextField(
                  controller: fields['purchasePrice']!,
                  label: 'Purchase price (NRs)',
                  keyboard: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: validateNumber,
                ),
                CustomTextField(
                  controller: fields['sellingPrice']!,
                  label: 'Selling price (NRs)',
                  keyboard: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: validateNumber,
                ),
                CustomTextField(
                  controller: fields['lowStockLimit']!,
                  label: 'Low stock limit',
                  keyboard: TextInputType.number,
                  validator: (v) => validateNumber(v, integer: true),
                ),
              ],
              CustomTextField(
                controller: fields['quantity']!,
                label: widget.product == null
                    ? 'Initial quantity'
                    : 'Quantity change (+ add / − remove)',
                keyboard: const TextInputType.numberWithOptions(signed: true),
                validator: (v) => validateNumber(
                  v,
                  integer: true,
                  signed: widget.product != null,
                ),
              ),
              if (widget.product != null)
                CustomTextField(
                  controller: fields['note']!,
                  label: 'Reason for change',
                  lines: 2,
                ),
              CustomButton(
                label: AppStrings.save,
                loading: provider.saving,
                onPressed: () async {
                  if (!form.currentState!.validate()) return;
                  if (admin &&
                      widget.product == null &&
                      selectedImage == null) {
                    showNotice(
                      context,
                      'Select a product image first.',
                      error: true,
                    );
                    return;
                  }
                  final details = admin
                      ? <String, dynamic>{
                          for (final key in [
                            'name',
                            'sku',
                            'category',
                            'description',
                          ])
                            key: fields[key]!.text.trim(),
                          'imageUrl': widget.product?.imageUrl ?? '',
                          'purchasePrice': double.parse(
                            fields['purchasePrice']!.text,
                          ),
                          'sellingPrice': double.parse(
                            fields['sellingPrice']!.text,
                          ),
                          'lowStockLimit': int.parse(
                            fields['lowStockLimit']!.text,
                          ),
                        }
                      : null;
                  final quantity = int.parse(fields['quantity']!.text);
                  // Validate removal doesn't exceed available quantity
                  if (widget.product != null && quantity < 0) {
                    final available = widget.product!.remainingQuantity;
                    if (quantity.abs() > available) {
                      showNotice(
                        context,
                        'Cannot remove ${quantity.abs()} units — only $available available.',
                        error: true,
                      );
                      return;
                    }
                  }
                  // Capture messenger before async gap so it works after pop
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = await provider.save(() async {
                    if (admin && selectedImage != null) {
                      uploadedImage ??= await CloudinaryService().uploadImage(
                        selectedImage!,
                      );
                      details!.addAll(uploadedImage!.toMap());
                    }
                    if (widget.product == null) {
                      await provider.service.addProduct(
                        details!,
                        quantity,
                        provider.user,
                        operationId: operationId,
                      );
                    } else {
                      await provider.service.updateQuantity(
                        widget.product!.id,
                        quantity,
                        fields['note']!.text.trim(),
                        provider.user,
                        details: details,
                      );
                    }
                  });
                  if (!context.mounted) return;
                  if (ok) {
                    Navigator.of(context).pop();
                    messenger
                      ..hideCurrentSnackBar()
                      ..showSnackBar(successSnackBar(AppStrings.saved));
                  } else {
                    messenger
                      ..hideCurrentSnackBar()
                      ..showSnackBar(errorSnackBar(provider.saveError!));
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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import '../services/app_error.dart';
import 'shared_widgets.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.name,
    required this.url,
    this.size = 46,
  });
  final String name, url;
  final double size;
  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          color: Theme.of(context).colorScheme.primary,
          size: size > 80 ? 48 : 24,
        ),
      ),
    );
    if (url.isEmpty && size <= 46) return InitialTile(name);
    return ClipRRect(
      borderRadius: BorderRadius.circular(size > 80 ? 18 : 12),
      child: SizedBox(
        width: size,
        height: size,
        child: url.isEmpty
            ? fallback
            : Image.network(
                url,
                fit: BoxFit.cover,
                semanticLabel: name,
                errorBuilder: (_, error, stack) => fallback,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : fallback,
              ),
      ),
    );
  }
}

class ProductImagePicker extends StatefulWidget {
  const ProductImagePicker({
    super.key,
    required this.onChanged,
    this.initialUrl = '',
    this.enabled = true,
    this.picker,
  });
  final ValueChanged<XFile> onChanged;
  final String initialUrl;
  final bool enabled;
  final ImagePicker? picker;
  @override
  State<ProductImagePicker> createState() => _ProductImagePickerState();
}

class _ProductImagePickerState extends State<ProductImagePicker> {
  late final picker = widget.picker ?? ImagePicker();
  Uint8List? bytes;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) recover();
  }

  Future<void> recover() async {
    try {
      final result = await picker.retrieveLostData();
      if (result.files?.isNotEmpty == true) await accept(result.files!.first);
      if (result.exception != null) throw result.exception!;
    } catch (e) {
      if (mounted) showError(context, errorMessage(e));
    }
  }

  Future<void> accept(XFile file) async {
    final length = await file.length();
    if (length == 0 || length > CloudinaryService.maxImageBytes) {
      throw const AppException('Choose an image smaller than 10 MB.');
    }
    final imageBytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => bytes = imageBytes);
    widget.onChanged(file);
  }

  Future<void> pick() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (kIsWeb ||
                defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS)
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    setState(() => busy = true);
    try {
      final file = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
        requestFullMetadata: false,
      );
      if (file != null) await accept(file);
    } catch (e) {
      if (mounted) showError(context, errorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (bytes != null || widget.initialUrl.isNotEmpty)
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 170,
            child: bytes != null
                ? Image.memory(
                    bytes!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stack) => const Center(
                      child: Text(
                        'Cannot preview this image. Choose another photo.',
                      ),
                    ),
                  )
                : Image.network(
                    widget.initialUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stack) =>
                        const Icon(Icons.broken_image_outlined),
                  ),
          ),
        ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: widget.enabled && !busy ? pick : null,
        icon: Icon(
          bytes == null && widget.initialUrl.isEmpty
              ? Icons.add_a_photo_outlined
              : Icons.edit_outlined,
        ),
        label: Text(
          busy
              ? 'Opening photos...'
              : bytes == null && widget.initialUrl.isEmpty
              ? 'Select product image'
              : 'Change image',
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Gallery or camera · Up to 10 MB',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

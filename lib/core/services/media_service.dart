import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'supabase_service.dart';

class MediaService {
  static final ImagePicker _picker = ImagePicker();

  /// Show dialog to choose Camera or Gallery, then pick image
  static Future<XFile?> showImageSourceDialog(BuildContext context) async {
    return showModalBottomSheet<XFile?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'اختيار مصدر الصورة (Image Picker)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    context: ctx,
                    icon: Icons.camera_alt_rounded,
                    label: 'الكاميرا (Camera)',
                    onTap: () async {
                      final file = await _picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 85,
                        maxWidth: 1200,
                      );
                      if (ctx.mounted) Navigator.pop(ctx, file);
                    },
                  ),
                  _buildSourceOption(
                    context: ctx,
                    icon: Icons.photo_library_rounded,
                    label: 'المعرض (Gallery)',
                    onTap: () async {
                      final file = await _picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                        maxWidth: 1200,
                      );
                      if (ctx.mounted) Navigator.pop(ctx, file);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildSourceOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.primary.withAlpha(60)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  /// Pick an image and upload directly to Supabase product-images bucket
  static Future<String?> pickAndUploadProductImage(BuildContext context) async {
    final file = await showImageSourceDialog(context);
    if (file == null) return null;

    final Uint8List bytes = await file.readAsBytes();
    final fileName = file.name;

    final url = await SupabaseService().uploadProductImage(
      imageBytes: bytes,
      fileName: fileName,
    );

    return url;
  }

  /// Pick an image and return raw bytes and filename for preview and upload
  static Future<PickedImageData?> pickProductImage(BuildContext context) async {
    final file = await showImageSourceDialog(context);
    if (file == null) return null;
    final Uint8List bytes = await file.readAsBytes();
    return PickedImageData(bytes: bytes, name: file.name);
  }

  /// Pick an image and upload directly to Supabase user-avatars bucket
  static Future<String?> pickAndUploadUserAvatar(BuildContext context) async {
    final file = await showImageSourceDialog(context);
    if (file == null) return null;

    final Uint8List bytes = await file.readAsBytes();
    final fileName = file.name;

    final url = await SupabaseService().uploadUserAvatar(
      imageBytes: bytes,
      fileName: fileName,
    );

    return url;
  }
}

class PickedImageData {
  final Uint8List bytes;
  final String name;
  const PickedImageData({required this.bytes, required this.name});
}

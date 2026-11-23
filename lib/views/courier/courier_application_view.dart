import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/services/media_service.dart';
import '../../core/services/supabase_service.dart';
import '../../data/models/driver_application_model.dart';
import '../../viewmodels/auth_viewmodel.dart';

class CourierApplicationView extends StatefulWidget {
  const CourierApplicationView({super.key});

  @override
  State<CourierApplicationView> createState() => _CourierApplicationViewState();
}

class _CourierApplicationViewState extends State<CourierApplicationView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _cityController = TextEditingController();
  final _experienceController = TextEditingController(text: '1');
  String _vehicleType = 'car';
  Uint8List? _licenseBytes;
  String? _licenseFileName;
  bool _isSubmitting = false;
  bool _isApproved = false;
  bool _isCheckingApproval = true;

  @override
  void initState() {
    super.initState();
    _loadApprovalStatus();
  }

  Future<void> _loadApprovalStatus() async {
    final approved = await SupabaseService().isCurrentUserApprovedCourier();
    if (!mounted) return;
    setState(() {
      _isApproved = approved;
      _isCheckingApproval = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    _cityController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _pickLicense() async {
    final picked = await MediaService.pickProductImage(context);
    if (picked == null || !mounted) return;
    setState(() {
      _licenseBytes = picked.bytes;
      _licenseFileName = picked.name;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final authUser = Provider.of<AuthViewModel>(context, listen: false).currentUser;
    final supabase = SupabaseService();
    if (authUser == null || !supabase.isInitialized) {
      _showMessage('Please sign in before applying.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      String? licenseUrl;
      if (_licenseBytes != null && _licenseFileName != null) {
        licenseUrl = await supabase.uploadDriverDocument(
          imageBytes: _licenseBytes!,
          fileName: _licenseFileName!,
        );
      }

      final application = DriverApplicationModel(
        id: 'driver_${DateTime.now().millisecondsSinceEpoch}',
        userId: authUser.id,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        nationalId: _nationalIdController.text.trim(),
        vehicleType: _vehicleType,
        city: _cityController.text.trim(),
        experienceYears: int.tryParse(_experienceController.text.trim()) ?? 1,
        licenseImageUrl: licenseUrl,
        createdAt: DateTime.now(),
      );

      final success = await supabase.submitDriverApplication(application);
      if (!mounted) return;
      _showMessage(
        success ? 'Courier application submitted for review.' : 'Could not submit the application.',
        isError: !success,
      );
      if (success) Navigator.pop(context);
    } catch (e) {
      if (mounted) _showMessage('Application failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.isArabic ? 'التقديم كمندوب توصيل' : 'Apply as Courier'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              loc.isArabic
                  ? 'أرسل بياناتك للانضمام إلى فريق التوصيل.'
                  : 'Submit your details to join our delivery team.',
              style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(160)),
            ),
            const SizedBox(height: 20),
            _field(_nameController, loc.isArabic ? 'الاسم الكامل' : 'Full name'),
            _field(_phoneController, loc.isArabic ? 'رقم الهاتف' : 'Phone number',
                keyboardType: TextInputType.phone),
            _field(_nationalIdController, loc.isArabic ? 'رقم الهوية' : 'National ID'),
            _field(_cityController, loc.isArabic ? 'المدينة' : 'City'),
            DropdownButtonFormField<String>(
              initialValue: _vehicleType,
              decoration: InputDecoration(
                labelText: loc.isArabic ? 'نوع المركبة' : 'Vehicle type',
                border: const OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'motorcycle', child: Text('Motorcycle')),
                DropdownMenuItem(value: 'car', child: Text('Car')),
                DropdownMenuItem(value: 'van', child: Text('Delivery van')),
                DropdownMenuItem(value: 'truck', child: Text('Cargo truck')),
              ],
              onChanged: (value) => setState(() => _vehicleType = value ?? 'car'),
            ),
            const SizedBox(height: 16),
            _field(
              _experienceController,
              loc.isArabic ? 'سنوات الخبرة' : 'Experience years',
              keyboardType: TextInputType.number,
            ),
            OutlinedButton.icon(
              onPressed: _isSubmitting ? null : _pickLicense,
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(
                _licenseFileName == null
                    ? (loc.isArabic ? 'رفع صورة الرخصة' : 'Upload license image')
                    : _licenseFileName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting || _isApproved || _isCheckingApproval ? null : _submit,
                child: _isApproved
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded),
                          SizedBox(width: 8),
                          Text('Approved'),
                        ],
                      )
                    : _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(loc.isArabic ? 'إرسال الطلب' : 'Submit application'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (value) => value == null || value.trim().isEmpty ? label : null,
      ),
    );
  }
}

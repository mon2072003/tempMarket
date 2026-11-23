import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/location_service.dart';
import '../../core/localization/app_localizations.dart';

class AddressPickerDialog extends StatefulWidget {
  final String initialAddress;

  const AddressPickerDialog({super.key, required this.initialAddress});

  static Future<String?> show(BuildContext context, {String initialAddress = ''}) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AddressPickerDialog(initialAddress: initialAddress),
    );
  }

  @override
  State<AddressPickerDialog> createState() => _AddressPickerDialogState();
}

class _AddressPickerDialogState extends State<AddressPickerDialog> {
  late TextEditingController _addressController;
  bool _isLoadingGps = false;
  double _currentLat = LocationService.defaultLat;
  double _currentLng = LocationService.defaultLng;
  bool _hasGps = false;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.initialAddress);
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _detectCurrentLocation() async {
    setState(() => _isLoadingGps = true);
    final result = await LocationService.getCurrentLocation();
    setState(() {
      _isLoadingGps = false;
      _currentLat = result.latitude;
      _currentLng = result.longitude;
      _hasGps = result.isGpsDetected;
      _addressController.text = result.formattedAddress;
    });
  }

  Future<void> _openGoogleMaps() async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$_currentLat,$_currentLng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final primary = theme.colorScheme.primary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.location_on_rounded, color: primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      loc.isArabic ? 'تحديد عنوان التوصيل والخريطة' : 'Delivery Address & Map',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Interactive Google Maps Visual Simulation Card
              Container(
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1E293B),
                      primary.withAlpha(200),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withAlpha(40),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Grid background decoration
                    Center(
                      child: Icon(
                        Icons.map_outlined,
                        size: 90,
                        color: Colors.white.withAlpha(30),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_pin, size: 40, color: Color(0xFFEF4444)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(160),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_hasGps)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4, right: 4),
                                    child: Icon(Icons.gps_fixed_rounded, size: 12, color: Color(0xFF10B981)),
                                  ),
                                Text(
                                  'Lat: ${_currentLat.toStringAsFixed(4)} | Lng: ${_currentLng.toStringAsFixed(4)}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                        ),
                        onPressed: _openGoogleMaps,
                        icon: const Icon(Icons.open_in_new_rounded, size: 14, color: Colors.black87),
                        label: Text(
                          loc.isArabic ? 'خريطة جوجل (Google Maps)' : 'Open in Maps',
                          style: const TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // GPS Button
              OutlinedButton.icon(
                onPressed: _isLoadingGps ? null : _detectCurrentLocation,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: primary),
                ),
                icon: _isLoadingGps
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.my_location_rounded, color: primary),
                label: Text(
                  loc.isArabic ? 'تحديد موقعي الحالي GPS' : 'Detect My Current GPS Location',
                  style: TextStyle(fontWeight: FontWeight.bold, color: primary),
                ),
              ),
              const SizedBox(height: 12),

              // Manual Address Input
              TextField(
                controller: _addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: loc.isArabic ? 'كتابة عنوانك بالتفصيل' : 'Type Your Detailed Address',
                  hintText: loc.isArabic
                      ? 'مثال: الرياض - حي الصحافة - شارع العليا - مبنى رقم 12'
                      : 'e.g. Riyadh - Al Sahafa - Olaya St - Bldg 12',
                  prefixIcon: const Icon(Icons.edit_location_alt_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(loc.isArabic ? 'إلغاء' : 'Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        final text = _addressController.text.trim();
                        if (text.isNotEmpty) {
                          Navigator.pop(context, text);
                        }
                      },
                      child: Text(loc.isArabic ? 'تأكيد العنوان' : 'Confirm Address'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

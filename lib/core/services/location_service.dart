import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final bool isGpsDetected;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    this.isGpsDetected = false,
  });

  String get googleMapsUrl => 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

  String getDirectionsUrl({double? originLat, double? originLng}) {
    if (originLat != null && originLng != null) {
      return 'https://www.google.com/maps/dir/?api=1&origin=$originLat,$originLng&destination=$latitude,$longitude&travelmode=driving';
    }
    return 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving';
  }
}

class LocationService {
  static const double defaultLat = 24.7136; // Riyadh
  static const double defaultLng = 46.6753;

  /// Optional Google Maps API key for Static Maps and Geocoding APIs
  static String googleMapsApiKey = '';

  /// Generate a Google Maps Directions URL between origin and destination
  static String getNavigationUrl({
    required double destLat,
    required double destLng,
    double originLat = defaultLat,
    double originLng = defaultLng,
  }) {
    return 'https://www.google.com/maps/dir/?api=1&origin=$originLat,$originLng&destination=$destLat,$destLng&travelmode=driving';
  }

  /// Generate a Google Maps Static API Image URL
  static String getStaticMapUrl({
    required double lat,
    required double lng,
    int zoom = 14,
    int width = 600,
    int height = 300,
  }) {
    final keyParam = googleMapsApiKey.isNotEmpty ? '&key=$googleMapsApiKey' : '';
    return 'https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng&zoom=$zoom&size=${width}x$height&markers=color:red%7C$lat,$lng$keyParam';
  }

  /// Request permissions and get current GPS location
  static Future<LocationResult> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationResult(
        latitude: defaultLat,
        longitude: defaultLng,
        formattedAddress: 'الرياض - طريق الملك فهد (الموقع الافتراضي)',
        isGpsDetected: false,
      );
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const LocationResult(
          latitude: defaultLat,
          longitude: defaultLng,
          formattedAddress: 'الرياض - طريق الملك فهد (تم رفض الإذن)',
          isGpsDetected: false,
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationResult(
        latitude: defaultLat,
        longitude: defaultLng,
        formattedAddress: 'الرياض - طريق الملك فهد (إذن الموقع معطل)',
        isGpsDetected: false,
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        formattedAddress: 'موقعي الحالي: (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})',
        isGpsDetected: true,
      );
    } catch (_) {
      return const LocationResult(
        latitude: defaultLat,
        longitude: defaultLng,
        formattedAddress: 'الرياض - طريق الملك فهد (تعذر الاتصال بـ GPS)',
        isGpsDetected: false,
      );
    }
  }
}

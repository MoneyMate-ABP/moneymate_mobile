import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';

class LocationService {
  LocationService._internal();
  static final LocationService instance = LocationService._internal();

  final Dio _dio = Dio(BaseOptions(
    headers: {
      'User-Agent': 'MoneyMateMobile/1.0.0',
      'Accept-Language': 'id,en',
    },
  ));

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied, it will throw an error message.
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Layanan lokasi dinonaktifkan di perangkat Anda.';
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Izin akses lokasi ditolak oleh pengguna.';
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw 'Izin lokasi ditolak secara permanen. Silakan aktifkan di pengaturan perangkat Anda.';
    } 

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 15),
    );
  }

  /// Get readable place name via Nominatim reverse geocoding.
  Future<String> getPlaceName(double lat, double lng) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'jsonv2',
          'lat': lat,
          'lon': lng,
          'zoom': 18,
          'addressdetails': 1,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final displayName = response.data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          return displayName;
        }
      }
      return 'Nama lokasi tidak ditemukan';
    } catch (e) {
      return 'Gagal memuat nama lokasi';
    }
  }
}

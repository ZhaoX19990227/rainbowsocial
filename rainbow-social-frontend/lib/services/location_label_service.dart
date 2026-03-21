import 'package:geocoding/geocoding.dart';

class LocationLabelService {
  Future<String> getLocationLabel({
    required double lat,
    required double lng,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return '';
      final place = placemarks.first;
      final pieces = <String>[
        if ((place.administrativeArea ?? '').trim().isNotEmpty)
          place.administrativeArea!.trim(),
        if ((place.locality ?? '').trim().isNotEmpty)
          place.locality!.trim(),
        if ((place.subLocality ?? '').trim().isNotEmpty &&
            place.subLocality!.trim() != place.locality?.trim())
          place.subLocality!.trim(),
      ];
      return pieces.take(2).join(' ');
    } catch (_) {
      return '';
    }
  }
}

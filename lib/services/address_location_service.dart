import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';

class AddressLocationResult {
  final String addressLine1;
  final String area;
  final String city;
  final String state;
  final String pincode;

  const AddressLocationResult({
    required this.addressLine1,
    required this.area,
    required this.city,
    required this.state,
    required this.pincode,
  });
}

class AddressLocationService {
  AddressLocationService();

  final geocoding.Geocoding _geocoding =
      geocoding.Geocoding();

  Future<AddressLocationResult> getCurrentAddress() async {
    // =======================================================
    // LOCATION SERVICE
    // =======================================================

    final bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    // =======================================================
    // PERMISSION
    // =======================================================

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationPermissionDeniedException();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionDeniedForeverException();
    }

    // =======================================================
    // CURRENT LOCATION
    //
    // geolocator ^12.0.0 compatible
    // =======================================================

    final Position position =
        await Geolocator.getCurrentPosition(
      desiredAccuracy:
          LocationAccuracy.high,
    );

    // =======================================================
    // REVERSE GEOCODING
    //
    // geocoding ^5.0.0 compatible
    // =======================================================

    final List<geocoding.Placemark> placemarks =
        await _geocoding.placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isEmpty) {
      throw const AddressNotFoundException();
    }

    final geocoding.Placemark place =
        placemarks.first;

    // =======================================================
    // ADDRESS COMPONENTS
    // =======================================================

    final String street =
        place.street?.trim() ?? '';

    final String subLocality =
        place.subLocality?.trim() ?? '';

    final String locality =
        place.locality?.trim() ?? '';

    final String administrativeArea =
        place.administrativeArea?.trim() ?? '';

    final String postalCode =
        place.postalCode?.trim() ?? '';

    final String subAdministrativeArea =
        place.subAdministrativeArea?.trim() ?? '';

    // =======================================================
    // AREA
    // =======================================================

    String area = '';

    if (subLocality.isNotEmpty) {
      area = subLocality;
    } else if (locality.isNotEmpty) {
      area = locality;
    }

    // =======================================================
    // CITY
    // =======================================================

    String city = '';

    if (locality.isNotEmpty) {
      city = locality;
    } else if (subAdministrativeArea.isNotEmpty) {
      city = subAdministrativeArea;
    }

    // =======================================================
    // STATE
    // =======================================================

    final String state =
        administrativeArea;

    // =======================================================
    // RETURN
    // =======================================================

    return AddressLocationResult(
      addressLine1: street,
      area: area,
      city: city,
      state: state,
      pincode: postalCode,
    );
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}

// ===========================================================
// CUSTOM EXCEPTIONS
// ===========================================================

class LocationPermissionDeniedException
    implements Exception {
  const LocationPermissionDeniedException();
}

class LocationPermissionDeniedForeverException
    implements Exception {
  const LocationPermissionDeniedForeverException();
}

class AddressNotFoundException
    implements Exception {
  const AddressNotFoundException();
}

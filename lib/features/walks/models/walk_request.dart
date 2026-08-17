import 'package:cloud_firestore/cloud_firestore.dart';

class WalkRequest {
  final String id;

  // Owner
  final String ownerId;
  final String ownerName;
  final String ownerPhone;
  final String dogName;

  // Pickup
  final String pickupAddress;
  final double distanceKm;
  final String estimatedTime;
  final double? pickupLatitude;
  final double? pickupLongitude;

  // Request
  final String status;
  final String? acceptedBy;

  // Walker
  final String? walkerId;
  final String? walkerPhone;
  final String? walkerName;
  final String? walkerProfileSelfie;
  final bool walkerVerified;

  // Firebase timestamps
  final DateTime? createdAt;
  final DateTime? expiresAt;

  const WalkRequest({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhone,
    required this.dogName,
    required this.pickupAddress,
    required this.distanceKm,
    required this.estimatedTime,
    required this.status,
    this.pickupLatitude,
    this.pickupLongitude,
    this.acceptedBy,
    this.walkerId,
    this.walkerPhone,
    this.walkerName,
    this.walkerProfileSelfie,
    this.walkerVerified = false,
    this.createdAt,
    this.expiresAt,
  });

  factory WalkRequest.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return WalkRequest(
      id: id,

      // ==========================================================
      // OWNER
      // Exact current Firestore fields:
      // ownerid / ownername / ownermobilenumber
      // ==========================================================

      ownerId: _readString(
        data['ownerid'],
        fallback: data['ownerId'],
      ),

      ownerName: _readString(
        data['ownername'],
        fallback: data['ownerName'],
        defaultValue: 'Dog Owner',
      ),

      ownerPhone: _readString(
        data['ownermobilenumber'],
        fallback: data['ownerPhone'],
      ),

      dogName: _readString(
        data['dogname'],
        fallback: data['dogName'],
        defaultValue: 'Dog',
      ),

      // ==========================================================
      // PICKUP
      // ==========================================================

      pickupAddress: _readString(
        data['address'],
        fallback: data['pickupAddress'],
        defaultValue: 'Pickup location unavailable',
      ),

      distanceKm: _doubleValue(
        data['distanceKm'],
      ),

      estimatedTime: _readString(
        data['estimatedtime'],
        fallback: data['estimatedTime'],
        defaultValue: 'Nearby',
      ),

      pickupLatitude: _nullableDouble(
        data['pickuplatitude'],
        fallback: data['pickupLatitude'],
      ),

      pickupLongitude: _nullableDouble(
        data['pickuplongitude'],
        fallback: data['pickupLongitude'],
      ),

      // ==========================================================
      // REQUEST
      // ==========================================================

      status: _readString(
        data['status'],
        defaultValue: 'searching',
      ),

      acceptedBy: _nullableString(
        data['acceptedBy'],
      ),

      // ==========================================================
      // WALKER
      // ==========================================================

      walkerId: _nullableString(
        data['walkerid'],
        fallback: data['walkerId'],
      ),

      walkerPhone: _nullableString(
        data['walkermobilenumber'],
        fallback: data['walkerPhone'],
      ),

      walkerName: _nullableString(
        data['walkerName'],
      ),

      walkerProfileSelfie: _nullableString(
        data['walkerProfileselfie'],
      ),

      walkerVerified:
          data['walkerVerified'] == true,

      // ==========================================================
      // TIMESTAMPS
      // ==========================================================

      createdAt: _readDate(
        data['createdAt'],
      ),

      expiresAt: _readDate(
        data['expiresAt'],
      ),
    );
  }

  // ============================================================
  // STRING HELPERS
  // ============================================================

  static String _readString(
    dynamic value, {
    dynamic fallback,
    String defaultValue = '',
  }) {
    final String primary =
        value?.toString().trim() ?? '';

    if (primary.isNotEmpty) {
      return primary;
    }

    final String secondary =
        fallback?.toString().trim() ?? '';

    if (secondary.isNotEmpty) {
      return secondary;
    }

    return defaultValue;
  }

  static String? _nullableString(
    dynamic value, {
    dynamic fallback,
  }) {
    final String primary =
        value?.toString().trim() ?? '';

    if (primary.isNotEmpty) {
      return primary;
    }

    final String secondary =
        fallback?.toString().trim() ?? '';

    if (secondary.isNotEmpty) {
      return secondary;
    }

    return null;
  }

  // ============================================================
  // DOUBLE
  // ============================================================

  static double _doubleValue(
    dynamic value, {
    dynamic fallback,
  }) {
    if (value is num) {
      return value.toDouble();
    }

    final double? primary =
        double.tryParse(
      value?.toString() ?? '',
    );

    if (primary != null) {
      return primary;
    }

    if (fallback is num) {
      return fallback.toDouble();
    }

    return double.tryParse(
          fallback?.toString() ?? '',
        ) ??
        0;
  }

  static double? _nullableDouble(
    dynamic value, {
    dynamic fallback,
  }) {
    if (value is num) {
      return value.toDouble();
    }

    final double? primary =
        double.tryParse(
      value?.toString() ?? '',
    );

    if (primary != null) {
      return primary;
    }

    if (fallback is num) {
      return fallback.toDouble();
    }

    return double.tryParse(
      fallback?.toString() ?? '',
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  static DateTime? _readDate(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}

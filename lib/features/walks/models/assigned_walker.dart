import 'package:cloud_firestore/cloud_firestore.dart';

class AssignedWalker {
  final String walkId;

  /// Application-level Walker ID.
  final String walkerId;

  final String walkerName;
  final String walkerPhone;
  final bool verified;
  final String status;
  final String? profileImage;
  final double? latitude;
  final double? longitude;

  const AssignedWalker({
    required this.walkId,
    required this.walkerId,
    required this.walkerName,
    required this.walkerPhone,
    required this.verified,
    required this.status,
    this.profileImage,
    this.latitude,
    this.longitude,
  });

  factory AssignedWalker.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return AssignedWalker(
      walkId: id,

      // New field: walkerId
      // Backward compatibility: walkerUid
      walkerId: _stringValue(
        data['walkerId'] ??
            data['walkerUid'],
      ),

      walkerName: _stringValue(
        data['walkerName'],
        fallback: 'Walker',
      ),

      walkerPhone: _stringValue(
        data['walkerPhone'],
      ),

      verified:
          data['walkerVerified'] == true,

      status: _stringValue(
        data['status'],
        fallback: 'assigned',
      ),

      profileImage:
          _nullableString(
        data['walkerProfileImage'],
      ),

      latitude: _doubleValue(
        data['walkerLatitude'],
      ),

      longitude: _doubleValue(
        data['walkerLongitude'],
      ),
    );
  }

  static String _stringValue(
    dynamic value, {
    String fallback = '',
  }) {
    final String result =
        value?.toString().trim() ?? '';

    return result.isEmpty
        ? fallback
        : result;
  }

  static String? _nullableString(
    dynamic value,
  ) {
    final String result =
        value?.toString().trim() ?? '';

    return result.isEmpty ? null : result;
  }

  static double? _doubleValue(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'walkerId': walkerId,
      'walkerName': walkerName,
      'walkerPhone': walkerPhone,
      'walkerVerified': verified,
      'status': status,
      'walkerProfileImage': profileImage,
      'walkerLatitude': latitude,
      'walkerLongitude': longitude,
      'updatedAt':
          FieldValue.serverTimestamp(),
    };
  }
}

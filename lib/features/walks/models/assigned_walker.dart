assigned_walker.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class AssignedWalker {
  final String walkId;
  final String walkerUid;
  final String walkerName;
  final String walkerPhone;
  final bool verified;
  final String status;
  final String? profileImage;
  final double? latitude;
  final double? longitude;

  const AssignedWalker({
    required this.walkId,
    required this.walkerUid,
    required this.walkerName,
    required this.walkerPhone,
    required this.verified,
    required this.status,
    this.profileImage,
    this.latitude,
    this.longitude,
  });

  // Existing UI compatibility.
  String get walkerId => walkerUid;

  factory AssignedWalker.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return AssignedWalker(
      walkId: id,
      walkerUid:
          data['walkerUid']?.toString() ?? '',
      walkerName:
          data['walkerName']?.toString() ?? 'Walker',
      walkerPhone:
          data['walkerPhone']?.toString() ?? '',
      verified:
          data['walkerVerified'] == true,
      status:
          data['status']?.toString() ?? 'accepted',
      profileImage:
          data['walkerProfileImage']?.toString(),
      latitude: _doubleValue(
        data['walkerLatitude'],
      ),
      longitude: _doubleValue(
        data['walkerLongitude'],
      ),
    );
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
      'walkerUid': walkerUid,
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

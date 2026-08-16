class WalkRequest {
  final String id;
  final String ownerUid;
  final String ownerName;
  final String dogName;
  final String pickupAddress;
  final double distanceKm;
  final String estimatedTime;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String status;
  final String? walkerUid;
  final String? acceptedBy;

  const WalkRequest({
    required this.id,
    required this.ownerUid,
    required this.ownerName,
    required this.dogName,
    required this.pickupAddress,
    required this.distanceKm,
    required this.estimatedTime,
    required this.status,
    this.pickupLatitude,
    this.pickupLongitude,
    this.walkerUid,
    this.acceptedBy,
  });

  factory WalkRequest.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return WalkRequest(
      id: id,
      ownerUid: data['ownerUid']?.toString() ?? '',
      ownerName:
          data['ownerName']?.toString() ?? 'Dog Owner',
      dogName:
          data['dogName']?.toString() ?? 'Dog',
      pickupAddress:
          data['address']?.toString() ??
          data['pickupAddress']?.toString() ??
          'Pickup location unavailable',
      distanceKm:
          _doubleValue(data['distanceKm']),
      estimatedTime:
          data['estimatedTime']?.toString() ?? 'Nearby',
      status:
          data['status']?.toString() ?? 'searching',
      pickupLatitude:
          _nullableDouble(data['pickupLatitude']),
      pickupLongitude:
          _nullableDouble(data['pickupLongitude']),
      walkerUid:
          data['walkerUid']?.toString(),
      acceptedBy:
          data['acceptedBy']?.toString(),
    );
  }

  static double _doubleValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        999;
  }

  static double? _nullableDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }
}

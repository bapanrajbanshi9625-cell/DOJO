class AssignedWalker {
  final String walkerUid;
  final String walkerName;
  final String walkerId;
  final bool verified;
  final String status;
  final String? phone;

  const AssignedWalker({
    required this.walkerUid,
    required this.walkerName,
    required this.walkerId,
    required this.verified,
    required this.status,
    this.phone,
  });

  factory AssignedWalker.fromFirestore(
    Map<String, dynamic> data,
  ) {
    return AssignedWalker(
      walkerUid: data['walkerUid']?.toString() ?? '',
      walkerName:
          data['walkerName']?.toString() ?? 'Walker',
      walkerId:
          data['walkerId']?.toString() ??
          data['walkerUid']?.toString() ??
          '',
      verified: data['verified'] == true,
      status:
          data['status']?.toString() ?? 'accepted',
      phone: data['walkerPhone']?.toString(),
    );
  }
}

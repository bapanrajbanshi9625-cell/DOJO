class ActiveWalk {
  final String documentId;
  final String ownerName;
  final String walkId;
  final double? currentLat;
  final double? currentLng;
  final String distance;
  final String duration;
  final String ownerId;
  final String petAge;
  final String petBreed;
  final String petName;
  final String status;
  final String walkerName;
  final String walkerId;

  const ActiveWalk({
    required this.documentId,
    required this.ownerName,
    required this.walkId,
    required this.currentLat,
    required this.currentLng,
    required this.distance,
    required this.duration,
    required this.ownerId,
    required this.petAge,
    required this.petBreed,
    required this.petName,
    required this.status,
    required this.walkerName,
    required this.walkerId,
  });

  // ==========================================================
  // FIRESTORE MAP → ACTIVE WALK
  // ==========================================================

  factory ActiveWalk.fromMap(
    String documentId,
    Map<String, dynamic> data,
  ) {
    return ActiveWalk(
      documentId: documentId,
      ownerName: _stringValue(
        data['OwnerName'],
      ),
      walkId: _stringValue(
        data['Walkid'],
      ),
      currentLat: _doubleValue(
        data['currentLat'],
      ),
      currentLng: _doubleValue(
        data['currentLng'],
      ),
      distance: _stringValue(
        data['distance'],
      ),
      duration: _stringValue(
        data['duration'],
      ),
      ownerId: _stringValue(
        data['ownerId'],
      ),
      petAge: _stringValue(
        data['petAge'],
      ),
      petBreed: _stringValue(
        data['petBreed'],
      ),
      petName: _stringValue(
        data['petName'],
      ),
      status: _stringValue(
        data['status'],
      ),
      walkerName: _stringValue(
        data['walkerName'],
      ),
      walkerId: _stringValue(
        data['walkerId'],
      ),
    );
  }

  // ==========================================================
  // ACTIVE WALK → FIRESTORE MAP
  // ==========================================================

  Map<String, dynamic> toMap() {
    return {
      'OwnerName': ownerName,
      'Walkid': walkId,
      'currentLat': currentLat,
      'currentLng': currentLng,
      'distance': distance,
      'duration': duration,
      'ownerId': ownerId,
      'petAge': petAge,
      'petBreed': petBreed,
      'petName': petName,
      'status': status,
      'walkerName': walkerName,
      'walkerId': walkerId,
    };
  }

  // ==========================================================
  // STRING HELPER
  // ==========================================================

  static String _stringValue(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  // ==========================================================
  // DOUBLE HELPER
  // ==========================================================

  static double? _doubleValue(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    if (value == null) {
      return null;
    }

    return double.tryParse(
      value.toString(),
    );
  }
}

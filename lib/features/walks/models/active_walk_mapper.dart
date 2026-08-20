import 'active_walk.dart';

class ActiveWalkMapper {
  ActiveWalkMapper._();

  // ==========================================================
  // FIRESTORE MAP → ACTIVE WALK
  // ==========================================================

  static ActiveWalk fromMap(
    String documentId,
    Map<String, dynamic> data,
  ) {
    return ActiveWalk.fromMap(
      documentId,
      data,
    );
  }

  // ==========================================================
  // ACTIVE WALK → FIRESTORE MAP
  // ==========================================================

  static Map<String, dynamic> toMap(
    ActiveWalk activeWalk,
  ) {
    return activeWalk.toMap();
  }
}

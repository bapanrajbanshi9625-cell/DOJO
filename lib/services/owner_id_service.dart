import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerIdService {
  OwnerIdService._();

  static final OwnerIdService instance = OwnerIdService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // COLLECTIONS
  // ============================================================

  static const String _phoneAccountsCollection =
      'phoneAccounts';

  static const String _ownerProfilesCollection =
      'ownerProfiles';

  static const String _countersCollection =
      'counters';

  static const String _ownerCounterDocument = 'owner';

  // ============================================================
  // GET OR CREATE OWNER ID
  // ============================================================

  Future<String> getOrCreateOwnerId({
    required String uid,
    required String phoneNumber,
  }) async {
    final String cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      throw Exception('Firebase UID is empty.');
    }

    // ==========================================================
    // PHONE ACCOUNT REFERENCE
    // ==========================================================

    final DocumentReference<Map<String, dynamic>>
        phoneAccountRef = _firestore
            .collection(_phoneAccountsCollection)
            .doc(cleanUid);

    // ==========================================================
    // CHECK EXISTING OWNER ID
    // ==========================================================

    final DocumentSnapshot<Map<String, dynamic>>
        phoneAccount = await phoneAccountRef.get();

    if (phoneAccount.exists) {
      final Map<String, dynamic>? data =
          phoneAccount.data();

      final dynamic existingOwnerId =
          data?['ownerId'];

      final dynamic existingRole =
          data?['role'];

      if (existingRole == 'owner' &&
          existingOwnerId is String &&
          existingOwnerId.trim().isNotEmpty) {
        return existingOwnerId.trim();
      }
    }

    // ==========================================================
    // CREATE OWNER ID
    // ==========================================================

    return await _firestore.runTransaction<String>(
      (transaction) async {
        // ------------------------------------------------------
        // COUNTER REFERENCE
        // ------------------------------------------------------

        final DocumentReference<Map<String, dynamic>>
            counterRef = _firestore
                .collection(_countersCollection)
                .doc(_ownerCounterDocument);

        // ------------------------------------------------------
        // READ COUNTER
        // ------------------------------------------------------

        final DocumentSnapshot<Map<String, dynamic>>
            counterSnapshot =
            await transaction.get(counterRef);

        int lastSerial = 0;

        if (counterSnapshot.exists) {
          final dynamic value =
              counterSnapshot.data()?['lastSerial'];

          if (value is int) {
            lastSerial = value;
          } else if (value is num) {
            lastSerial = value.toInt();
          }
        }

        // ------------------------------------------------------
        // NEXT SERIAL
        // ------------------------------------------------------

        final int nextSerial = lastSerial + 1;

        if (nextSerial > 9999) {
          throw Exception(
            'Owner ID serial limit reached.',
          );
        }

        // ------------------------------------------------------
        // DATE
        // ------------------------------------------------------

        final DateTime now = DateTime.now();

        // Example: 2026 -> 26
        final String year =
            (now.year % 100)
                .toString()
                .padLeft(2, '0');

        // ------------------------------------------------------
        // MONTH CODE
        // ------------------------------------------------------

        const List<String> monthCodes = [
          'J', // January
          'F', // February
          'M', // March
          'A', // April
          'Y', // May
          'U', // June
          'L', // July
          'G', // August
          'S', // September
          'O', // October
          'N', // November
          'D', // December
        ];

        final String monthCode =
            monthCodes[now.month - 1];

        // ------------------------------------------------------
        // DAY CODE
        // ------------------------------------------------------

        const List<String> dayCodes = [
          'M', // Monday
          'T', // Tuesday
          'W', // Wednesday
          'H', // Thursday
          'F', // Friday
          'A', // Saturday
          'S', // Sunday
        ];

        final String dayCode =
            dayCodes[now.weekday - 1];

        // ------------------------------------------------------
        // SERIAL
        // ------------------------------------------------------

        final String serial =
            nextSerial
                .toString()
                .padLeft(4, '0');

        // ======================================================
        // FINAL OWNER ID
        // ======================================================
        //
        // OWN + YY + MONTH + DAY + SERIAL
        //
        // Example:
        //
        // OWN26GM0001
        //
        // Total = 11 characters
        // ======================================================

        final String ownerId =
            'OWN$year$monthCode$dayCode$serial';

        // ------------------------------------------------------
        // OWNER PROFILE REFERENCE
        // ------------------------------------------------------

        final DocumentReference<Map<String, dynamic>>
            ownerProfileRef = _firestore
                .collection(_ownerProfilesCollection)
                .doc(ownerId);

        // ------------------------------------------------------
        // UPDATE COUNTER
        // ------------------------------------------------------

        transaction.set(
          counterRef,
          {
            'lastSerial': nextSerial,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        // ------------------------------------------------------
        // CREATE OWNER PROFILE
        // ------------------------------------------------------

        transaction.set(
          ownerProfileRef,
          {
            'ownerId': ownerId,
            'authUid': cleanUid,
            'phone': phoneNumber.trim(),
            'role': 'owner',
            'createdAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        // ------------------------------------------------------
        // CREATE PHONE ACCOUNT
        // ------------------------------------------------------

        transaction.set(
          phoneAccountRef,
          {
            'authUid': cleanUid,
            'phone': phoneNumber.trim(),
            'role': 'owner',
            'ownerId': ownerId,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        return ownerId;
      },
    );
  }

  // ============================================================
  // GET EXISTING OWNER ID
  // ============================================================

  Future<String?> getExistingOwnerId({
    required String uid,
  }) async {
    final String cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>>
        snapshot = await _firestore
            .collection(_phoneAccountsCollection)
            .doc(cleanUid)
            .get();

    if (!snapshot.exists) {
      return null;
    }

    final Map<String, dynamic>? data =
        snapshot.data();

    final dynamic ownerId =
        data?['ownerId'];

    if (ownerId is String &&
        ownerId.trim().isNotEmpty) {
      return ownerId.trim();
    }

    return null;
  }
}

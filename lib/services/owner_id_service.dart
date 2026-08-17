import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerIdService {
  OwnerIdService._();

  static final OwnerIdService instance =
      OwnerIdService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // COLLECTION NAMES
  // ============================================================

  static const String _phoneAccountsCollection =
      'phoneAccounts';

  static const String _ownerProfilesCollection =
      'ownerProfiles';

  static const String _countersCollection =
      'counters';

  static const String _ownerCounterDocument =
      'owner';

  // ============================================================
  // GET OR CREATE OWNER ID
  // ============================================================

  Future<String> getOrCreateOwnerId({
    required String uid,
    required String phoneNumber,
  }) async {
    final String cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      throw Exception(
        'Firebase UID is empty.',
      );
    }

    // ==========================================================
    // 1. CHECK EXISTING PHONE ACCOUNT
    // ==========================================================

    final DocumentReference<Map<String, dynamic>>
        phoneAccountRef = _firestore
            .collection(_phoneAccountsCollection)
            .doc(cleanUid);

    final DocumentSnapshot<Map<String, dynamic>>
        phoneAccount =
        await phoneAccountRef.get();

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
    // 2. CREATE OWNER ID USING TRANSACTION
    // ==========================================================

    final String ownerId =
        await _firestore.runTransaction<String>(
      (transaction) async {
        // ------------------------------------------------------
        // REFERENCES
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

        final int nextSerial =
            lastSerial + 1;

        if (nextSerial > 9999) {
          throw Exception(
            'Owner ID serial limit reached.',
          );
        }

        // ------------------------------------------------------
        // DATE PARTS
        // ------------------------------------------------------

        final DateTime now =
            DateTime.now();

        // Last two digits of year.
        final String year =
            (now.year % 100)
                .toString()
                .padLeft(2, '0');

        // Month:
        //
        // January  = J
        // February = F
        // March    = M
        // April    = A
        // May      = Y
        // June     = U
        // July     = L
        // August   = G
        // September= S
        // October  = O
        // November = N
        // December = D
        //
        // Unique letters are used so months don't collide.

        const List<String> monthCodes = [
          'J',
          'F',
          'M',
          'A',
          'Y',
          'U',
          'L',
          'G',
          'S',
          'O',
          'N',
          'D',
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

        // ------------------------------------------------------
        // FINAL OWNER ID
        // ======================================================
        //
        // OWN + YY + MONTH + DAY + 4 DIGIT SERIAL
        //
        // Example:
        //
        // OWN26GM0001
        //
        // NOTE:
        // This format is 11 characters.
        //
        // OWN = 3
        // 26  = 2
        // G   = 1
        // M   = 1
        // 0001= 4
        //
        // Total = 11
        //
        // ------------------------------------------------------

        final String newOwnerId =
            'OWN$year$monthCode$dayCode$serial';

        // ------------------------------------------------------
        // OWNER PROFILE
        // ------------------------------------------------------

        final DocumentReference<Map<String, dynamic>>
            ownerProfileRef = _firestore
                .collection(_ownerProfilesCollection)
                .doc(newOwnerId);

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
        // SAVE OWNER PROFILE
        // ------------------------------------------------------

        transaction.set(
          ownerProfileRef,
          {
            'ownerId': newOwnerId,
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
        // SAVE PHONE ACCOUNT
        // ------------------------------------------------------

        transaction.set(
          phoneAccountRef,
          {
            'authUid': cleanUid,
            'phone': phoneNumber.trim(),
            'role': 'owner',
            'ownerId': newOwnerId,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        return newOwnerId;
      },
    );

    return ownerId;
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

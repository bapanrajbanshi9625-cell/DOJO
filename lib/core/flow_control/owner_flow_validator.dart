// File location:
// lib/core/flow_control/owner_flow_validator.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ============================================================
/// OWNER FLOW VALIDATOR
/// ============================================================
///
/// Purpose:
/// - Validate the complete Owner app flow.
/// - Detect Auth / Profile / Walk / Insta Walk mismatches.
/// - Produce structured diagnostic reports.
///
/// IMPORTANT:
/// - Read-only.
/// - Does NOT modify Firestore.
/// - Does NOT modify navigation.
/// - Does NOT modify user data.
/// - Safe to call from debug/admin diagnostics.
///
/// ============================================================

enum OwnerFlowIssueSeverity {
  info,
  warning,
  error,
}

/// ============================================================
/// FLOW ISSUE
/// ============================================================

class OwnerFlowIssue {
  final String code;
  final OwnerFlowIssueSeverity severity;
  final String message;
  final String? path;
  final Map<String, dynamic> details;

  const OwnerFlowIssue({
    required this.code,
    required this.severity,
    required this.message,
    this.path,
    this.details = const {},
  });

  bool get isError =>
      severity == OwnerFlowIssueSeverity.error;

  bool get isWarning =>
      severity == OwnerFlowIssueSeverity.warning;

  bool get isInfo =>
      severity == OwnerFlowIssueSeverity.info;

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'severity': severity.name,
      'message': message,
      'path': path,
      'details': details,
    };
  }

  @override
  String toString() {
    return '[${severity.name.toUpperCase()}] '
        '$code: $message'
        '${path == null ? '' : ' ($path)'}';
  }
}

/// ============================================================
/// VALIDATION REPORT
/// ============================================================

class OwnerFlowValidationReport {
  final DateTime checkedAt;
  final List<OwnerFlowIssue> issues;

  const OwnerFlowValidationReport({
    required this.checkedAt,
    required this.issues,
  });

  bool get hasErrors =>
      issues.any(
        (issue) =>
            issue.severity ==
            OwnerFlowIssueSeverity.error,
      );

  bool get hasWarnings =>
      issues.any(
        (issue) =>
            issue.severity ==
            OwnerFlowIssueSeverity.warning,
      );

  bool get isHealthy =>
      !hasErrors;

  int get errorCount =>
      issues
          .where(
            (issue) =>
                issue.severity ==
                OwnerFlowIssueSeverity.error,
          )
          .length;

  int get warningCount =>
      issues
          .where(
            (issue) =>
                issue.severity ==
                OwnerFlowIssueSeverity.warning,
          )
          .length;

  int get infoCount =>
      issues
          .where(
            (issue) =>
                issue.severity ==
                OwnerFlowIssueSeverity.info,
          )
          .length;

  Map<String, dynamic> toMap() {
    return {
      'checkedAt': checkedAt.toIso8601String(),
      'healthy': isHealthy,
      'hasErrors': hasErrors,
      'hasWarnings': hasWarnings,
      'errorCount': errorCount,
      'warningCount': warningCount,
      'infoCount': infoCount,
      'issues': issues
          .map(
            (issue) => issue.toMap(),
          )
          .toList(),
    };
  }

  String get summary {
    if (hasErrors) {
      return 'Owner flow has $errorCount error(s) '
          'and $warningCount warning(s).';
    }

    if (hasWarnings) {
      return 'Owner flow is functional with '
          '$warningCount warning(s).';
    }

    return 'Owner flow is healthy.';
  }
}

/// ============================================================
/// OWNER FLOW VALIDATOR
/// ============================================================

class OwnerFlowValidator {
  OwnerFlowValidator({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth =
            auth ?? FirebaseAuth.instance,
        _firestore =
            firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// ----------------------------------------------------------
  /// MAIN VALIDATION
  /// ----------------------------------------------------------

  Future<OwnerFlowValidationReport> validate() async {
    final List<OwnerFlowIssue> issues = [];

    final DateTime checkedAt =
        DateTime.now();

    // ==========================================================
    // 1. AUTH
    // ==========================================================

    final User? user = _auth.currentUser;

    if (user == null) {
      issues.add(
        const OwnerFlowIssue(
          code: 'AUTH_USER_MISSING',
          severity:
              OwnerFlowIssueSeverity.error,
          message:
              'No authenticated Firebase user was found.',
          path: 'FirebaseAuth.currentUser',
        ),
      );

      return OwnerFlowValidationReport(
        checkedAt: checkedAt,
        issues: issues,
      );
    }

    issues.add(
      OwnerFlowIssue(
        code: 'AUTH_OK',
        severity:
            OwnerFlowIssueSeverity.info,
        message:
            'Authenticated Firebase user found.',
        details: {
          'uid': user.uid,
          'phoneVerified':
              user.phoneNumber != null,
        },
      ),
    );

    // ==========================================================
    // 2. OWNER PROFILE
    // ==========================================================

    DocumentSnapshot<Map<String, dynamic>>? ownerDoc;

    try {
      ownerDoc =
          await _findOwnerDocument(user.uid);
    } catch (e) {
      issues.add(
        OwnerFlowIssue(
          code: 'OWNER_PROFILE_READ_FAILED',
          severity:
              OwnerFlowIssueSeverity.error,
          message:
              'Unable to read the Owner profile.',
          path: 'owners',
          details: {
            'error': e.toString(),
          },
        ),
      );

      return OwnerFlowValidationReport(
        checkedAt: checkedAt,
        issues: issues,
      );
    }

    if (ownerDoc == null ||
        !ownerDoc.exists) {
      issues.add(
        const OwnerFlowIssue(
          code: 'OWNER_PROFILE_MISSING',
          severity:
              OwnerFlowIssueSeverity.error,
          message:
              'Owner profile document was not found.',
          path: 'owners',
        ),
      );

      return OwnerFlowValidationReport(
        checkedAt: checkedAt,
        issues: issues,
      );
    }

    issues.add(
      OwnerFlowIssue(
        code: 'OWNER_PROFILE_OK',
        severity:
            OwnerFlowIssueSeverity.info,
        message:
            'Owner profile document found.',
        path: 'owners/${ownerDoc.id}',
      ),
    );

    final Map<String, dynamic> ownerData =
        ownerDoc.data() ?? {};

    // ==========================================================
    // 3. OWNER ID
    // ==========================================================

    final String ownerId =
        _readString(
      ownerData,
      const [
        'ownerId',
        'Owner ID',
        'uid',
        'Uid',
      ],
    );

    if (ownerId.isEmpty) {
      issues.add(
        const OwnerFlowIssue(
          code: 'OWNER_ID_MISSING',
          severity:
              OwnerFlowIssueSeverity.error,
          message:
              'Owner ID is missing from the Owner profile.',
          path: 'ownerId',
        ),
      );
    } else if (ownerId != user.uid) {
      issues.add(
        OwnerFlowIssue(
          code: 'OWNER_ID_MISMATCH',
          severity:
              OwnerFlowIssueSeverity.error,
          message:
              'Owner profile ID does not match authenticated UID.',
          path: 'ownerId',
          details: {
            'firebaseUid': user.uid,
            'profileOwnerId': ownerId,
          },
        ),
      );
    } else {
      issues.add(
        const OwnerFlowIssue(
          code: 'OWNER_ID_OK',
          severity:
              OwnerFlowIssueSeverity.info,
          message:
              'Owner ID matches authenticated UID.',
        ),
      );
    }

    // ==========================================================
    // 4. OWNER NAME
    // ==========================================================

    final String ownerName =
        _readString(
      ownerData,
      const [
        'fullName',
        'Full Name',
        'ownerName',
        'Owner Name',
        'name',
      ],
    );

    if (ownerName.isEmpty) {
      issues.add(
        const OwnerFlowIssue(
          code: 'OWNER_NAME_MISSING',
          severity:
              OwnerFlowIssueSeverity.warning,
          message:
              'Owner name is missing.',
          path: 'fullName',
        ),
      );
    }

    // ==========================================================
    // 5. ADDRESS
    // ==========================================================

    final String address =
        _readString(
      ownerData,
      const [
        'address',
        'Address',
        'Adress',
      ],
    );

    if (address.isEmpty) {
      issues.add(
        const OwnerFlowIssue(
          code: 'OWNER_ADDRESS_MISSING',
          severity:
              OwnerFlowIssueSeverity.warning,
          message:
              'Owner address is missing.',
          path: 'address',
        ),
      );
    } else {
      issues.add(
        const OwnerFlowIssue(
          code: 'OWNER_ADDRESS_OK',
          severity:
              OwnerFlowIssueSeverity.info,
          message:
              'Owner address is available.',
        ),
      );
    }

    // ==========================================================
    // 6. PET
    // ==========================================================

    final String petName =
        _readString(
      ownerData,
      const [
        'petName',
        'Pet Name',
        'dogName',
        'Dog Name',
      ],
    );

    if (petName.isEmpty) {
      issues.add(
        const OwnerFlowIssue(
          code: 'PET_NAME_MISSING',
          severity:
              OwnerFlowIssueSeverity.warning,
          message:
              'Pet/Dog name is missing.',
          path: 'petName',
        ),
      );
    }

    // ==========================================================
    // 7. PROFILE COMPLETION
    // ==========================================================

    final dynamic profileCompleted =
        ownerData['profileCompleted'];

    if (profileCompleted == null) {
      issues.add(
        const OwnerFlowIssue(
          code: 'PROFILE_COMPLETION_MISSING',
          severity:
              OwnerFlowIssueSeverity.warning,
          message:
              'profileCompleted field is missing.',
          path: 'profileCompleted',
        ),
      );
    } else if (profileCompleted != true) {
      issues.add(
        OwnerFlowIssue(
          code: 'PROFILE_NOT_COMPLETED',
          severity:
              OwnerFlowIssueSeverity.warning,
          message:
              'Owner profile is not marked as completed.',
          path: 'profileCompleted',
          details: {
            'value': profileCompleted,
          },
        ),
      );
    } else {
      issues.add(
        const OwnerFlowIssue(
          code: 'PROFILE_COMPLETED_OK',
          severity:
              OwnerFlowIssueSeverity.info,
          message:
              'Owner profile is marked completed.',
        ),
      );
    }

    // ==========================================================
    // 8. ACTIVE WALKS
    // ==========================================================

    await _validateActiveWalks(
      ownerId: ownerId,
      issues: issues,
    );

    // ==========================================================
    // 9. INSTA WALK
    // ==========================================================

    await _validateInstaWalk(
      ownerId: ownerId,
      issues: issues,
    );

    // ==========================================================
    // 10. FINAL REPORT
    // ==========================================================

    return OwnerFlowValidationReport(
      checkedAt: checkedAt,
      issues: List.unmodifiable(issues),
    );
  }

  /// ----------------------------------------------------------
  /// FIND OWNER DOCUMENT
  /// ----------------------------------------------------------

  Future<DocumentSnapshot<Map<String, dynamic>>?>
      _findOwnerDocument(
    String uid,
  ) async {
    // ==========================================================
    // DIRECT UID DOCUMENT
    // ==========================================================

    final DocumentSnapshot<Map<String, dynamic>>
        direct =
        await _firestore
            .collection('owners')
            .doc(uid)
            .get();

    if (direct.exists) {
      return direct;
    }

    // ==========================================================
    // QUERY BY OWNER ID
    // ==========================================================

    final QuerySnapshot<Map<String, dynamic>>
        query =
        await _firestore
            .collection('owners')
            .where(
              'ownerId',
              isEqualTo: uid,
            )
            .limit(1)
            .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first;
    }

    // ==========================================================
    // FALLBACK LEGACY FIELD
    // ==========================================================

    final QuerySnapshot<Map<String, dynamic>>
        legacy =
        await _firestore
            .collection('owners')
            .where(
              'Owner ID',
              isEqualTo: uid,
            )
            .limit(1)
            .get();

    if (legacy.docs.isNotEmpty) {
      return legacy.docs.first;
    }

    return null;
  }

  /// ----------------------------------------------------------
  /// ACTIVE WALKS VALIDATION
  /// ----------------------------------------------------------

  Future<void> _validateActiveWalks({
    required String ownerId,
    required List<OwnerFlowIssue> issues,
  }) async {
    try {
      final QuerySnapshot<Map<String, dynamic>>
          snapshot =
          await _firestore
              .collection('active_walks')
              .where(
                'ownerId',
                isEqualTo: ownerId,
              )
              .limit(10)
              .get();

      if (snapshot.docs.isEmpty) {
        issues.add(
          const OwnerFlowIssue(
            code: 'ACTIVE_WALK_NONE',
            severity:
                OwnerFlowIssueSeverity.info,
            message:
                'No active walk found for this Owner.',
            path: 'active_walks',
          ),
        );

        return;
      }

      int activeCount = 0;

      for (final QueryDocumentSnapshot<Map<String, dynamic>>
          doc in snapshot.docs) {
        final Map<String, dynamic> data =
            doc.data();

        final String status =
            _readString(
          data,
          const [
            'status',
            'Status',
            'walkStatus',
            'Walk Status',
          ],
        ).toLowerCase();

        if (_isActiveStatus(status)) {
          activeCount++;
        }
      }

      if (activeCount > 1) {
        issues.add(
          OwnerFlowIssue(
            code: 'MULTIPLE_ACTIVE_WALKS',
            severity:
                OwnerFlowIssueSeverity.warning,
            message:
                'More than one active walk was found.',
            path: 'active_walks',
            details: {
              'activeCount': activeCount,
            },
          ),
        );
      } else {
        issues.add(
          OwnerFlowIssue(
            code: 'ACTIVE_WALK_STATE_OK',
            severity:
                OwnerFlowIssueSeverity.info,
            message:
                'Active walk state is consistent.',
            details: {
              'activeCount': activeCount,
            },
          ),
        );
      }
    } catch (e) {
      issues.add(
        OwnerFlowIssue(
          code: 'ACTIVE_WALK_VALIDATION_FAILED',
          severity:
              OwnerFlowIssueSeverity.warning,
          message:
              'Unable to validate active walks.',
          path: 'active_walks',
          details: {
            'error': e.toString(),
          },
        ),
      );
    }
  }

  /// ----------------------------------------------------------
  /// INSTA WALK VALIDATION
  /// ----------------------------------------------------------

  Future<void> _validateInstaWalk({
    required String ownerId,
    required List<OwnerFlowIssue> issues,
  }) async {
    try {
      final QuerySnapshot<Map<String, dynamic>>
          snapshot =
          await _firestore
              .collection('walk_requests')
              .where(
                'ownerId',
                isEqualTo: ownerId,
              )
              .limit(10)
              .get();

      if (snapshot.docs.isEmpty) {
        issues.add(
          const OwnerFlowIssue(
            code: 'INSTA_WALK_NONE',
            severity:
                OwnerFlowIssueSeverity.info,
            message:
                'No Insta Walk request found.',
            path: 'walk_requests',
          ),
        );

        return;
      }

      int searching = 0;
      int accepted = 0;
      int finished = 0;

      for (final QueryDocumentSnapshot<Map<String, dynamic>>
          doc in snapshot.docs) {
        final Map<String, dynamic> data =
            doc.data();

        final String status =
            _readString(
          data,
          const [
            'status',
            'Status',
            'requestStatus',
            'Request Status',
          ],
        ).toLowerCase();

        if (_isSearchingStatus(status)) {
          searching++;
        } else if (_isAcceptedStatus(status)) {
          accepted++;
        } else {
          finished++;
        }

        _validateRequestDocument(
          doc.id,
          data,
          issues,
        );
      }

      if (searching > 1) {
        issues.add(
          OwnerFlowIssue(
            code: 'MULTIPLE_SEARCHING_REQUESTS',
            severity:
                OwnerFlowIssueSeverity.error,
            message:
                'Multiple active Insta Walk searching requests were found.',
            path: 'walk_requests',
            details: {
              'searchingCount': searching,
            },
          ),
        );
      }

      if (searching > 0 &&
          accepted > 0) {
        issues.add(
          const OwnerFlowIssue(
            code: 'SEARCH_ACCEPTED_STATE_MISMATCH',
            severity:
                OwnerFlowIssueSeverity.error,
            message:
                'Owner has both searching and accepted Insta Walk states.',
            path: 'walk_requests',
          ),
        );
      }

      issues.add(
        OwnerFlowIssue(
          code: 'INSTA_WALK_STATE_CHECKED',
          severity:
              OwnerFlowIssueSeverity.info,
          message:
              'Insta Walk request states checked.',
          details: {
            'searching': searching,
            'accepted': accepted,
            'finished': finished,
          },
        ),
      );
    } catch (e) {
      issues.add(
        OwnerFlowIssue(
          code: 'INSTA_WALK_VALIDATION_FAILED',
          severity:
              OwnerFlowIssueSeverity.warning,
          message:
              'Unable to validate Insta Walk requests.',
          path: 'walk_requests',
          details: {
            'error': e.toString(),
          },
        ),
      );
    }
  }

  /// ----------------------------------------------------------
  /// REQUEST DOCUMENT VALIDATION
  /// ----------------------------------------------------------

  void _validateRequestDocument(
    String requestId,
    Map<String, dynamic> data,
    List<OwnerFlowIssue> issues,
  ) {
    // ==========================================================
    // REQUEST ID
    // ==========================================================

    final String storedRequestId =
        _readString(
      data,
      const [
        'requestId',
        'Request ID',
      ],
    );

    if (storedRequestId.isEmpty) {
      issues.add(
        OwnerFlowIssue(
          code: 'REQUEST_ID_MISSING',
          severity:
              OwnerFlowIssueSeverity.warning,
          message:
              'Insta Walk request has no requestId field.',
          path:
              'walk_requests/$requestId/requestId',
        ),
      );
    } else if (storedRequestId != requestId) {
      issues.add(
        OwnerFlowIssue(
          code: 'REQUEST_ID_MISMATCH',
          severity:
              OwnerFlowIssueSeverity.error,
          message:
              'Firestore document ID does not match requestId.',
          path:
              'walk_requests/$requestId/requestId',
          details: {
            'documentId': requestId,
            'requestId': storedRequestId,
          },
        ),
      );
    }

    // ==========================================================
    // OWNER ID
    // ==========================================================

    final String requestOwnerId =
        _readString(
      data,
      const [
        'ownerId',
        'Owner ID',
      ],
    );

    if (requestOwnerId.isEmpty) {
      issues.add(
        OwnerFlowIssue(
          code: 'REQUEST_OWNER_ID_MISSING',
          severity:
              OwnerFlowIssueSeverity.error,
          message:
              'Insta Walk request has no ownerId.',
          path:
              'walk_requests/$requestId/ownerId',
        ),
      );
    }

    // ==========================================================
    // EXPIRATION
    // ==========================================================

    final dynamic expiresAt =
        data['expiresAt'];

    if (expiresAt == null) {
      issues.add(
        OwnerFlowIssue(
          code: 'REQUEST_EXPIRY_MISSING',
          severity:
              OwnerFlowIssueSeverity.warning,
          message:
              'Insta Walk request has no expiresAt.',
          path:
              'walk_requests/$requestId/expiresAt',
        ),
      );
    }
  }

  /// ----------------------------------------------------------
  /// STRING READER
  /// ----------------------------------------------------------

  String _readString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final dynamic value = data[key];

      if (value == null) {
        continue;
      }

      final String text =
          value.toString().trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }

  /// ----------------------------------------------------------
  /// STATUS HELPERS
  /// ----------------------------------------------------------

  bool _isActiveStatus(
    String status,
  ) {
    const List<String> values = [
      'searching',
      'accepted',
      'active',
      'started',
      'in_progress',
      'in progress',
    ];

    return values.contains(status);
  }

  bool _isSearchingStatus(
    String status,
  ) {
    const List<String> values = [
      'searching',
      'pending',
      'requested',
    ];

    return values.contains(status);
  }

  bool _isAcceptedStatus(
    String status,
  ) {
    const List<String> values = [
      'accepted',
      'active',
      'started',
      'in_progress',
      'in progress',
    ];

    return values.contains(status);
  }
}

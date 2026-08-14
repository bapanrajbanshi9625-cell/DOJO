import 'package:cloud_firestore/cloud_firestore.dart';

class WalkModel {
  final String id;
  final String dogName;
  final String walkerName;
  final String status;
  final DateTime date;

  WalkModel({
    required this.id,
    required this.dogName,
    required this.walkerName,
    required this.status,
    required this.date,
  });

  factory WalkModel.fromFirestore(
    DocumentSnapshot doc,
  ) {
    final data =
        doc.data() as Map<String, dynamic>;

    DateTime date = DateTime.now();

    final value =
        data['createdAt'] ??
        data['date'] ??
        data['walkDate'];

    if (value is Timestamp) {
      date = value.toDate();
    }

    return WalkModel(
      id: doc.id,
      dogName:
          data['dogName']?.toString() ??
          data['petName']?.toString() ??
          'Walk',
      walkerName:
          data['walkerName']?.toString() ??
          'Walker',
      status:
          data['status']?.toString() ??
          'Completed',
      date: date,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_wallert/services/firestore_service.dart';

class Bank implements FirestoreModel {
  @override
  final String? id;
  final String bankName;
  final String userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Bank({
    this.id,
    required this.bankName,
    required this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory Bank.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Bank(
      id: doc.id,
      bankName: data['bankName'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'bankName': bankName,
      'userId': userId,
      'createdAt': createdAt != null 
          ? Timestamp.fromDate(createdAt!) 
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Bank copyWith({
    String? id,
    String? bankName,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bank(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
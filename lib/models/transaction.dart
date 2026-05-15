import 'package:cloud_firestore/cloud_firestore.dart';

class ArdentTransaction {
  final String id;
  final String type; // 'Award', 'Purchase', 'Penalty'
  final int amount;
  final String description;
  final DateTime timestamp;
  final String issuer;

  ArdentTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.timestamp,
    required this.issuer,
  });

  factory ArdentTransaction.fromMap(Map<String, dynamic> data, String id) {
    return ArdentTransaction(
      id: id,
      type: data['type'] ?? 'Award',
      amount: data['amount'] ?? 0,
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      issuer: data['issuer'] ?? 'System',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'amount': amount,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
      'issuer': issuer,
    };
  }
}

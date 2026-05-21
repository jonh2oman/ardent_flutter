import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionCurrency { merits, cash }

class ArdentTransaction {
  final String id;
  final String type; // 'Award', 'Purchase', 'Penalty', 'Deposit', 'Withdrawal'
  final double amount;
  final String description;
  final DateTime timestamp;
  final String issuer;
  final TransactionCurrency currency;

  ArdentTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.timestamp,
    required this.issuer,
    this.currency = TransactionCurrency.merits,
  });

  factory ArdentTransaction.fromMap(Map<String, dynamic> data, String id) {
    return ArdentTransaction(
      id: id,
      type: data['type'] ?? 'Award',
      amount: (data['amount'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      timestamp: data['timestamp'] != null 
          ? (data['timestamp'] as Timestamp).toDate() 
          : DateTime.now(),
      issuer: data['issuer'] ?? 'System',
      currency: data['currency'] == 'cash' ? TransactionCurrency.cash : TransactionCurrency.merits,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'amount': amount,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
      'issuer': issuer,
      'currency': currency == TransactionCurrency.cash ? 'cash' : 'merits',
    };
  }
}

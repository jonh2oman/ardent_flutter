import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class BankLedgerEntry {
  final String id;
  final double balance;
  final DateTime date;
  final String notes;
  final String reportedBy;

  BankLedgerEntry({
    required this.id,
    required this.balance,
    required this.date,
    this.notes = '',
    required this.reportedBy,
  });

  factory BankLedgerEntry.create({
    required double balance,
    required DateTime date,
    String notes = '',
    required String reportedBy,
  }) {
    return BankLedgerEntry(
      id: const Uuid().v4(),
      balance: balance,
      date: date,
      notes: notes,
      reportedBy: reportedBy,
    );
  }

  factory BankLedgerEntry.fromMap(Map<String, dynamic> data, String id) {
    DateTime parsedDate;
    final rawDate = data['date'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return BankLedgerEntry(
      id: id,
      balance: (data['balance'] ?? 0.0).toDouble(),
      date: parsedDate,
      notes: data['notes'] ?? '',
      reportedBy: data['reportedBy'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'balance': balance,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'reportedBy': reportedBy,
    };
  }
}

class BankLedger {
  final List<BankLedgerEntry> history;

  BankLedger({required this.history});

  factory BankLedger.fromMap(Map<String, dynamic> data) {
    final rawHistory = data['history'] as List<dynamic>? ?? [];
    final list = rawHistory.map((item) {
      final m = Map<String, dynamic>.from(item);
      return BankLedgerEntry.fromMap(m, m['id'] ?? const Uuid().v4());
    }).toList();

    // Sort descending by date so that index 0 is always the newest balance
    list.sort((a, b) => b.date.compareTo(a.date));

    return BankLedger(history: list);
  }

  Map<String, dynamic> toMap() {
    return {
      'history': history.map((e) => e.toMap()).toList(),
    };
  }

  double get currentBalance => history.isNotEmpty ? history.first.balance : 0.0;
  DateTime? get lastUpdated => history.isNotEmpty ? history.first.date : null;
}

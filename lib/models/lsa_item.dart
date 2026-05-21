import 'package:cloud_firestore/cloud_firestore.dart';

class LsaItem {
  final String id;
  final String name;
  final String description;
  final int quantity;
  final double unitPrice;
  final String link;
  final String imageUrl;
  final DateTime timestamp;

  LsaItem({
    required this.id,
    required this.name,
    this.description = '',
    required this.quantity,
    required this.unitPrice,
    this.link = '',
    this.imageUrl = '',
    required this.timestamp,
  });

  factory LsaItem.fromMap(String id, Map<String, dynamic> data) {
    return LsaItem(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      quantity: data['quantity'] ?? 1,
      unitPrice: (data['unitPrice'] ?? 0.0).toDouble(),
      link: data['link'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'link': link,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

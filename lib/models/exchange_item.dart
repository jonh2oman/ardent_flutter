import 'package:cloud_firestore/cloud_firestore.dart';

enum PriceType { merits, cash }

class ExchangeItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final PriceType priceType;
  final String category;
  final String? imageUrl;
  final int stock;
  final bool isActive;

  ExchangeItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.priceType,
    required this.category,
    this.imageUrl,
    this.stock = 0,
    this.isActive = true,
  });

  factory ExchangeItem.fromMap(Map<String, dynamic> data, String id) {
    PriceType parsedPriceType = PriceType.merits;
    final rawPriceType = data['priceType'];
    if (rawPriceType is int) {
      if (rawPriceType >= 0 && rawPriceType < PriceType.values.length) {
        parsedPriceType = PriceType.values[rawPriceType];
      }
    } else if (rawPriceType is String) {
      if (rawPriceType.toLowerCase() == 'cash' || rawPriceType == '1') {
        parsedPriceType = PriceType.cash;
      } else {
        parsedPriceType = PriceType.merits;
      }
    }

    return ExchangeItem(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      priceType: parsedPriceType,
      category: data['category'] ?? 'General',
      imageUrl: data['imageUrl'],
      stock: (data['stock'] ?? 0).toInt(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'priceType': priceType.index,
      'category': category,
      'imageUrl': imageUrl,
      'stock': stock,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ExchangeItem copyWith({
    String? name,
    String? description,
    double? price,
    PriceType? priceType,
    String? category,
    String? imageUrl,
    int? stock,
    bool? isActive,
  }) {
    return ExchangeItem(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      priceType: priceType ?? this.priceType,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      stock: stock ?? this.stock,
      isActive: isActive ?? this.isActive,
    );
  }
}

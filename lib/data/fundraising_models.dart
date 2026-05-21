import 'package:cloud_firestore/cloud_firestore.dart';

class FundraisingCampaign {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;

  FundraisingCampaign({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  factory FundraisingCampaign.fromMap(String id, Map<String, dynamic> data) {
    return FundraisingCampaign(
      id: id,
      name: data['name'] ?? '',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
    };
  }
}

class FundraisingProduct {
  final String id;
  final String name;
  final double price;
  final int initialStock;

  FundraisingProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.initialStock,
  });

  factory FundraisingProduct.fromMap(String id, Map<String, dynamic> data) {
    return FundraisingProduct(
      id: id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      initialStock: data['initialStock'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'initialStock': initialStock,
    };
  }
}

class FundraisingAssignment {
  final String id;
  final String cadetId;
  final String productId;
  final int quantity;
  final DateTime timestamp;

  FundraisingAssignment({
    required this.id,
    required this.cadetId,
    required this.productId,
    required this.quantity,
    required this.timestamp,
  });

  factory FundraisingAssignment.fromMap(String id, Map<String, dynamic> data) {
    return FundraisingAssignment(
      id: id,
      cadetId: data['cadetId'] ?? '',
      productId: data['productId'] ?? '',
      quantity: data['quantity'] ?? 0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cadetId': cadetId,
      'productId': productId,
      'quantity': quantity,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class FundraisingReturn {
  final String id;
  final String cadetId;
  final double amountReturned;
  final DateTime timestamp;

  FundraisingReturn({
    required this.id,
    required this.cadetId,
    required this.amountReturned,
    required this.timestamp,
  });

  factory FundraisingReturn.fromMap(String id, Map<String, dynamic> data) {
    return FundraisingReturn(
      id: id,
      cadetId: data['cadetId'] ?? '',
      amountReturned: (data['amountReturned'] ?? 0.0).toDouble(),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cadetId': cadetId,
      'amountReturned': amountReturned,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

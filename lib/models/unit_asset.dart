class UnitAsset {
  final String id;
  final String name;
  final String? description;
  final String? serialNumber;
  final bool isSloc;
  final int quantity;
  final String? assignedTo;
  final String condition;
  final String? notes;
  final String? dueDate;
  final String? recipientType;

  UnitAsset({
    required this.id,
    required this.name,
    this.description,
    this.serialNumber,
    this.isSloc = false,
    this.quantity = 1,
    this.assignedTo,
    this.condition = 'Good',
    this.notes,
    this.dueDate,
    this.recipientType,
  });

  factory UnitAsset.fromMap(Map<String, dynamic> map, String id) {
    return UnitAsset(
      id: id,
      name: map['name'] ?? '',
      description: map['description'],
      serialNumber: map['serialNumber'],
      isSloc: map['isSloc'] ?? false,
      quantity: map['quantity'] ?? 1,
      assignedTo: map['assignedTo'],
      condition: map['condition'] ?? 'Good',
      notes: map['notes'],
      dueDate: map['dueDate'],
      recipientType: map['recipientType'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'serialNumber': serialNumber,
      'isSloc': isSloc,
      'quantity': quantity,
      'assignedTo': assignedTo,
      'condition': condition,
      'notes': notes,
      'dueDate': dueDate,
      'recipientType': recipientType,
    };
  }
}

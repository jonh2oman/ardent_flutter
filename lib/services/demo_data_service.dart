import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class DemoDataService {
  static final _firestore = FirebaseFirestore.instance;
  static const _uuid = Uuid();
  static final _random = Random();

  static const List<String> _firstNames = ['James', 'Mary', 'John', 'Patricia', 'Robert', 'Jennifer', 'Michael', 'Linda', 'William', 'Elizabeth', 'David', 'Barbara', 'Richard', 'Susan', 'Joseph', 'Jessica', 'Thomas', 'Sarah', 'Charles', 'Karen'];
  static const List<String> _lastNames = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson', 'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin'];
  static const List<String> _ranks = ['OCdt', 'NCdt', 'AB', 'LS', 'PO2', 'PO1', 'CPO2', 'CPO1'];
  static const List<String> _divisions = ['Main Deck', 'Quarterdeck', 'Forecastle', 'Aft Deck'];

  static Future<void> loadDemoData(String corpsId) async {
    // 1. Wipe existing data
    await _wipeSubcollections(corpsId);

    // 2. Generate Cadets
    final cadets = _generateCadets(25);
    
    // Update corps doc with cadets
    await _firestore.collection('corps').doc(corpsId).update({
      'settings.cadets': cadets,
    });

    // 3. Generate Uniform Inventory
    await _generateUniformInventory(corpsId);

    // 4. Generate Fundraising Campaigns
    await _generateFundraisingData(corpsId, cadets);
  }

  static Future<void> _wipeSubcollections(String corpsId) async {
    final batch = _firestore.batch();
    
    // Wipe inventory
    final invSnap = await _firestore.collection('corps').doc(corpsId).collection('uniform_inventory').get();
    for (var doc in invSnap.docs) batch.delete(doc.reference);

    // Wipe fundraising campaigns
    final fbSnap = await _firestore.collection('corps').doc(corpsId).collection('fundraising_campaigns').get();
    for (var doc in fbSnap.docs) {
      // Note: we fetch nested collections to delete them
      final pSnap = await doc.reference.collection('products').get();
      for (var p in pSnap.docs) batch.delete(p.reference);
      
      final aSnap = await doc.reference.collection('assignments').get();
      for (var a in aSnap.docs) batch.delete(a.reference);
      
      final rSnap = await doc.reference.collection('returns').get();
      for (var r in rSnap.docs) batch.delete(r.reference);

      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  static List<Map<String, dynamic>> _generateCadets(int count) {
    List<Map<String, dynamic>> cadets = [];
    for (int i = 0; i < count; i++) {
      // DOB between 12 and 18 years ago
      final ageInDays = 12 * 365 + _random.nextInt(6 * 365);
      final dob = DateTime.now().subtract(Duration(days: ageInDays)).toIso8601String();
      
      // CIN: e.g. 1234567
      final cin = (1000000 + _random.nextInt(9000000)).toString();

      cadets.add({
        'id': _uuid.v4(),
        'firstName': _firstNames[_random.nextInt(_firstNames.length)],
        'lastName': _lastNames[_random.nextInt(_lastNames.length)],
        'rank': _ranks[_random.nextInt(_ranks.length)],
        'division': _divisions[_random.nextInt(_divisions.length)],
        'status': 'Active',
        'dob': dob,
        'cin': cin,
      });
    }
    return cadets;
  }

  static Future<void> _generateUniformInventory(String corpsId) async {
    final batch = _firestore.batch();
    final items = [
      {'name': 'Tunic', 'type': 'Jacket', 'sizes': ['34R', '36R', '38R', '40R', '42R']},
      {'name': 'Trousers', 'type': 'Pants', 'sizes': ['28R', '30R', '32R', '34R', '36R']},
      {'name': 'Boots', 'type': 'Footwear', 'sizes': ['7', '8', '9', '10', '11', '12']},
      {'name': 'Wedge', 'type': 'Headwear', 'sizes': ['54', '55', '56', '57', '58']},
      {'name': 'Parka', 'type': 'Outerwear', 'sizes': ['Small', 'Medium', 'Large', 'XL']},
    ];

    for (var item in items) {
      for (var size in item['sizes'] as List<String>) {
        final docRef = _firestore.collection('corps').doc(corpsId).collection('uniform_inventory').doc();
        batch.set(docRef, {
          'itemName': item['name'],
          'category': item['type'],
          'size': size,
          'quantityTotal': 10 + _random.nextInt(20),
          'quantityAssigned': _random.nextInt(10),
          'isArchived': false,
          'condition': 'New',
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    }
    await batch.commit();
  }

  static Future<void> _generateFundraisingData(String corpsId, List<Map<String, dynamic>> cadets) async {
    final campaigns = [
      {'name': 'Spring Chocolate Sale', 'goal': 5000.0, 'products': [
        {'name': 'Almond Bar', 'price': 3.0},
        {'name': 'Caramel Bar', 'price': 3.0},
        {'name': 'Mint Box', 'price': 5.0},
      ]},
      {'name': 'Fall Bottle Drive', 'goal': 2000.0, 'products': [
        {'name': 'Bag of Cans', 'price': 10.0},
        {'name': 'Box of Bottles', 'price': 15.0},
      ]},
    ];

    for (var c in campaigns) {
      final campRef = _firestore.collection('corps').doc(corpsId).collection('fundraising_campaigns').doc();
      await campRef.set({
        'name': c['name'],
        'description': 'Demo campaign generated automatically.',
        'startDate': Timestamp.fromDate(DateTime.now().subtract(Duration(days: 30))),
        'endDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 30))),
        'goalAmount': c['goal'],
        'status': 'Active',
      });

      final products = c['products'] as List<Map<String, dynamic>>;
      List<String> productIds = [];
      for (var p in products) {
        final pRef = campRef.collection('products').doc();
        await pRef.set({
          'name': p['name'],
          'price': p['price'],
          'cost': (p['price'] as double) * 0.4,
          'initialStock': 500,
          'currentStock': 500,
        });
        productIds.add(pRef.id);
      }

      // Assign to cadets
      for (var cadet in cadets) {
        if (_random.nextDouble() > 0.3) {
          final pId = productIds[_random.nextInt(productIds.length)];
          final price = products.firstWhere((p) => p['name'] == products[productIds.indexOf(pId)]['name'])['price'] as double;
          final qty = 10 + _random.nextInt(20);
          
          final aRef = campRef.collection('assignments').doc();
          await aRef.set({
            'cadetId': cadet['id'],
            'productId': pId,
            'quantity': qty,
            'timestamp': Timestamp.fromDate(DateTime.now().subtract(Duration(days: _random.nextInt(20)))),
            'notes': 'Demo assignment',
          });

          // Generate returns
          if (_random.nextDouble() > 0.5) {
            final rRef = campRef.collection('returns').doc();
            final returnAmount = qty * price * (_random.nextDouble() * 0.8 + 0.2); // 20% to 100% return
            await rRef.set({
              'cadetId': cadet['id'],
              'amountReturned': double.parse(returnAmount.toStringAsFixed(2)),
              'timestamp': Timestamp.fromDate(DateTime.now().subtract(Duration(days: _random.nextInt(5)))),
              'receiptNumber': 'REC-${_random.nextInt(9999)}',
              'notes': 'Demo return',
            });
          }
        }
      }
    }
  }
}

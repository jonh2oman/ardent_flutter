// Ardent Exchange - Production Grade Cadet Economy System
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import '../providers/auth_provider.dart';
import '../models/exchange_item.dart';
import '../models/transaction.dart';

class ExchangeScreen extends StatefulWidget {
  final int initialTab;
  const ExchangeScreen({super.key, this.initialTab = 0});

  @override
  State<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends State<ExchangeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCadetUid;
  List<Map<String, dynamic>> _allCadets = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    _loadCadets();
  }

  Future<void> _loadCadets() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final doc = await FirebaseFirestore.instance
        .collection('corps')
        .doc(auth.userData!.corpsId)
        .get();
    
    if (doc.exists) {
      final List<dynamic> cadets = doc.data()?['settings']?['cadets'] ?? [];
      setState(() {
        _allCadets = cadets.map((c) => Map<String, dynamic>.from(c)).toList();
        for (var c in _allCadets) {
          c['name'] = '${c['firstName'] ?? ''} ${c['lastName'] ?? ''}'.trim();
        }
        _allCadets.sort((a, b) => a['name'].compareTo(b['name']));
      });
    }
  }

  void _selectCadet(BuildContext context, List<dynamic> cadets) {
    // Process and sort cadets for the list
    final List<Map<String, dynamic>> sortedCadets = cadets
        .map((c) => Map<String, dynamic>.from(c))
        .toList();
    
    for (var c in sortedCadets) {
      c['name'] = '${c['firstName'] ?? ''} ${c['lastName'] ?? ''}'.trim();
    }
    sortedCadets.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SELECT CADET'),
        backgroundColor: const Color(0xFF1A1A1A),
        content: SizedBox(
          width: 400,
          height: 500,
          child: ListView.builder(
            itemCount: sortedCadets.length,
            itemBuilder: (context, index) {
              final cadet = sortedCadets[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.white10,
                  child: Text(cadet['firstName']?[0] ?? 'C', style: const TextStyle(color: Colors.white)),
                ),
                title: Text(cadet['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${cadet['rank'] ?? 'Cadet'} • ${cadet['merits'] ?? 0} Merits'),
                onTap: () {
                  setState(() => _selectedCadetUid = cadet['uid'] ?? cadet['id']);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final isAdmin = auth.userData?.isAdmin == true;
    final effectiveUid = _selectedCadetUid ?? auth.user?.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('corps').doc(auth.userData!.corpsId).snapshots(),
      builder: (context, snapshot) {
        List<dynamic> cadets = [];
        Map<String, dynamic> selectedCadetData = {'firstName': 'Loading...', 'merits': 0, 'cashBalance': 0.0};
        
        if (snapshot.hasData && snapshot.data!.exists) {
          final corpsData = snapshot.data!.data() as Map<String, dynamic>;
          cadets = corpsData['settings']?['cadets'] ?? [];
          
          // Find the selected cadet in the array (checking both uid and id for backward compatibility)
          print('DEBUG: Searching for $effectiveUid in ${cadets.length} cadets');
          final cadet = cadets.firstWhere(
            (c) {
              final cid = (c['uid'] ?? c['id'])?.toString();
              return cid == effectiveUid?.toString();
            },
            orElse: () => null,
          );
          
          if (cadet != null) {
            selectedCadetData = Map<String, dynamic>.from(cadet);
          } else if (effectiveUid == auth.user?.uid) {
            // If the user themselves is not in the cadets array (maybe they are staff), 
            // fallback to their own userData
            selectedCadetData = {
              'firstName': auth.userData?.firstName ?? 'Unknown',
              'merits': auth.userData?.merits ?? 0,
              'cashBalance': auth.userData?.cashBalance ?? 0.0,
              'uid': auth.user?.uid,
            };
          }
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              _buildHeader(context, auth, theme, selectedCadetData, effectiveUid, cadets),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBankView(auth, theme, selectedCadetData, effectiveUid),
                    _POSView(selectedCadetUid: effectiveUid, isAdmin: isAdmin),
                    isAdmin ? _InventoryView() : const Center(child: Text('Access Denied', style: TextStyle(color: Colors.white24))),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider auth, ThemeData theme, Map<String, dynamic> selectedCadetData, String? effectiveUid, List<dynamic> cadets) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ARDENT EXCHANGE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: theme.colorScheme.primary, letterSpacing: 2)),
                  const SizedBox(height: 8),
                  Text(effectiveUid == auth.user?.uid ? 'My Wallet' : 'Managing: ${selectedCadetData['firstName']}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                ],
              ),
              if (auth.userData?.isAdmin == true)
                OutlinedButton.icon(
                  onPressed: () => _selectCadet(context, cadets),
                  icon: const Icon(LucideIcons.users, size: 18),
                  label: const Text('SWITCH CADET'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: theme.colorScheme.primary,
            indicatorWeight: 4,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            tabs: const [
              Tab(text: 'BANK', icon: Icon(LucideIcons.landmark, size: 18)),
              Tab(text: 'SHOP', icon: Icon(LucideIcons.shoppingCart, size: 18)),
              Tab(text: 'INVENTORY', icon: Icon(LucideIcons.package, size: 18)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBankView(AuthProvider auth, ThemeData theme, Map<String, dynamic> selectedCadetData, String? effectiveUid) {
    final isAdmin = auth.userData?.isAdmin == true;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Row(
            children: [
              // Merits Card
              Expanded(
                child: _buildBalanceCard(
                  theme,
                  'MERITS',
                  '${selectedCadetData['merits'] ?? 0}',
                  LucideIcons.coins,
                  Colors.amberAccent,
                  isAdmin ? () => _showAdjustBalanceDialog(auth, effectiveUid!, TransactionCurrency.merits) : null,
                ),
              ),
              const SizedBox(width: 24),
              // Canteen Cash Card
              Expanded(
                child: _buildBalanceCard(
                  theme,
                  'CANTEEN CASH',
                  '\$${(selectedCadetData['cashBalance'] ?? 0.0).toStringAsFixed(2)}',
                  LucideIcons.wallet,
                  Colors.greenAccent,
                  isAdmin ? () => _showAdjustBalanceDialog(auth, effectiveUid!, TransactionCurrency.cash) : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          _buildTransactionHistory(auth, theme, effectiveUid),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(ThemeData theme, String label, String value, IconData icon, Color accentColor, VoidCallback? onAdjust) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
              Icon(icon, color: accentColor, size: 24),
            ],
          ),
          const SizedBox(height: 24),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
          if (onAdjust != null) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAdjust,
                icon: const Icon(LucideIcons.plusCircle, size: 16),
                label: const Text('ADJUST BALANCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor.withOpacity(0.1),
                  foregroundColor: accentColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showAdjustBalanceDialog(AuthProvider auth, String targetUid, TransactionCurrency currency) async {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    String type = 'Award';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text('ADJUST ${currency == TransactionCurrency.merits ? 'MERITS' : 'CASH'}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                dropdownColor: const Color(0xFF2A2A2A),
                decoration: const InputDecoration(labelText: 'Adjustment Type'),
                items: const [
                  DropdownMenuItem(value: 'Award', child: Text('Award / Deposit')),
                  DropdownMenuItem(value: 'Penalty', child: Text('Penalty / Withdrawal')),
                ],
                onChanged: (v) => setDialogState(() => type = v!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: InputDecoration(labelText: 'Amount (${currency == TransactionCurrency.merits ? 'Merits' : '\$'})'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Reason / Description'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0) return;

                final finalAmount = type == 'Award' ? amount : -amount;
                final corpsRef = FirebaseFirestore.instance.collection('corps').doc(auth.userData!.corpsId);

                await FirebaseFirestore.instance.runTransaction((transaction) async {
                  final corpsDoc = await transaction.get(corpsRef);
                  if (!corpsDoc.exists) throw 'Corps document not found';

                  final List<dynamic> cadets = List.from(corpsDoc.data()?['settings']?['cadets'] ?? []);
                  final index = cadets.indexWhere((c) {
                    final cid = (c['uid'] ?? c['id'])?.toString();
                    return cid == targetUid?.toString();
                  });

                  if (index == -1) throw 'Cadet not found in roster (target: $targetUid, total: ${cadets.length})';

                  final cadet = Map<String, dynamic>.from(cadets[index]);
                  if (currency == TransactionCurrency.merits) {
                    final current = cadet['merits'] ?? 0;
                    cadet['merits'] = (current + finalAmount).toInt();
                  } else {
                    final current = (cadet['cashBalance'] ?? 0.0).toDouble();
                    cadet['cashBalance'] = current + finalAmount;
                  }

                  cadets[index] = cadet;
                  transaction.update(corpsRef, {'settings.cadets': cadets});

                  // Log Transaction to centralized collection
                  final txRef = corpsRef.collection('exchange_transactions').doc();
                  transaction.set(txRef, {
                    'targetUid': targetUid,
                    'type': type,
                    'amount': amount,
                    'description': descController.text.isEmpty ? 'Balance Adjustment' : descController.text,
                    'timestamp': FieldValue.serverTimestamp(),
                    'issuer': auth.userData!.name,
                    'currency': currency == TransactionCurrency.cash ? 'cash' : 'merits',
                  });
                });

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('CONFIRM'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionHistory(AuthProvider auth, ThemeData theme, String? effectiveUid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('corps')
          .doc(auth.userData!.corpsId)
          .collection('exchange_transactions')
          .where('targetUid', isEqualTo: effectiveUid)
          .orderBy('timestamp', descending: true)
          .limit(15)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error loading transactions. You may need to create a Firestore index.\n${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final txs = snapshot.data!.docs;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('RECENT ACTIVITY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white24, letterSpacing: 1)),
            const SizedBox(height: 24),
            if (txs.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('No recent activity', style: TextStyle(color: Colors.white10)))),
            ...txs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final type = data['type'] ?? 'Purchase';
              final isPositive = type == 'Award' || type == 'Deposit';
              final currency = data['currency'] == 'cash' ? 'cash' : 'merits';
              final amount = (data['amount'] ?? 0).toDouble();
              final desc = data['description'] ?? 'Transaction';
              final date = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isPositive ? Colors.greenAccent : Colors.redAccent).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPositive ? LucideIcons.arrowUpRight : LucideIcons.arrowDownRight,
                        color: isPositive ? Colors.greenAccent : Colors.redAccent,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(desc, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(DateFormat('MMM d, h:mm a').format(date), style: const TextStyle(fontSize: 11, color: Colors.white38)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isPositive ? '+' : '-'}${currency == 'cash' ? '\$' : ''}${currency == 'cash' ? amount.toStringAsFixed(2) : amount.toInt()}',
                          style: TextStyle(
                            color: isPositive ? Colors.greenAccent : Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        Text(currency.toUpperCase(), style: const TextStyle(fontSize: 9, color: Colors.white24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}

// POS View
class _POSView extends StatefulWidget {
  final String? selectedCadetUid;
  final bool isAdmin;
  const _POSView({this.selectedCadetUid, required this.isAdmin});

  @override
  State<_POSView> createState() => _POSViewState();
}

class _POSViewState extends State<_POSView> {
  final Map<String, int> _cart = {}; // ItemID -> Quantity

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Row(
      children: [
        // Product Grid
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('corps').doc(auth.userData!.corpsId).collection('exchange_inventory').where('isActive', isEqualTo: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final items = snapshot.data!.docs.map((doc) => ExchangeItem.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
                
                if (items.isEmpty) return const Center(child: Text('Inventory is empty', style: TextStyle(color: Colors.white24)));

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, 
                    crossAxisSpacing: 16, 
                    mainAxisSpacing: 16, 
                    childAspectRatio: 1.1
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final qty = _cart[item.id] ?? 0;
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(qty > 0 ? 0.08 : 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: qty > 0 ? Colors.greenAccent.withOpacity(0.3) : Colors.white.withOpacity(0.05)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => setState(() => _cart[item.id] = qty + 1),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    color: Colors.black12,
                                    child: item.imageUrl != null ? Image.network(item.imageUrl!, fit: BoxFit.cover) : const Icon(LucideIcons.package, color: Colors.white10),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1),
                                      Text(
                                        item.priceType == PriceType.merits ? '${item.price.toInt()} Merits' : '\$${item.price.toStringAsFixed(2)}', 
                                        style: TextStyle(color: item.priceType == PriceType.merits ? Colors.amberAccent : Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (qty > 0)
                              Positioned(
                                top: 8, right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                                  child: Text('$qty', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        // Cart Sidebar
        Container(
          width: 380,
          decoration: BoxDecoration(
            color: Colors.black26,
            border: Border(left: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          padding: const EdgeInsets.all(32),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('corps').doc(auth.userData!.corpsId).collection('exchange_inventory').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final allInventory = snapshot.data!.docs.map((doc) => ExchangeItem.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
              
              final cartItems = allInventory.where((item) => _cart.containsKey(item.id)).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('SHOPPING CART', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white24, letterSpacing: 1)),
                      if (_cart.isNotEmpty)
                        TextButton(onPressed: () => setState(() => _cart.clear()), child: const Text('CLEAR', style: TextStyle(fontSize: 10, color: Colors.redAccent))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _cart.isEmpty
                      ? const Center(child: Text('Cart is empty', style: TextStyle(color: Colors.white10)))
                      : ListView.builder(
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            final qty = _cart[item.id]!;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text('${item.priceType == PriceType.merits ? item.price.toInt() : item.price} x $qty'),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.minusCircle, size: 18, color: Colors.white24),
                                    onPressed: () => setState(() {
                                      if (qty > 1) _cart[item.id] = qty - 1;
                                      else _cart.remove(item.id);
                                    }),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  ),
                  const Divider(height: 64, color: Colors.white10),
                  _buildCheckoutSummary(auth, cartItems),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutSummary(AuthProvider auth, List<ExchangeItem> cartItems) {
    int totalMerits = 0;
    double totalCash = 0;

    for (var item in cartItems) {
      final qty = _cart[item.id] ?? 0;
      if (item.priceType == PriceType.merits) totalMerits += (item.price * qty).toInt();
      else totalCash += item.price * qty;
    }

    final effectiveUid = widget.selectedCadetUid ?? auth.user?.uid;

    return Column(
      children: [
        if (totalMerits > 0) 
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Merits:'), Text('$totalMerits', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.w900, fontSize: 18))]),
          ),
        if (totalCash > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Cash:'), Text('\$${totalCash.toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900, fontSize: 18))]),
          ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981), 
              foregroundColor: Colors.black, 
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _cart.isEmpty || effectiveUid == null ? null : () => _processCheckout(auth, totalMerits, totalCash, cartItems),
            child: Text(effectiveUid == null ? 'SELECT A CADET' : 'COMPLETE PURCHASE', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ),
      ],
    );
  }

  Future<void> _processCheckout(AuthProvider auth, int totalMerits, double totalCash, List<ExchangeItem> cartItems) async {
    final corpsRef = FirebaseFirestore.instance.collection('corps').doc(auth.userData!.corpsId);
    final targetUid = widget.selectedCadetUid ?? auth.user?.uid;
    
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // --- 1. READS ---
        final corpsDoc = await transaction.get(corpsRef);
        if (!corpsDoc.exists) throw 'Corps document not found';

        // Pre-fetch all item stocks before writing
        final Map<String, DocumentSnapshot> itemDocs = {};
        for (var item in cartItems) {
          final itemRef = corpsRef.collection('exchange_inventory').doc(item.id);
          final itemDoc = await transaction.get(itemRef);
          itemDocs[item.id] = itemDoc;
        }

        // --- 2. WRITES ---
        final List<dynamic> cadets = List.from(corpsDoc.data()?['settings']?['cadets'] ?? []);
        final index = cadets.indexWhere((c) {
          final cid = (c['uid'] ?? c['id'])?.toString();
          return cid == targetUid?.toString();
        });

        if (index == -1) throw 'Cadet not found in roster (target: $targetUid, total: ${cadets.length})';

        final cadet = Map<String, dynamic>.from(cadets[index]);
        final currentMerits = cadet['merits'] ?? 0;
        final currentCash = (cadet['cashBalance'] ?? 0.0).toDouble();

        if (currentMerits < totalMerits) throw 'Insufficient Merits';
        if (currentCash < totalCash) throw 'Insufficient Canteen Cash';

        // 1. Deduct from Cadet in array
        cadet['merits'] = currentMerits - totalMerits;
        cadet['cashBalance'] = currentCash - totalCash;
        cadets[index] = cadet;
        transaction.update(corpsRef, {'settings.cadets': cadets});

        // 2. Log Transactions & Update Stock
        for (var item in cartItems) {
          final qty = _cart[item.id]!;
          
          // Log to centralized collection
          final txRef = corpsRef.collection('exchange_transactions').doc();
          transaction.set(txRef, {
            'targetUid': targetUid,
            'type': 'Purchase',
            'amount': item.price * qty,
            'description': 'Bought $qty x ${item.name}',
            'timestamp': FieldValue.serverTimestamp(),
            'issuer': auth.userData!.name,
            'currency': item.priceType == PriceType.cash ? 'cash' : 'merits',
          });

          // 3. Update Inventory Stock
          final itemRef = corpsRef.collection('exchange_inventory').doc(item.id);
          final itemDoc = itemDocs[item.id]!;
          final currentStock = itemDoc.get('stock') ?? 0;
          transaction.update(itemRef, {'stock': currentStock - qty});
        }

        // 4. Log to Global Sales
        final salesRef = corpsRef.collection('exchange_sales').doc();
        transaction.set(salesRef, {
          'timestamp': FieldValue.serverTimestamp(),
          'cadetUid': targetUid,
          'cadetName': '${cadet['firstName']} ${cadet['lastName']}',
          'totalMerits': totalMerits,
          'totalCash': totalCash,
          'items': _cart.entries.map((e) => {'id': e.key, 'qty': e.value}).toList(),
          'processedBy': auth.userData!.name,
        });
      });

      setState(() => _cart.clear());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase Complete!'), backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }
}

// Inventory Management View
class _InventoryView extends StatefulWidget {
  @override
  State<_InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<_InventoryView> {
  final _picker = ImagePicker();

  Future<void> _addItem(AuthProvider auth) async {
    _showItemDialog(auth, null);
  }

  void _showItemDialog(AuthProvider auth, ExchangeItem? existingItem) {
    final nameController = TextEditingController(text: existingItem?.name);
    final descController = TextEditingController(text: existingItem?.description);
    final priceController = TextEditingController(text: existingItem?.price.toString());
    final stockController = TextEditingController(text: existingItem?.stock.toString());
    PriceType priceType = existingItem?.priceType ?? PriceType.merits;
    bool isActive = existingItem?.isActive ?? true;
    Uint8List? imageBytes;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(
                existingItem == null ? LucideIcons.packagePlus : LucideIcons.edit3, 
                color: Colors.amberAccent
              ),
              const SizedBox(width: 12),
              Text(
                existingItem == null ? 'ADD CATALOG ITEM' : 'EDIT CATALOG ITEM',
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ],
          ),
          content: Container(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Multiplatform Safe Image Picker
                  GestureDetector(
                    onTap: () async {
                      final picked = await _picker.pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        final bytes = await picked.readAsBytes();
                        setDialogState(() {
                          imageBytes = bytes;
                        });
                      }
                    },
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: imageBytes != null || existingItem?.imageUrl != null
                              ? Colors.amberAccent.withOpacity(0.3)
                              : Colors.white.withOpacity(0.1),
                          width: 1.5,
                        ),
                      ),
                      child: imageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.memory(imageBytes!, fit: BoxFit.cover),
                            )
                          : existingItem?.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(existingItem!.imageUrl!, fit: BoxFit.cover),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      LucideIcons.camera,
                                      size: 36,
                                      color: Colors.amberAccent.withOpacity(0.6),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Tap to upload item photo',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white54,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Supports JPEG, PNG under 5MB',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white24,
                                      ),
                                    ),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Text Fields
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Item Name',
                      labelStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(LucideIcons.tag, size: 18, color: Colors.white30),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.03),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.amberAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: descController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(LucideIcons.fileText, size: 18, color: Colors.white30),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.03),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.amberAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Price',
                            labelStyle: const TextStyle(color: Colors.white54),
                            prefixIcon: const Icon(LucideIcons.dollarSign, size: 18, color: Colors.white30),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.03),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.amberAccent),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<PriceType>(
                            value: priceType,
                            dropdownColor: const Color(0xFF1E1E1E),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            items: const [
                              DropdownMenuItem(
                                value: PriceType.merits,
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.coins, color: Colors.amberAccent, size: 16),
                                    SizedBox(width: 8),
                                    Text('Merits'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: PriceType.cash,
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.wallet, color: Colors.greenAccent, size: 16),
                                    SizedBox(width: 8),
                                    Text('Cash'),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (v) => setDialogState(() => priceType = v!),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: stockController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Stock Level',
                      labelStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(LucideIcons.layers, size: 18, color: Colors.white30),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.03),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.amberAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: SwitchListTile(
                      value: isActive,
                      title: const Text('Active in Store', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('If inactive, cadets cannot see or purchase this item', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      activeColor: Colors.amberAccent,
                      onChanged: (v) => setDialogState(() => isActive = v),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          actions: [
            if (existingItem != null)
              TextButton(
                onPressed: isUploading
                    ? null
                    : () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: const Color(0xFF1E1E1E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Row(
                              children: [
                                Icon(LucideIcons.alertTriangle, color: Colors.redAccent),
                                SizedBox(width: 12),
                                Text('DELETE CATALOG ITEM', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            content: Text(
                              'Are you absolutely sure you want to permanently delete "${existingItem.name}"? This action is irreversible.',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('CONFIRM DELETE'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          setDialogState(() => isUploading = true);
                          try {
                            await FirebaseFirestore.instance
                                .collection('corps')
                                .doc(auth.userData!.corpsId)
                                .collection('exchange_inventory')
                                .doc(existingItem.id)
                                .delete();
                            if (context.mounted) {
                              Navigator.pop(context); // Close details dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Item deleted successfully'), backgroundColor: Colors.redAccent)
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isUploading = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error deleting item: $e'), backgroundColor: Colors.redAccent)
                              );
                            }
                          }
                        }
                      },
                child: const Text(
                  'DELETE ITEM',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('CANCEL', style: TextStyle(color: Colors.white38))
            ),
            ElevatedButton(
              onPressed: isUploading ? null : () async {
                setDialogState(() => isUploading = true);
                String? imageUrl = existingItem?.imageUrl;
                
                try {
                  if (imageBytes != null) {
                    final storageRef = FirebaseStorage.instance.ref().child('corps/${auth.userData!.corpsId}/exchange/${DateTime.now().millisecondsSinceEpoch}.jpg');
                    final uploadTask = storageRef.putData(
                      imageBytes!,
                      SettableMetadata(contentType: 'image/jpeg'),
                    );
                    await uploadTask;
                    imageUrl = await storageRef.getDownloadURL();
                  }

                  final itemData = {
                    'name': nameController.text.trim(),
                    'description': descController.text.trim(),
                    'price': double.tryParse(priceController.text) ?? 0.0,
                    'priceType': priceType.index,
                    'stock': int.tryParse(stockController.text) ?? 0,
                    'imageUrl': imageUrl,
                    'isActive': isActive,
                    'category': existingItem?.category ?? 'General',
                  };

                  if (existingItem == null) {
                    await FirebaseFirestore.instance
                        .collection('corps')
                        .doc(auth.userData!.corpsId)
                        .collection('exchange_inventory')
                        .add(itemData);
                  } else {
                    await FirebaseFirestore.instance
                        .collection('corps')
                        .doc(auth.userData!.corpsId)
                        .collection('exchange_inventory')
                        .doc(existingItem.id)
                        .update(itemData);
                  }

                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  setDialogState(() => isUploading = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error saving item: $e'), backgroundColor: Colors.redAccent)
                    );
                  }
                }
              },
              child: Text(isUploading ? 'SAVING...' : 'SAVE ITEM'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addItem(auth),
        icon: const Icon(LucideIcons.plus),
        label: const Text('ADD ITEM'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('UNIT INVENTORY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white24, letterSpacing: 1)),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('corps').doc(auth.userData!.corpsId).collection('exchange_inventory').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final items = snapshot.data!.docs.map((doc) => ExchangeItem.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
                  
                  if (items.isEmpty) return const Center(child: Text('No items in inventory', style: TextStyle(color: Colors.white24)));

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _InventoryItemCard(
                        item: item,
                        onTap: () => _showItemDialog(auth, item),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Hover-animated, premium styled inventory card
class _InventoryItemCard extends StatefulWidget {
  final ExchangeItem item;
  final VoidCallback onTap;

  const _InventoryItemCard({required this.item, required this.onTap});

  @override
  State<_InventoryItemCard> createState() => _InventoryItemCardState();
}

class _InventoryItemCardState extends State<_InventoryItemCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    
    // Determine stock status details
    final isOutOfStock = item.stock <= 0;
    final isLowStock = item.stock > 0 && item.stock < 5;
    
    Color stockBadgeColor = Colors.greenAccent;
    String stockText = 'IN STOCK (${item.stock})';
    if (isOutOfStock) {
      stockBadgeColor = Colors.redAccent;
      stockText = 'OUT OF STOCK';
    } else if (isLowStock) {
      stockBadgeColor = Colors.amberAccent;
      stockText = 'LOW STOCK (${item.stock})';
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            color: _isHovered ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered 
                ? (item.priceType == PriceType.merits ? Colors.amberAccent.withOpacity(0.3) : Colors.greenAccent.withOpacity(0.3))
                : Colors.white.withOpacity(0.05)
            ),
            boxShadow: _isHovered ? [
              BoxShadow(
                color: (item.priceType == PriceType.merits ? Colors.amberAccent : Colors.greenAccent).withOpacity(0.05),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ] : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Image with semi-transparent black header background
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        color: Colors.black26,
                        child: item.imageUrl != null 
                          ? Image.network(
                              item.imageUrl!, 
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.image, size: 40, color: Colors.white10),
                            )
                          : const Icon(LucideIcons.package, size: 40, color: Colors.white10),
                      ),
                    ),
                    
                    // Item Info details
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), 
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis
                          ),
                          const SizedBox(height: 6),
                          
                          // Price Badge & Stock Badge Layout
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Elegant rounded chip for currency price
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (item.priceType == PriceType.merits ? Colors.amberAccent : Colors.greenAccent).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: (item.priceType == PriceType.merits ? Colors.amberAccent : Colors.greenAccent).withOpacity(0.2)
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      item.priceType == PriceType.merits ? LucideIcons.coins : LucideIcons.wallet, 
                                      size: 10, 
                                      color: item.priceType == PriceType.merits ? Colors.amberAccent : Colors.greenAccent
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.priceType == PriceType.merits ? '${item.price.toInt()}' : '\$${item.price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: item.priceType == PriceType.merits ? Colors.amberAccent : Colors.greenAccent, 
                                        fontSize: 10, 
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Small edit button indicator
                              Icon(
                                LucideIcons.edit3, 
                                size: 14, 
                                color: _isHovered ? Colors.white70 : Colors.white24
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Color-coded Stock Badge
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: stockBadgeColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: stockBadgeColor.withOpacity(0.15)),
                            ),
                            child: Center(
                              child: Text(
                                stockText,
                                style: TextStyle(
                                  color: stockBadgeColor, 
                                  fontSize: 9, 
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // ARCHIVED semi-transparent overlay banner if inactive
                if (!item.isActive)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.65),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                          ),
                          child: const Text(
                            'ARCHIVED',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';
import '../models/lsa_item.dart';
import '../models/corps_data.dart';
import '../services/pdf_service.dart';

class LSAWishListScreen extends StatefulWidget {
  const LSAWishListScreen({Key? key}) : super(key: key);

  @override
  State<LSAWishListScreen> createState() => _LSAWishListScreenState();
}

class _LSAWishListScreenState extends State<LSAWishListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _priceController = TextEditingController(text: '0.00');
  final TextEditingController _linkController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1017),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            final corpsId = auth.userData?.corpsId ?? '';
            if (corpsId.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildAddItemForm(corpsId)),
                        const SizedBox(width: 24),
                        Expanded(flex: 7, child: _buildWishListTracker(corpsId)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(LucideIcons.arrowLeft, size: 16, color: Colors.white),
              label: const Text('Back', style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                backgroundColor: const Color(0xFF1C212D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 16),
            const Text('LSA Wish List', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.only(left: 100), // aligning roughly with title
          child: Text('Create and manage your annual Local Support Allocation (LSA) request list.', style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }

  Widget _buildAddItemForm(String corpsId) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF11141C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add New LSA Item', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Fill out the form to add an item to the wish list.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 24),
            
            _buildInputField('Item Name', _nameController),
            const SizedBox(height: 16),
            _buildInputField('Description (Optional)', _descriptionController, maxLines: 3),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(child: _buildInputField('Quantity', _quantityController, isNumber: true)),
                const SizedBox(width: 16),
                Expanded(child: _buildInputField('Unit Price (\$)', _priceController, isNumber: true)),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildInputField('Link (Optional)', _linkController, hintText: 'https://example.com/product'),
            const SizedBox(height: 16),
            
            const Text('Price Screenshot (Optional)', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image upload coming soon.')));
              },
              icon: const Icon(LucideIcons.imagePlus, size: 16),
              label: const Text('Upload Image'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _addItem(corpsId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6B9C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Add Item'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {int maxLines = 1, bool isNumber = false, String? hintText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D1017),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLines: maxLines,
            keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.white24),
            ),
          ),
        ),
      ],
    );
  }

  void _addItem(String corpsId) {
    if (_nameController.text.trim().isEmpty) return;

    final qty = int.tryParse(_quantityController.text) ?? 1;
    final price = double.tryParse(_priceController.text) ?? 0.0;

    _firestore.collection('corps').doc(corpsId).collection('lsa_wishlist').add({
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'quantity': qty,
      'unitPrice': price,
      'link': _linkController.text.trim(),
      'imageUrl': '',
      'timestamp': FieldValue.serverTimestamp(),
    });

    _nameController.clear();
    _descriptionController.clear();
    _quantityController.text = '1';
    _priceController.text = '0.00';
    _linkController.clear();
  }

  Widget _buildWishListTracker(String corpsId) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF11141C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('corps').doc(corpsId).collection('lsa_wishlist').orderBy('timestamp').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!.docs;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Wish List Tracker', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  OutlinedButton.icon(
                    onPressed: items.isEmpty ? null : () => _generateSponsorMemo(corpsId, items),
                    icon: const Icon(LucideIcons.fileDown, size: 16),
                    label: const Text('Generate Sponsor Memo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (items.isEmpty)
                const Expanded(child: Center(child: Text('No items have been added to the wish list yet.', style: TextStyle(color: Colors.white54))))
              else
                Expanded(
                  child: _buildItemsTable(corpsId, items),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItemsTable(String corpsId, List<QueryDocumentSnapshot> itemDocs) {
    double grandTotal = 0.0;
    final rows = itemDocs.map((doc) {
      final item = LsaItem.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      final total = item.quantity * item.unitPrice;
      grandTotal += total;
      return item;
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: Row(
            children: const [
              Expanded(flex: 3, child: Text('Item', style: TextStyle(color: Colors.white54, fontSize: 12))),
              Expanded(flex: 1, child: Text('Qty', style: TextStyle(color: Colors.white54, fontSize: 12))),
              Expanded(flex: 1, child: Text('Unit Price', style: TextStyle(color: Colors.white54, fontSize: 12))),
              Expanded(flex: 1, child: Text('Total', style: TextStyle(color: Colors.white54, fontSize: 12))),
              Expanded(flex: 1, child: Text('Links', style: TextStyle(color: Colors.white54, fontSize: 12))),
              Expanded(flex: 1, child: Align(alignment: Alignment.centerRight, child: Text('Actions', style: TextStyle(color: Colors.white54, fontSize: 12)))),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final item = rows[index];
              final total = item.quantity * item.unitPrice;
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                          if (item.description.isNotEmpty)
                            Text(item.description, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                    Expanded(flex: 1, child: Text('${item.quantity}', style: const TextStyle(color: Colors.white, fontSize: 13))),
                    Expanded(flex: 1, child: Text('\$${item.unitPrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 13))),
                    Expanded(flex: 1, child: Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 13))),
                    Expanded(
                      flex: 1, 
                      child: item.link.isNotEmpty 
                        ? const Icon(LucideIcons.link, size: 14, color: Colors.blueAccent)
                        : const SizedBox.shrink()
                    ),
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.edit2, size: 14, color: Colors.white54),
                            onPressed: () {
                              // Edit coming soon
                            },
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.only(right: 8),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.x, size: 14, color: Colors.redAccent),
                            onPressed: () {
                              _firestore.collection('corps').doc(corpsId).collection('lsa_wishlist').doc(item.id).delete();
                            },
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF161A22),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
          ),
          child: Row(
            children: [
              const Expanded(flex: 5, child: Align(alignment: Alignment.centerRight, child: Text('Grand Total', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
              Expanded(flex: 4, child: Padding(padding: const EdgeInsets.only(left: 16), child: Text('\$${grandTotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _generateSponsorMemo(String corpsId, List<QueryDocumentSnapshot> docs) async {
    try {
      final corpsDoc = await _firestore.collection('corps').doc(corpsId).get();
      if (!corpsDoc.exists) return;
      final corpsData = CorpsData.fromMap(corpsDoc.data()!, corpsDoc.id);
      
      final items = docs.map((doc) => LsaItem.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
      
      await PdfService.generateLSASponsorMemo(corpsData, items);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e')));
      }
    }
  }
}

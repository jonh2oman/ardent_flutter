import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/fundraising_models.dart';

class AssignmentTab extends StatefulWidget {
  final String corpsId;

  const AssignmentTab({Key? key, required this.corpsId}) : super(key: key);

  @override
  State<AssignmentTab> createState() => _AssignmentTabState();
}

class _AssignmentTabState extends State<AssignmentTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedCampaignId;
  String? _selectedProductId;
  String? _selectedCadetId;
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCampaignSelector(),
        const SizedBox(height: 16),
        if (_selectedCampaignId != null)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 1, child: _buildAssignProductsCard()),
                const SizedBox(width: 16),
                Expanded(flex: 1, child: _buildCurrentlyAssignedCard()),
              ],
            ),
          )
        else
          const Center(child: Text('Please select or create a campaign to assign products.', style: TextStyle(color: Colors.white54))),
      ],
    );
  }

  Widget _buildCampaignSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('corps').doc(widget.corpsId).collection('fundraising_campaigns').orderBy('startDate', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final campaigns = snapshot.data!.docs;
        if (campaigns.isEmpty) return const SizedBox.shrink();

        if (_selectedCampaignId == null && campaigns.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => _selectedCampaignId = campaigns.first.id);
          });
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF11141C),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCampaignId,
              dropdownColor: const Color(0xFF1C212D),
              style: const TextStyle(color: Colors.white),
              isExpanded: true,
              hint: const Text('Select Campaign', style: TextStyle(color: Colors.white54)),
              items: campaigns.map((doc) {
                final c = FundraisingCampaign.fromMap(doc.id, doc.data() as Map<String, dynamic>);
                return DropdownMenuItem(value: c.id, child: Text(c.name));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedCampaignId = val;
                  _selectedProductId = null;
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssignProductsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF11141C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Assign Products', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Assign fundraising products to a cadet.', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 24),
          
          const Text('Product', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('corps').doc(widget.corpsId).collection('fundraising_campaigns').doc(_selectedCampaignId).collection('products').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final products = snapshot.data!.docs;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C212D),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedProductId,
                    dropdownColor: const Color(0xFF1C212D),
                    isExpanded: true,
                    hint: const Text('Select a product...', style: TextStyle(color: Colors.white54)),
                    style: const TextStyle(color: Colors.white),
                    items: products.map((doc) {
                      final p = FundraisingProduct.fromMap(doc.id, doc.data() as Map<String, dynamic>);
                      return DropdownMenuItem(value: p.id, child: Text(p.name));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedProductId = val),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          const Text('Cadet', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final cadetsList = List<dynamic>.from(auth.corpsData?.settings?['cadets'] ?? [])
                ..sort((a, b) => (a['lastName'] ?? '').toString().compareTo((b['lastName'] ?? '').toString()));

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C212D),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCadetId,
                    dropdownColor: const Color(0xFF1C212D),
                    isExpanded: true,
                    hint: const Text('Select a cadet...', style: TextStyle(color: Colors.white54)),
                    style: const TextStyle(color: Colors.white),
                    items: cadetsList.map((c) {
                      final id = (c['uid'] ?? c['id'] ?? '').toString();
                      return DropdownMenuItem(value: id, child: Text('${c['lastName']}, ${c['firstName']}'));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCadetId = val),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          const Text('Quantity Assigned', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1C212D),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: _quantity.toString()),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(border: InputBorder.none),
                    onChanged: (val) => _quantity = int.tryParse(val) ?? 1,
                  ),
                ),
                Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _quantity++),
                      child: const Icon(LucideIcons.chevronUp, size: 14, color: Colors.white54),
                    ),
                    InkWell(
                      onTap: () => setState(() { if (_quantity > 1) _quantity--; }),
                      child: const Icon(LucideIcons.chevronDown, size: 14, color: Colors.white54),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_selectedCampaignId != null && _selectedProductId != null && _selectedCadetId != null) {
                  _firestore
                      .collection('corps')
                      .doc(widget.corpsId)
                      .collection('fundraising_campaigns')
                      .doc(_selectedCampaignId)
                      .collection('assignments')
                      .add({
                    'cadetId': _selectedCadetId,
                    'productId': _selectedProductId,
                    'quantity': _quantity,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  // Show snackbar
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Products assigned successfully')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A6B9C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Assign'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentlyAssignedCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF11141C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Currently Assigned', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('A list of products currently assigned to cadets.', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 24),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('corps')
                  .doc(widget.corpsId)
                  .collection('fundraising_campaigns')
                  .doc(_selectedCampaignId)
                  .collection('assignments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, assignmentSnap) {
                if (!assignmentSnap.hasData) return const Center(child: CircularProgressIndicator());
                final assignments = assignmentSnap.data!.docs;

                final auth = Provider.of<AuthProvider>(context, listen: false);
                final cadetsList = List<dynamic>.from(auth.corpsData?.settings?['cadets'] ?? []);
                final cadetMap = {for (var c in cadetsList) (c['uid'] ?? c['id'] ?? '').toString(): c as Map<String, dynamic>};

                return Builder(
                  builder: (context) {
                    return FutureBuilder<QuerySnapshot>(
                      future: _firestore.collection('corps').doc(widget.corpsId).collection('fundraising_campaigns').doc(_selectedCampaignId).collection('products').get(),
                      builder: (context, productSnap) {
                        if (!productSnap.hasData) return const SizedBox.shrink();
                        final productDocs = productSnap.data!.docs;
                        final productMap = {for (var doc in productDocs) doc.id: doc.data() as Map<String, dynamic>};

                        return ListView(
                          children: [
                            const Row(
                              children: [
                                Expanded(flex: 2, child: Text('Cadet', style: TextStyle(color: Colors.white54, fontSize: 12))),
                                Expanded(flex: 1, child: Text('Item', style: TextStyle(color: Colors.white54, fontSize: 12))),
                                Expanded(flex: 1, child: Text('Qty', style: TextStyle(color: Colors.white54, fontSize: 12))),
                                SizedBox(width: 40),
                              ],
                            ),
                            const Divider(color: Colors.white24, height: 24),
                            ...assignments.map((doc) {
                              final a = FundraisingAssignment.fromMap(doc.id, doc.data() as Map<String, dynamic>);
                              final cadetData = cadetMap[a.cadetId];
                              final cadetName = cadetData != null ? '${cadetData['lastName']}, ${cadetData['firstName']}' : 'Unknown';
                              final productData = productMap[a.productId];
                              final productName = productData != null ? productData['name'] : 'Unknown';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  children: [
                                    Expanded(flex: 2, child: Text(cadetName, style: const TextStyle(color: Colors.white, fontSize: 13))),
                                    Expanded(flex: 1, child: Text(productName, style: const TextStyle(color: Colors.white, fontSize: 13))),
                                    Expanded(flex: 1, child: Text('${a.quantity}', style: const TextStyle(color: Colors.white, fontSize: 13))),
                                    IconButton(
                                      icon: const Icon(LucideIcons.trash2, size: 14, color: Colors.redAccent),
                                      onPressed: () {
                                        _firestore
                                            .collection('corps')
                                            .doc(widget.corpsId)
                                            .collection('fundraising_campaigns')
                                            .doc(_selectedCampaignId)
                                            .collection('assignments')
                                            .doc(a.id)
                                            .delete();
                                      },
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        );
                      }
                    );
                  }
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

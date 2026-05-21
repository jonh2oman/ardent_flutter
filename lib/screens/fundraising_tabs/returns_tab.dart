import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../data/fundraising_models.dart';

class ReturnsTab extends StatefulWidget {
  final String corpsId;

  const ReturnsTab({Key? key, required this.corpsId}) : super(key: key);

  @override
  State<ReturnsTab> createState() => _ReturnsTabState();
}

class _ReturnsTabState extends State<ReturnsTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedCampaignId;
  String? _selectedCadetId;
  final TextEditingController _amountController = TextEditingController();

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
                Expanded(flex: 1, child: _buildLogReturnCard()),
                const SizedBox(width: 16),
                Expanded(flex: 1, child: _buildRecentReturnsCard()),
              ],
            ),
          )
        else
          const Center(child: Text('Please select a campaign to log returns.', style: TextStyle(color: Colors.white54))),
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
                  _selectedCadetId = null;
                  _amountController.clear();
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogReturnCard() {
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
          const Text('Log Cash Return', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Record funds turned in by a cadet.', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 24),
          
          const Text('Cadet', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('corps').doc(widget.corpsId).collection('personnel').orderBy('lastName').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final cadets = snapshot.data!.docs;

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
                    items: cadets.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(value: doc.id, child: Text('${data['lastName']}, ${data['firstName']}'));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCadetId = val),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          const Text('Amount Returned', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1C212D),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: TextField(
              controller: _amountController,
              style: const TextStyle(color: Colors.white),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                border: InputBorder.none,
                prefixIcon: Icon(Icons.attach_money, color: Colors.white54, size: 16),
                prefixIconConstraints: BoxConstraints(minWidth: 30, minHeight: 0),
                hintText: '0.00',
                hintStyle: TextStyle(color: Colors.white24),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(_amountController.text) ?? 0.0;
                if (_selectedCampaignId != null && _selectedCadetId != null && amount > 0) {
                  _firestore
                      .collection('corps')
                      .doc(widget.corpsId)
                      .collection('fundraising_campaigns')
                      .doc(_selectedCampaignId)
                      .collection('returns')
                      .add({
                    'cadetId': _selectedCadetId,
                    'amountReturned': amount,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  _amountController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Return logged successfully')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A6B9C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Log Return'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReturnsCard() {
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
          const Text('Recent Returns', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('A list of recent monetary returns for this campaign.', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 24),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('corps')
                  .doc(widget.corpsId)
                  .collection('fundraising_campaigns')
                  .doc(_selectedCampaignId)
                  .collection('returns')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, returnsSnap) {
                if (!returnsSnap.hasData) return const Center(child: CircularProgressIndicator());
                final returns = returnsSnap.data!.docs;

                return FutureBuilder<QuerySnapshot>(
                  future: _firestore.collection('corps').doc(widget.corpsId).collection('personnel').get(),
                  builder: (context, cadetSnap) {
                    if (!cadetSnap.hasData) return const SizedBox.shrink();
                    final cadetDocs = cadetSnap.data!.docs;
                    final cadetMap = {for (var doc in cadetDocs) doc.id: doc.data() as Map<String, dynamic>};

                    return ListView(
                      children: [
                        const Row(
                          children: [
                            Expanded(flex: 2, child: Text('Cadet', style: TextStyle(color: Colors.white54, fontSize: 12))),
                            Expanded(flex: 1, child: Text('Amount', style: TextStyle(color: Colors.white54, fontSize: 12))),
                            Expanded(flex: 1, child: Text('Date', style: TextStyle(color: Colors.white54, fontSize: 12))),
                            SizedBox(width: 40),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 24),
                        ...returns.map((doc) {
                          final r = FundraisingReturn.fromMap(doc.id, doc.data() as Map<String, dynamic>);
                          final cadetData = cadetMap[r.cadetId];
                          final cadetName = cadetData != null ? '${cadetData['lastName']}, ${cadetData['firstName']}' : 'Unknown';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                Expanded(flex: 2, child: Text(cadetName, style: const TextStyle(color: Colors.white, fontSize: 13))),
                                Expanded(flex: 1, child: Text('\$${r.amountReturned.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 13))),
                                Expanded(flex: 1, child: Text(DateFormat('dd MMM').format(r.timestamp), style: const TextStyle(color: Colors.white54, fontSize: 13))),
                                IconButton(
                                  icon: const Icon(LucideIcons.trash2, size: 14, color: Colors.redAccent),
                                  onPressed: () {
                                    _firestore
                                        .collection('corps')
                                        .doc(widget.corpsId)
                                        .collection('fundraising_campaigns')
                                        .doc(_selectedCampaignId)
                                        .collection('returns')
                                        .doc(r.id)
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
              },
            ),
          ),
        ],
      ),
    );
  }
}

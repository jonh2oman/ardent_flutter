import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
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

                final auth = Provider.of<AuthProvider>(context, listen: false);
                final cadetsList = List<dynamic>.from(auth.corpsData?.settings?['cadets'] ?? []);
                final cadetMap = {for (var c in cadetsList) (c['uid'] ?? c['id'] ?? '').toString(): c as Map<String, dynamic>};

                return Builder(
                  builder: (context) {
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

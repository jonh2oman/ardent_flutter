import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../data/fundraising_models.dart';

class CampaignsTab extends StatefulWidget {
  final String corpsId;

  const CampaignsTab({Key? key, required this.corpsId}) : super(key: key);

  @override
  State<CampaignsTab> createState() => _CampaignsTabState();
}

class _CampaignsTabState extends State<CampaignsTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showNewCampaignDialog() {
    final nameController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1C212D),
            title: const Text('New Campaign', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Campaign Name',
                    labelStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => startDate = picked);
                          }
                        },
                        child: Text(startDate == null ? 'Start Date' : DateFormat('dd MMM yyyy').format(startDate!), style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => endDate = picked);
                          }
                        },
                        child: Text(endDate == null ? 'End Date' : DateFormat('dd MMM yyyy').format(endDate!), style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty && startDate != null && endDate != null) {
                    _firestore.collection('corps').doc(widget.corpsId).collection('fundraising_campaigns').add({
                      'name': nameController.text,
                      'startDate': Timestamp.fromDate(startDate!),
                      'endDate': Timestamp.fromDate(endDate!),
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Create'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showAddProductDialog(String campaignId) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C212D),
        title: const Text('Add Product', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Product Name', labelStyle: TextStyle(color: Colors.white54)),
            ),
            TextField(
              controller: priceController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Price (\$)', labelStyle: TextStyle(color: Colors.white54)),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: stockController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Initial Stock', labelStyle: TextStyle(color: Colors.white54)),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(priceController.text) ?? 0.0;
              final stock = int.tryParse(stockController.text) ?? 0;
              if (nameController.text.isNotEmpty) {
                _firestore
                    .collection('corps')
                    .doc(widget.corpsId)
                    .collection('fundraising_campaigns')
                    .doc(campaignId)
                    .collection('products')
                    .add({
                  'name': nameController.text,
                  'price': price,
                  'initialStock': stock,
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          onPressed: _showNewCampaignDialog,
          icon: const Icon(LucideIcons.plusCircle, size: 16),
          label: const Text('New Campaign'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A6B9C),
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('corps')
                .doc(widget.corpsId)
                .collection('fundraising_campaigns')
                .orderBy('startDate', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              final campaigns = snapshot.data!.docs;
              if (campaigns.isEmpty) {
                return const Center(child: Text('No campaigns found.', style: TextStyle(color: Colors.white54)));
              }

              return ListView.builder(
                itemCount: campaigns.length,
                itemBuilder: (context, index) {
                  final campaignDoc = campaigns[index];
                  final campaign = FundraisingCampaign.fromMap(campaignDoc.id, campaignDoc.data() as Map<String, dynamic>);
                  final dateRange = '${DateFormat('dd MMM yyyy').format(campaign.startDate)} - ${DateFormat('dd MMM yyyy').format(campaign.endDate)}';

                  return Card(
                    color: const Color(0xFF11141C),
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: Text(campaign.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(dateRange, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        iconColor: Colors.white54,
                        collapsedIconColor: Colors.white54,
                        childrenPadding: const EdgeInsets.all(16),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C212D),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(LucideIcons.package, color: Colors.white, size: 16),
                                        SizedBox(width: 8),
                                        Text('Products', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    OutlinedButton(
                                      onPressed: () => _showAddProductDialog(campaign.id),
                                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: Colors.white.withOpacity(0.2))),
                                      child: const Text('Add Product', style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                StreamBuilder<QuerySnapshot>(
                                  stream: _firestore
                                      .collection('corps')
                                      .doc(widget.corpsId)
                                      .collection('fundraising_campaigns')
                                      .doc(campaign.id)
                                      .collection('products')
                                      .snapshots(),
                                  builder: (context, productSnapshot) {
                                    if (!productSnapshot.hasData) return const SizedBox.shrink();
                                    final products = productSnapshot.data!.docs;

                                    return Table(
                                      columnWidths: const {
                                        0: FlexColumnWidth(2),
                                        1: FlexColumnWidth(1),
                                        2: FlexColumnWidth(1),
                                        3: FlexColumnWidth(1),
                                      },
                                      children: [
                                        TableRow(
                                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1)))),
                                          children: const [
                                            Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Name', style: TextStyle(color: Colors.white54, fontSize: 12))),
                                            Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Price', style: TextStyle(color: Colors.white54, fontSize: 12))),
                                            Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Stock', style: TextStyle(color: Colors.white54, fontSize: 12))),
                                            Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Actions', style: TextStyle(color: Colors.white54, fontSize: 12), textAlign: TextAlign.right)),
                                          ],
                                        ),
                                        ...products.map((pDoc) {
                                          final p = FundraisingProduct.fromMap(pDoc.id, pDoc.data() as Map<String, dynamic>);
                                          return TableRow(
                                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))),
                                            children: [
                                              Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 13))),
                                              Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('\$${p.price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 13))),
                                              Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('${p.initialStock}', style: const TextStyle(color: Colors.white, fontSize: 13))),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 6),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(LucideIcons.edit2, size: 14, color: Colors.white54),
                                                      onPressed: () {}, // TODO: Edit product
                                                      constraints: const BoxConstraints(),
                                                      padding: const EdgeInsets.all(4),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(LucideIcons.trash2, size: 14, color: Colors.redAccent),
                                                      onPressed: () {
                                                        _firestore
                                                            .collection('corps')
                                                            .doc(widget.corpsId)
                                                            .collection('fundraising_campaigns')
                                                            .doc(campaign.id)
                                                            .collection('products')
                                                            .doc(p.id)
                                                            .delete();
                                                      },
                                                      constraints: const BoxConstraints(),
                                                      padding: const EdgeInsets.all(4),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {}, // TODO: Edit campaign
                                icon: const Icon(LucideIcons.edit, size: 14),
                                label: const Text('Edit Campaign'),
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () {
                                  _firestore.collection('corps').doc(widget.corpsId).collection('fundraising_campaigns').doc(campaign.id).delete();
                                },
                                icon: const Icon(LucideIcons.trash2, size: 14),
                                label: const Text('Delete Campaign'),
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../providers/auth_provider.dart';
import '../../data/fundraising_models.dart';

class ReportTab extends StatefulWidget {
  final String corpsId;

  const ReportTab({Key? key, required this.corpsId}) : super(key: key);

  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedCampaignId;
  String _campaignName = 'Master Report';

  Future<List<Map<String, dynamic>>> _fetchMasterReportData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final cadetsList = List<dynamic>.from(auth.corpsData?.settings?['cadets'] ?? []);
    final cadetMap = {for (var c in cadetsList) (c['uid'] ?? c['id'] ?? '').toString(): c as Map<String, dynamic>};

    final snap = await _firestore.collection('corps').doc(widget.corpsId).collection('fundraising_campaigns').get();
    final campaignDocs = snap.docs;

    Map<String, double> assignedValues = {};
    Map<String, double> returnedValues = {};

    for (var cDoc in campaignDocs) {
      final cId = cDoc.id;
      final pSnap = await _firestore.collection('corps').doc(widget.corpsId).collection('fundraising_campaigns').doc(cId).collection('products').get();
      final productMap = {for (var doc in pSnap.docs) doc.id: doc.data() as Map<String, dynamic>};

      final aSnap = await _firestore.collection('corps').doc(widget.corpsId).collection('fundraising_campaigns').doc(cId).collection('assignments').get();
      final rSnap = await _firestore.collection('corps').doc(widget.corpsId).collection('fundraising_campaigns').doc(cId).collection('returns').get();

      for (var doc in aSnap.docs) {
        final a = FundraisingAssignment.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        final pData = productMap[a.productId];
        final price = pData != null ? (pData['price'] ?? 0.0).toDouble() : 0.0;
        assignedValues[a.cadetId] = (assignedValues[a.cadetId] ?? 0.0) + (a.quantity * price);
      }

      for (var doc in rSnap.docs) {
        final r = FundraisingReturn.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        returnedValues[r.cadetId] = (returnedValues[r.cadetId] ?? 0.0) + r.amountReturned;
      }
    }

    List<Map<String, dynamic>> rows = [];
    for (var cadetId in assignedValues.keys) {
      final assigned = assignedValues[cadetId] ?? 0.0;
      final returned = returnedValues[cadetId] ?? 0.0;
      final cData = cadetMap[cadetId];
      final name = cData != null ? '${cData['rank'] ?? ''} ${cData['lastName']}, ${cData['firstName']}' : 'Unknown';
      
      rows.add({
        'name': name,
        'assigned': assigned,
        'returned': returned,
        'progress': assigned > 0 ? (returned / assigned).clamp(0.0, 1.0) : 0.0,
      });
    }

    rows.sort((a, b) => b['progress'].compareTo(a['progress']));
    return rows;
  }

  Future<void> _generatePdf(List<Map<String, dynamic>> rows, double grandTotalAssigned, double grandTotalReturned) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating PDF...')));

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          build: (pw.Context context) {
            return [
              pw.Text('Fundraising Report: $_campaignName', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Cadet', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Value Assigned', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Money Returned', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Progress', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  ...rows.map((r) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(r['name'])),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('\$${r['assigned'].toStringAsFixed(2)}')),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('\$${r['returned'].toStringAsFixed(2)}')),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${(r['progress'] * 100).toInt()}%')),
                      ],
                    );
                  }).toList(),
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Totals', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('\$${grandTotalAssigned.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('\$${grandTotalReturned.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('')),
                    ],
                  ),
                ],
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: '${_campaignName.replaceAll(' ', '_')}_Report.pdf',
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCampaignSelector(),
        const SizedBox(height: 16),
        if (_selectedCampaignId != null)
          Expanded(child: _buildReportCard())
        else
          const Center(child: Text('Please select a campaign to view the report.', style: TextStyle(color: Colors.white54))),
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
            setState(() {
              _selectedCampaignId = 'ALL';
              _campaignName = 'Master Report (All Campaigns)';
            });
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
              items: [
                const DropdownMenuItem(value: 'ALL', child: Text('Master Report (All Campaigns)', style: TextStyle(fontWeight: FontWeight.bold))),
                ...campaigns.map((doc) {
                  final c = FundraisingCampaign.fromMap(doc.id, doc.data() as Map<String, dynamic>);
                  return DropdownMenuItem(value: c.id, child: Text(c.name));
                }),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedCampaignId = val;
                    if (val == 'ALL') {
                      _campaignName = 'Master Report (All Campaigns)';
                    } else {
                      final c = campaigns.firstWhere((doc) => doc.id == val);
                      _campaignName = FundraisingCampaign.fromMap(c.id, c.data() as Map<String, dynamic>).name;
                    }
                  });
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportCard() {
    if (_selectedCampaignId == 'ALL') {
      return FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchMasterReportData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error loading master report: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
          
          final rows = snapshot.data ?? [];
          double grandTotalAssigned = 0;
          double grandTotalReturned = 0;
          for (var r in rows) {
            grandTotalAssigned += r['assigned'];
            grandTotalReturned += r['returned'];
          }

          return _buildReportUI(rows, grandTotalAssigned, grandTotalReturned);
        },
      );
    }

    // For a single campaign, keep the real-time streams
    return Builder(
      builder: (context) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final cadetsList = List<dynamic>.from(auth.corpsData?.settings?['cadets'] ?? []);
        final cadetMap = {for (var c in cadetsList) (c['uid'] ?? c['id'] ?? '').toString(): c as Map<String, dynamic>};

        return StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('corps').doc(widget.corpsId).collection('fundraising_campaigns').doc(_selectedCampaignId).collection('products').snapshots(),
          builder: (context, productSnap) {
            if (!productSnap.hasData) return const Center(child: CircularProgressIndicator());
            final productDocs = productSnap.data!.docs;
            final productMap = {for (var doc in productDocs) doc.id: doc.data() as Map<String, dynamic>};

            return StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('corps').doc(widget.corpsId).collection('fundraising_campaigns').doc(_selectedCampaignId).collection('assignments').snapshots(),
              builder: (context, assignSnap) {
                if (!assignSnap.hasData) return const Center(child: CircularProgressIndicator());
                
                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('corps').doc(widget.corpsId).collection('fundraising_campaigns').doc(_selectedCampaignId).collection('returns').snapshots(),
                  builder: (context, returnSnap) {
                    if (!returnSnap.hasData) return const Center(child: CircularProgressIndicator());
                    
                    // Aggregate Assignments
                    Map<String, double> assignedValues = {};
                    for (var doc in assignSnap.data!.docs) {
                      final a = FundraisingAssignment.fromMap(doc.id, doc.data() as Map<String, dynamic>);
                      final pData = productMap[a.productId];
                      final price = pData != null ? (pData['price'] ?? 0.0).toDouble() : 0.0;
                      final value = a.quantity * price;
                      assignedValues[a.cadetId] = (assignedValues[a.cadetId] ?? 0.0) + value;
                    }

                    // Aggregate Returns
                    Map<String, double> returnedValues = {};
                    for (var doc in returnSnap.data!.docs) {
                      final r = FundraisingReturn.fromMap(doc.id, doc.data() as Map<String, dynamic>);
                      returnedValues[r.cadetId] = (returnedValues[r.cadetId] ?? 0.0) + r.amountReturned;
                    }

                    // Combine into list
                    List<Map<String, dynamic>> rows = [];
                    double grandTotalAssigned = 0;
                    double grandTotalReturned = 0;

                    for (var cadetId in assignedValues.keys) {
                      final assigned = assignedValues[cadetId] ?? 0.0;
                      final returned = returnedValues[cadetId] ?? 0.0;
                      final cData = cadetMap[cadetId];
                      final name = cData != null ? '${cData['rank'] ?? ''} ${cData['lastName']}, ${cData['firstName']}' : 'Unknown';
                      
                      rows.add({
                        'name': name,
                        'assigned': assigned,
                        'returned': returned,
                        'progress': assigned > 0 ? (returned / assigned).clamp(0.0, 1.0) : 0.0,
                      });

                      grandTotalAssigned += assigned;
                      grandTotalReturned += returned;
                    }

                    rows.sort((a, b) => b['progress'].compareTo(a['progress']));

                    return _buildReportUI(rows, grandTotalAssigned, grandTotalReturned);
                  }
                );
              }
            );
          }
        );
      }
    );
  }

  Widget _buildReportUI(List<Map<String, dynamic>> rows, double grandTotalAssigned, double grandTotalReturned) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fundraising Report: $_campaignName', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Leaderboard and summary of fundraising efforts.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => _generatePdf(rows, grandTotalAssigned, grandTotalReturned),
                icon: const Icon(LucideIcons.downloadCloud, size: 16),
                label: const Text('Generate PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: ListView(
              children: [
                const Row(
                  children: [
                    Expanded(flex: 3, child: Text('Cadet', style: TextStyle(color: Colors.white54, fontSize: 12))),
                    Expanded(flex: 2, child: Text('Value Assigned', style: TextStyle(color: Colors.white54, fontSize: 12))),
                    Expanded(flex: 2, child: Text('Money Returned', style: TextStyle(color: Colors.white54, fontSize: 12))),
                    Expanded(flex: 3, child: Text('Return Progress', style: TextStyle(color: Colors.white54, fontSize: 12))),
                  ],
                ),
                const Divider(color: Colors.white24, height: 24),
                ...rows.map((r) {
                  final progressPct = (r['progress'] * 100).toInt();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text(r['name'], style: const TextStyle(color: Colors.white, fontSize: 13))),
                        Expanded(flex: 2, child: Text('\$${r['assigned'].toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 13))),
                        Expanded(flex: 2, child: Text('\$${r['returned'].toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 13))),
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: r['progress'],
                                  backgroundColor: Colors.white.withOpacity(0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    progressPct >= 100 ? Colors.green : const Color(0xFF4A6B9C),
                                  ),
                                  minHeight: 6,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('$progressPct%', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const Divider(color: Colors.white24, height: 24),
                Row(
                  children: [
                    const Expanded(flex: 3, child: Text('Totals', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('\$${grandTotalAssigned.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('\$${grandTotalReturned.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
                    const Expanded(flex: 3, child: SizedBox.shrink()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

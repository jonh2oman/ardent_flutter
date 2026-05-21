import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../models/unit_asset.dart';
import '../models/user_data.dart';

class EquipmentLoanManagerTab extends StatefulWidget {
  final Future<void> Function(BuildContext, String, UnitAsset, AuthProvider) onPrintCard;

  const EquipmentLoanManagerTab({super.key, required this.onPrintCard});

  @override
  State<EquipmentLoanManagerTab> createState() => _EquipmentLoanManagerTabState();
}

class _EquipmentLoanManagerTabState extends State<EquipmentLoanManagerTab> {
  String? _selectedAssetId;
  String _recipientType = 'Cadet';
  String? _selectedRecipient;
  DateTime? _returnDate;

  Future<List<String>> _fetchMembers(String corpsId, AuthProvider auth, String type) async {
    if (type == 'Officer') {
      final snapshot = await FirebaseFirestore.instance.collection('users').where('corpsId', isEqualTo: corpsId).get();
      final names = snapshot.docs.map((d) {
        final user = UserData.fromMap(d.data(), d.id);
        return user.name;
      }).where((name) => name.isNotEmpty && name != 'Unknown' && name != 'Incomplete Profile').toSet().toList();
      names.sort();
      return names;
    } else {
      final cadets = List<dynamic>.from(auth.corpsData?.settings['cadets'] ?? []);
      final names = cadets.map((c) {
        final uid = c['uid']?.toString() ?? c['id']?.toString() ?? 'unknown';
        final user = UserData.fromMap(Map<String, dynamic>.from(c as Map), uid);
        return user.name;
      }).where((name) => name.isNotEmpty && name != 'Unknown' && name != 'Incomplete Profile').toSet().toList();
      names.sort();
      return names;
    }
  }

  Future<void> _createLoan(String corpsId) async {
    if (_selectedAssetId == null || _selectedRecipient == null || _returnDate == null) return;

    await FirebaseFirestore.instance.collection('corps').doc(corpsId).collection('assets').doc(_selectedAssetId).update({
      'assignedTo': _selectedRecipient,
      'recipientType': _recipientType,
      'dueDate': _returnDate!.toIso8601String(),
    });

    if (mounted) {
      setState(() {
        _selectedAssetId = null;
        _selectedRecipient = null;
        _returnDate = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loan created successfully')));
    }
  }

  Future<void> _returnLoan(String corpsId, String assetId) async {
    await FirebaseFirestore.instance.collection('corps').doc(corpsId).collection('assets').doc(assetId).update({
      'assignedTo': null,
      'recipientType': null,
      'dueDate': null,
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final corpsId = authProvider.corpsData?.id;

    if (corpsId == null) {
      return const Center(child: Text('No unit available'));
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Panel: Create New Loan
          Expanded(
            flex: 1,
            child: Card(
              color: const Color(0xFF141414),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white10)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Create New Loan', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Select an available asset and a cadet to create a new loan record.', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 24),
                    
                    const Text('Available Asset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('corps').doc(corpsId).collection('assets').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const CircularProgressIndicator();
                        final availableAssets = snapshot.data!.docs.where((d) => (d.data() as Map<String, dynamic>)['assignedTo'] == null).toList();
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(filled: true, fillColor: Colors.black12, border: OutlineInputBorder()),
                          hint: const Text('Select an asset...'),
                          value: _selectedAssetId,
                          items: availableAssets.map((d) {
                            final data = d.data() as Map<String, dynamic>;
                            return DropdownMenuItem(value: d.id, child: Text(data['name'] ?? 'Unknown'));
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedAssetId = val),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    const Text('Recipient Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'Cadet', label: Text('Cadet'), icon: Icon(LucideIcons.users)),
                        ButtonSegment(value: 'Officer', label: Text('Officer'), icon: Icon(LucideIcons.shield)),
                      ],
                      selected: {_recipientType},
                      onSelectionChanged: (set) {
                        setState(() {
                          _recipientType = set.first;
                          _selectedRecipient = null;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    Text('Recipient ${_recipientType}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    FutureBuilder<List<String>>(
                      future: _fetchMembers(corpsId, authProvider, _recipientType),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const CircularProgressIndicator();
                        final names = snapshot.data!;
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(filled: true, fillColor: Colors.black12, border: OutlineInputBorder()),
                          hint: Text('Select a ${_recipientType.toLowerCase()}...'),
                          value: _selectedRecipient,
                          items: names.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                          onChanged: (val) => setState(() => _selectedRecipient = val),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    const Text('Return Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (date != null) {
                          setState(() => _returnDate = date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.calendar, size: 18),
                            const SizedBox(width: 8),
                            Text(_returnDate != null ? DateFormat('MMMM d, yyyy').format(_returnDate!) : 'Select return date...'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: (_selectedAssetId != null && _selectedRecipient != null && _returnDate != null)
                            ? () => _createLoan(corpsId)
                            : null,
                        child: const Text('Create Loan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          
          // Right Panel: Currently Loaned Items
          Expanded(
            flex: 2,
            child: Card(
              color: const Color(0xFF141414),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white10)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Currently Loaned Items', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('A list of all equipment currently on loan to cadets and officers.', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 24),
                    
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('corps').doc(corpsId).collection('assets').where('assignedTo', isNull: false).snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                          final docs = snapshot.data!.docs;
                          if (docs.isEmpty) {
                            return const Center(child: Text('No active loans.', style: TextStyle(color: Colors.grey)));
                          }

                          return ListView.separated(
                            itemCount: docs.length,
                            separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                            itemBuilder: (context, index) {
                              final data = docs[index].data() as Map<String, dynamic>;
                              final asset = UnitAsset.fromMap(data, docs[index].id);
                              
                              DateTime? dueDate;
                              if (asset.dueDate != null) {
                                dueDate = DateTime.tryParse(asset.dueDate!);
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(asset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(asset.assignedTo ?? 'Unknown'),
                                          if (asset.recipientType != null)
                                            Container(
                                              margin: const EdgeInsets.only(top: 4),
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.white10,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(asset.recipientType!.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(dueDate != null ? DateFormat('MMMM d, yyyy').format(dueDate) : 'No due date'),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          OutlinedButton.icon(
                                            icon: const Icon(LucideIcons.rotateCcw, size: 16),
                                            label: const Text('Return'),
                                            onPressed: () => _returnLoan(corpsId, asset.id),
                                            style: OutlinedButton.styleFrom(foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12)),
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton.icon(
                                            icon: const Icon(LucideIcons.printer, size: 16),
                                            label: const Text('Print Card'),
                                            onPressed: () => widget.onPrintCard(context, corpsId, asset, authProvider),
                                            style: OutlinedButton.styleFrom(foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

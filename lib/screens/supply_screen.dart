import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/auth_provider.dart';
import '../models/user_data.dart';
import '../models/unit_asset.dart';
import 'equipment_loan_manager_tab.dart';

class SupplyScreen extends StatefulWidget {
  const SupplyScreen({super.key});

  @override
  State<SupplyScreen> createState() => _SupplyScreenState();
}

class _SupplyScreenState extends State<SupplyScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    
    final cadets = List<dynamic>.from(authProvider.corpsData?.settings['cadets'] ?? [])
        .map((c) {
          final uid = c['uid']?.toString() ?? c['id']?.toString() ?? 'unknown';
          return UserData.fromMap(Map<String, dynamic>.from(c), uid);
        })
        .where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 24.0, top: 24.0, right: 24.0),
              child: Row(
                children: [
                  const Icon(LucideIcons.package, color: Colors.blueAccent, size: 28),
                  const SizedBox(width: 16),
                  Text('Supply & Logistics', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const TabBar(
              tabs: [
                Tab(text: 'Cadet Kit'),
                Tab(text: 'Unit Assets'),
                Tab(text: 'Equipment Loans'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Cadet Kit
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
            
            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  icon: Icon(LucideIcons.search, size: 18, color: Colors.white30),
                  hintText: 'Search for a cadet...',
                  hintStyle: TextStyle(color: Colors.white30),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: ListView.builder(
                itemCount: cadets.length,
                itemBuilder: (context, index) {
                  final cadet = cadets[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueAccent.withOpacity(0.2),
                        child: Text(
                          cadet.name.isNotEmpty ? cadet.name[0].toUpperCase() : '?', 
                          style: const TextStyle(color: Colors.blueAccent)
                        ),
                      ),
                      title: Text(cadet.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${cadet.rank ?? 'Cadet'} • ${cadet.phase ?? 'No Phase'}', style: const TextStyle(fontSize: 12, color: Colors.white30)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('UNIFORM SIZES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildSizeTag('Headdress', cadet.uniformSizes['headdress'] ?? 'N/A'),
                                  _buildSizeTag('Tunic', cadet.uniformSizes['tunic'] ?? 'N/A'),
                                  _buildSizeTag('Trousers', cadet.uniformSizes['trousers'] ?? 'N/A'),
                                  _buildSizeTag('Boots', cadet.uniformSizes['boots'] ?? 'N/A'),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _showEditSizesDialog(context, authProvider, cadet),
                                      icon: const Icon(LucideIcons.edit3, size: 14),
                                      label: const Text('Update Sizes'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _showLoanCardPreview(context, cadet),
                                      icon: const Icon(LucideIcons.printer, size: 14),
                                      label: const Text('Loan Card'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _showIssueKitDialog(context, authProvider, cadet),
                                      icon: const Icon(LucideIcons.plusCircle, size: 14),
                                      label: const Text('Issue Item'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
                      ],
                    ),
                  ),
                  // Tab 2: Unit Assets
                  const UnitAssetsTab(),
                  EquipmentLoanManagerTab(onPrintCard: generateAssetLoanCard),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeTag(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.white30)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showEditSizesDialog(BuildContext context, AuthProvider auth, UserData cadet) {
    final controllers = {
      'headdress': TextEditingController(text: cadet.uniformSizes['headdress']),
      'tunic': TextEditingController(text: cadet.uniformSizes['tunic']),
      'trousers': TextEditingController(text: cadet.uniformSizes['trousers']),
      'boots': TextEditingController(text: cadet.uniformSizes['boots']),
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text('Update Sizes: ${cadet.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: controllers.entries.map((e) => TextField(
            controller: e.value,
            decoration: InputDecoration(labelText: e.key.toUpperCase()),
            style: const TextStyle(color: Colors.white),
          )).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              Map<String, String> newSizes = {};
              controllers.forEach((k, v) => newSizes[k] = v.text);
              
              final List<dynamic> allCadets = List.from(auth.corpsData?.settings['cadets'] ?? []);
              final index = allCadets.indexWhere((c) => c['uid']?.toString() == cadet.id || c['id']?.toString() == cadet.id);
              if (index != -1) {
                // Ensure we are working with a modifiable map
                final updatedCadet = Map<String, dynamic>.from(allCadets[index]);
                updatedCadet['uniformSizes'] = newSizes;
                allCadets[index] = updatedCadet;

                final corpsId = auth.corpsData?.id;
                if (corpsId != null) {
                  await FirebaseFirestore.instance.collection('corps').doc(corpsId).update({
                    'settings.cadets': allCadets,
                  });
                }
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('SAVE SIZES'),
          ),
        ],
      ),
    );
  }

  void _showIssueKitDialog(BuildContext context, AuthProvider auth, UserData cadet) {
    final itemController = TextEditingController();
    final serialController = TextEditingController();
    final sizeController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    String condition = 'New';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text('Issue Kit to ${cadet.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: itemController, decoration: const InputDecoration(labelText: 'ITEM NAME (e.g. Parka)'), style: const TextStyle(color: Colors.white)),
                TextField(controller: serialController, decoration: const InputDecoration(labelText: 'SERIAL NUMBER (Optional)'), style: const TextStyle(color: Colors.white)),
                TextField(controller: sizeController, decoration: const InputDecoration(labelText: 'SIZE ISSUED (Optional)'), style: const TextStyle(color: Colors.white)),
                TextField(controller: qtyController, decoration: const InputDecoration(labelText: 'QUANTITY'), keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: condition,
                  items: ['New', 'Good', 'Fair', 'Poor'].map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white)))).toList(),
                  onChanged: (val) => setDialogState(() => condition = val!),
                  decoration: const InputDecoration(labelText: 'CONDITION'),
                  dropdownColor: const Color(0xFF2A2A2A),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                final newItem = {
                  'item': itemController.text,
                  'serial': serialController.text,
                  'size': sizeController.text,
                  'qty': int.tryParse(qtyController.text) ?? 1,
                  'condition': condition,
                  'date': DateTime.now().toString().split(' ')[0],
                };
              
              final List<dynamic> allCadets = List.from(auth.corpsData?.settings['cadets'] ?? []);
              final index = allCadets.indexWhere((c) => c['uid']?.toString() == cadet.id || c['id']?.toString() == cadet.id);
              if (index != -1) {
                // Ensure we are working with a modifiable map
                final updatedCadet = Map<String, dynamic>.from(allCadets[index]);
                final List<dynamic> kit = List.from(updatedCadet['issuedKit'] ?? []);
                kit.add(newItem);
                updatedCadet['issuedKit'] = kit;
                allCadets[index] = updatedCadet;

                final corpsId = auth.corpsData?.id;
                if (corpsId != null) {
                  await FirebaseFirestore.instance.collection('corps').doc(corpsId).update({
                    'settings.cadets': allCadets,
                  });
                }
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('ISSUE ITEM'),
          ),
        ],
      ),
      ),
    );
  }

  void _showLoanCardPreview(BuildContext context, UserData cadet) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.blue[900],
              title: Text('Loan Card: ${cadet.name}'),
              actions: [
                IconButton(
                  icon: const Icon(LucideIcons.printer), 
                  onPressed: () => _printLoanCard(cadet),
                  tooltip: 'Print/Save PDF',
                ),
                IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          const Text('PERSONAL ISSUE & LOAN CARD', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black)),
                          const Text('RCSCC 288 ARDENT - SUPPLY DEPARTMENT', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          const SizedBox(height: 10),
                          Container(height: 2, width: 250, color: Colors.black),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoBox('CADET NAME', cadet.name),
                        _buildInfoBox('RANK', cadet.rank ?? 'CADET'),
                        _buildInfoBox('PHASE', cadet.phase ?? 'N/A'),
                      ],
                    ),
                    const SizedBox(height: 40),
                    const Text('ISSUED ITEMS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black, decoration: TextDecoration.underline)),
                    const SizedBox(height: 20),
                    Table(
                      border: TableBorder.all(color: Colors.black12),
                      children: [
                        const TableRow(
                          children: [
                            Padding(padding: EdgeInsets.all(8.0), child: Text('ITEM', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                            Padding(padding: EdgeInsets.all(8.0), child: Text('SIZE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                            Padding(padding: EdgeInsets.all(8.0), child: Text('QTY', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                            Padding(padding: EdgeInsets.all(8.0), child: Text('COND', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                            Padding(padding: EdgeInsets.all(8.0), child: Text('SERIAL #', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                            Padding(padding: EdgeInsets.all(8.0), child: Text('DATE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                          ],
                        ),
                        if (cadet.issuedKit.isEmpty)
                          const TableRow(
                            children: [
                              Padding(padding: EdgeInsets.all(8.0), child: Text('No items currently issued.', style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic))),
                              Padding(padding: EdgeInsets.all(8.0), child: Text('-', style: TextStyle(color: Colors.black54))),
                              Padding(padding: EdgeInsets.all(8.0), child: Text('-', style: TextStyle(color: Colors.black54))),
                              Padding(padding: EdgeInsets.all(8.0), child: Text('-', style: TextStyle(color: Colors.black54))),
                              Padding(padding: EdgeInsets.all(8.0), child: Text('-', style: TextStyle(color: Colors.black54))),
                              Padding(padding: EdgeInsets.all(8.0), child: Text('-', style: TextStyle(color: Colors.black54))),
                            ],
                          )
                        else
                          ...cadet.issuedKit.map((item) => TableRow(
                            children: [
                              Padding(padding: EdgeInsets.all(8.0), child: Text(item['item'] ?? '', style: const TextStyle(color: Colors.black87))),
                              Padding(padding: EdgeInsets.all(8.0), child: Text(item['size'] ?? '-', style: const TextStyle(color: Colors.black87))),
                              Padding(padding: EdgeInsets.all(8.0), child: Text('${item['qty'] ?? 1}', style: const TextStyle(color: Colors.black87))),
                              Padding(padding: EdgeInsets.all(8.0), child: Text(item['condition'] ?? '-', style: const TextStyle(color: Colors.black87))),
                              Padding(padding: EdgeInsets.all(8.0), child: Text(item['serial'] ?? '-', style: const TextStyle(color: Colors.black87))),
                              Padding(padding: EdgeInsets.all(8.0), child: Text(item['date'] ?? '', style: const TextStyle(color: Colors.black87))),
                            ],
                          )).toList(),
                      ],
                    ),
                    const SizedBox(height: 60),
                    const Text('DECLARATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
                    const SizedBox(height: 10),
                    const Text(
                      'I acknowledge receipt of the items listed above and understand that I am responsible for their safe keeping. I agree to return all items upon request or upon leaving the unit.',
                      style: TextStyle(fontSize: 12, color: Colors.black87, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 60),
                    Row(
                      children: [
                        Expanded(child: Column(children: [Container(height: 1, color: Colors.black), const Text('CADET SIGNATURE', style: TextStyle(fontSize: 10, color: Colors.black54))])),
                        const SizedBox(width: 40),
                        Expanded(child: Column(children: [Container(height: 1, color: Colors.black), const Text('DATE', style: TextStyle(fontSize: 10, color: Colors.black54))])),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.bold)),
        Text(value.toUpperCase(), style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Future<void> _printLoanCard(UserData cadet) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'ROYAL CANADIAN SEA CADETS',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'PERSONAL ISSUE & LOAN CARD',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'RCSCC 288 ARDENT - SUPPLY DEPARTMENT',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Container(height: 1.5, color: PdfColors.black),
                    ],
                  ),
                ),
                pw.SizedBox(height: 32),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('CADET NAME', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                        pw.Text(cadet.name.toUpperCase(), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('RANK', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                        pw.Text((cadet.rank ?? 'CADET').toUpperCase(), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('PHASE', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                        pw.Text((cadet.phase ?? 'N/A').toUpperCase(), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Text('UNIFORM SIZES', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Text('Headdress', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                      pw.Text(cadet.uniformSizes['headdress'] ?? 'N/A', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ]),
                    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Text('Tunic', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                      pw.Text(cadet.uniformSizes['tunic'] ?? 'N/A', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ]),
                    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Text('Trousers', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                      pw.Text(cadet.uniformSizes['trousers'] ?? 'N/A', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ]),
                    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Text('Boots', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                      pw.Text(cadet.uniformSizes['boots'] ?? 'N/A', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ]),
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Text('ISSUED ITEMS', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(2),
                    4: const pw.FlexColumnWidth(2),
                    5: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('ITEM', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('SIZE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('QTY', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('COND', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('SERIAL #', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('DATE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                      ],
                    ),
                    if (cadet.issuedKit.isEmpty)
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('No items issued.', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('-', style: const pw.TextStyle(fontSize: 8))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('-', style: const pw.TextStyle(fontSize: 8))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('-', style: const pw.TextStyle(fontSize: 8))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('-', style: const pw.TextStyle(fontSize: 8))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('-', style: const pw.TextStyle(fontSize: 8))),
                        ],
                      )
                    else
                      ...cadet.issuedKit.map((item) {
                        final itemName = item['item']?.toString() ?? '-';
                        final sizeName = item['size']?.toString() ?? '-';
                        final qtyVal = item['qty']?.toString() ?? '1';
                        final condVal = item['condition']?.toString() ?? '-';
                        final serialVal = item['serial']?.toString() ?? '-';
                        final dateVal = item['date']?.toString() ?? '-';
                        return pw.TableRow(
                          children: [
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(itemName.isEmpty ? '-' : itemName, style: const pw.TextStyle(fontSize: 8))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(sizeName.isEmpty ? '-' : sizeName, style: const pw.TextStyle(fontSize: 8))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(qtyVal, style: const pw.TextStyle(fontSize: 8))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(condVal.isEmpty ? '-' : condVal, style: const pw.TextStyle(fontSize: 8))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(serialVal.isEmpty ? '-' : serialVal, style: const pw.TextStyle(fontSize: 8))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(dateVal.isEmpty ? '-' : dateVal, style: const pw.TextStyle(fontSize: 8))),
                          ],
                        );
                      }).toList(),
                  ],
                ),
                pw.SizedBox(height: 32),
                pw.Text('DECLARATION', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(
                  'I acknowledge receipt of the items listed above and understand that I am responsible for their safe keeping. I agree to return all items clean, laundered, and in good condition upon request or upon leaving the unit.',
                  style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
                ),
                pw.SizedBox(height: 40),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          pw.Container(height: 0.5, color: PdfColors.black),
                          pw.SizedBox(height: 4),
                          pw.Text('CADET SIGNATURE', style: const pw.TextStyle(fontSize: 7)),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 32),
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          pw.Container(height: 0.5, color: PdfColors.black),
                          pw.SizedBox(height: 4),
                          pw.Text('ISSUING OFFICER SIGNATURE', style: const pw.TextStyle(fontSize: 7)),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 32),
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          pw.Container(height: 0.5, color: PdfColors.black),
                          pw.SizedBox(height: 4),
                          pw.Text('DATE', style: const pw.TextStyle(fontSize: 7)),
                        ],
                      ),
                    ),
                  ],
                ),
              ];
        },
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'loan_card_${cadet.name.replaceAll(' ', '_')}.pdf',
    );
  }

  // Refactored from UnitAssetsTab so EquipmentLoanManagerTab can also use it
  Future<void> generateAssetLoanCard(BuildContext context, String corpsId, UnitAsset asset, AuthProvider auth) async {
    final pdf = pw.Document();
    final dateStr = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
    final assignedToName = asset.assignedTo ?? 'Unassigned';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('UNIT ASSET LOAN CARD', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('LOANED TO: $assignedToName', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(1),
                  3: pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('ASSET NAME', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('QTY', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('COND', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('SERIAL #', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(asset.name, style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(asset.quantity.toString(), style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(asset.condition, style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(asset.serialNumber ?? '-', style: const pw.TextStyle(fontSize: 10))),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 32),
              pw.Text('DECLARATION', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text(
                'I acknowledge receipt of the unit asset listed above and understand that I am responsible for its safe keeping. I agree to return the item in good condition upon request or upon leaving the unit.',
                style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
              ),
              pw.SizedBox(height: 60),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        pw.Container(height: 0.5, color: PdfColors.black),
                        pw.SizedBox(height: 4),
                        pw.Text('SIGNATURE', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 32),
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        pw.Container(height: 0.5, color: PdfColors.black),
                        pw.SizedBox(height: 4),
                        pw.Text('ISSUING OFFICER SIGNATURE', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 32),
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        pw.Container(height: 0.5, color: PdfColors.black),
                        pw.SizedBox(height: 4),
                        pw.Text('DATE', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'asset_loan_${asset.name.replaceAll(' ', '_')}.pdf',
    );
  }
}

class UnitAssetsTab extends StatefulWidget {
  const UnitAssetsTab({super.key});

  @override
  State<UnitAssetsTab> createState() => _UnitAssetsTabState();
}

class _UnitAssetsTabState extends State<UnitAssetsTab> {
  bool _showSlocOnly = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final corpsId = authProvider.corpsData?.id;

    if (corpsId == null) {
      return const Center(child: Text('No unit available'));
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Show SLOC Only'),
                  Switch(
                    value: _showSlocOnly,
                    onChanged: (val) => setState(() => _showSlocOnly = val),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddAssetDialog(context, corpsId, authProvider),
                icon: const Icon(LucideIcons.plus),
                label: const Text('Add Asset'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('corps')
                  .doc(corpsId)
                  .collection('assets')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var docs = snapshot.data!.docs;
                if (_showSlocOnly) {
                  docs = docs.where((d) => (d.data() as Map<String, dynamic>)['isSloc'] == true).toList();
                }

                if (docs.isEmpty) {
                  return const Center(child: Text('No assets found.'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final asset = UnitAsset.fromMap(data, docs[index].id);
                    return Card(
                      color: Colors.white.withOpacity(0.05),
                      child: ListTile(
                        leading: Icon(asset.isSloc ? LucideIcons.shieldCheck : LucideIcons.package),
                        title: Text(asset.name),
                        subtitle: Text('Qty: ${asset.quantity} • Cond: ${asset.condition}${asset.assignedTo != null && asset.assignedTo!.isNotEmpty ? ' • Loaned to: ${asset.assignedTo}' : ''}'),
                        trailing: Text(asset.serialNumber ?? 'No Serial'),
                        onTap: () => _showEditAssetDialog(context, corpsId, authProvider, asset),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddAssetDialog(BuildContext context, String corpsId, AuthProvider auth) async {
    final names = await _fetchMemberNames(corpsId, auth);
    if (context.mounted) _showAssetDialog(context, corpsId, auth, null, names);
  }

  Future<void> _showEditAssetDialog(BuildContext context, String corpsId, AuthProvider auth, UnitAsset asset) async {
    final names = await _fetchMemberNames(corpsId, auth);
    if (context.mounted) _showAssetDialog(context, corpsId, auth, asset, names);
  }

  Future<List<String>> _fetchMemberNames(String corpsId, AuthProvider auth) async {
    final snapshot = await FirebaseFirestore.instance.collection('users').where('corpsId', isEqualTo: corpsId).get();
    final names = snapshot.docs.map((d) => (d.data() as Map<String, dynamic>)['name']?.toString() ?? 'Unknown').toList();
    final cadets = List<dynamic>.from(auth.corpsData?.settings['cadets'] ?? []);
    for (var c in cadets) {
      final n = c['name']?.toString();
      if (n != null && !names.contains(n)) names.add(n);
    }
    names.sort();
    return names;
  }

  void _showAssetDialog(BuildContext context, String corpsId, AuthProvider auth, UnitAsset? asset, List<String> memberNames) {
    final nameCtrl = TextEditingController(text: asset?.name);
    final descCtrl = TextEditingController(text: asset?.description);
    final serialCtrl = TextEditingController(text: asset?.serialNumber);
    final qtyCtrl = TextEditingController(text: asset?.quantity.toString() ?? '1');
    bool isSloc = asset?.isSloc ?? false;
    String condition = asset?.condition ?? 'Good';
    String? assignedTo = asset?.assignedTo;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text(asset == null ? 'Add Asset' : 'Edit Asset'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                TextField(controller: serialCtrl, decoration: const InputDecoration(labelText: 'Serial Number')),
                TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: condition,
                  items: ['New', 'Good', 'Fair', 'Poor'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setDialogState(() => condition = val!),
                  decoration: const InputDecoration(labelText: 'Condition'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  value: assignedTo != null && memberNames.contains(assignedTo) ? assignedTo : null,
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('None')),
                    ...memberNames.map((m) => DropdownMenuItem(value: m, child: Text(m))),
                  ],
                  onChanged: (val) => setDialogState(() => assignedTo = val),
                  decoration: const InputDecoration(labelText: 'Assigned To / Loaned To'),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Is SLOC Item?'),
                  value: isSloc,
                  onChanged: (val) => setDialogState(() => isSloc = val),
                ),
              ],
            ),
          ),
          actions: [
            if (asset != null) ...[
              IconButton(
                icon: const Icon(LucideIcons.printer, color: Colors.blueAccent),
                onPressed: () {
                  Navigator.pop(context);
                  final parent = context.findAncestorStateOfType<_SupplyScreenState>();
                  parent?.generateAssetLoanCard(context, corpsId, asset, auth);
                },
                tooltip: 'Print Loan Card',
              ),
              TextButton(
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('corps').doc(corpsId).collection('assets').doc(asset.id).delete();
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('DELETE', style: TextStyle(color: Colors.red)),
              ),
            ],
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'name': nameCtrl.text,
                  'description': descCtrl.text,
                  'serialNumber': serialCtrl.text,
                  'quantity': int.tryParse(qtyCtrl.text) ?? 1,
                  'condition': condition,
                  'isSloc': isSloc,
                  'assignedTo': assignedTo,
                };
                if (asset == null) {
                  await FirebaseFirestore.instance.collection('corps').doc(corpsId).collection('assets').add(data);
                } else {
                  await FirebaseFirestore.instance.collection('corps').doc(corpsId).collection('assets').doc(asset.id).update(data);
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }

}

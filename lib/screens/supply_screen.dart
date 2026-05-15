import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/user_data.dart';

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
          final uid = c['uid']?.toString() ?? 'unknown';
          return UserData.fromMap(Map<String, dynamic>.from(c), uid);
        })
        .where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.package, color: Colors.blueAccent, size: 28),
                const SizedBox(width: 16),
                Text('Supply & Logistics', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            
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
              final index = allCadets.indexWhere((c) => c['uid'] == cadet.id);
              if (index != -1) {
                allCadets[index]['uniformSizes'] = newSizes;
                await FirebaseFirestore.instance.collection('corps').doc(auth.userData?.corpsId).update({
                  'settings.cadets': allCadets,
                });
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text('Issue Kit to ${cadet.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: itemController, decoration: const InputDecoration(labelText: 'ITEM NAME (e.g. Parka)'), style: const TextStyle(color: Colors.white)),
            TextField(controller: serialController, decoration: const InputDecoration(labelText: 'SERIAL NUMBER'), style: const TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final newItem = {
                'item': itemController.text,
                'serial': serialController.text,
                'date': DateTime.now().toString().split(' ')[0],
              };
              
              final List<dynamic> allCadets = List.from(auth.corpsData?.settings['cadets'] ?? []);
              final index = allCadets.indexWhere((c) => c['uid'] == cadet.id);
              if (index != -1) {
                final List<dynamic> kit = List.from(allCadets[index]['issuedKit'] ?? []);
                kit.add(newItem);
                allCadets[index]['issuedKit'] = kit;
                await FirebaseFirestore.instance.collection('corps').doc(auth.userData?.corpsId).update({
                  'settings.cadets': allCadets,
                });
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('ISSUE ITEM'),
          ),
        ],
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
                IconButton(icon: const Icon(LucideIcons.printer), onPressed: () {}),
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
                            Padding(padding: EdgeInsets.all(8.0), child: Text('SERIAL #', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                            Padding(padding: EdgeInsets.all(8.0), child: Text('DATE ISSUED', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                          ],
                        ),
                        ...cadet.issuedKit.map((item) => TableRow(
                          children: [
                            Padding(padding: EdgeInsets.all(8.0), child: Text(item['item'] ?? '', style: const TextStyle(color: Colors.black87))),
                            Padding(padding: EdgeInsets.all(8.0), child: Text(item['serial'] ?? '', style: const TextStyle(color: Colors.black87))),
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
}

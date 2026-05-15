import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_data.dart';
import '../widgets/stat_card.dart';
import '../providers/auth_provider.dart';
import '../data/curriculum.dart';

class CadetDetailScreen extends StatelessWidget {
  final UserData cadet;

  const CadetDetailScreen({super.key, required this.cadet});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final age = _calculateAge(cadet.dob);
    
    // Calculate live attendance
    final attendanceData = auth.attendance;
    int totalNights = attendanceData.length;
    int presentNights = 0;
    
    attendanceData.forEach((date, statuses) {
      final status = statuses[cadet.id];
      if (status == 'Present' || status == 'Late') {
        presentNights++;
      }
    });
    
    final attendancePercent = totalNights > 0 
      ? (presentNights / totalNights * 100).toInt() 
      : 100;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(cadet.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Text(cadet.name.isNotEmpty ? cadet.name[0] : 'C', style: TextStyle(fontSize: 32, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cadet.rank ?? 'Cadet', style: TextStyle(fontSize: 18, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                      Text(cadet.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1.0)),
                      Text('PHASE ${cadet.phase ?? 'N/A'} • CIN: ${cadet.cin ?? '---'}', style: const TextStyle(fontSize: 12, color: Colors.white30, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Quick Stats
            Row(
              children: [
                Expanded(child: StatCard(title: 'Age', value: age > 0 ? '$age' : '--', icon: LucideIcons.user, iconColor: Colors.blueAccent)),
                const SizedBox(width: 16),
                Expanded(child: StatCard(title: 'Attendance', value: '$attendancePercent%', icon: LucideIcons.checkCircle, iconColor: Colors.greenAccent)),
                const SizedBox(width: 16),
                Expanded(child: StatCard(title: 'Merits', value: '${cadet.merits}', icon: LucideIcons.coins, iconColor: Colors.amberAccent)),
              ],
            ),
            const SizedBox(height: 32),

            // Personal Information
            _buildSection(theme, 'Personal Information', [
              _buildDetailRow('Rank', cadet.rank ?? 'Cadet'),
              _buildDetailRow('Date of Birth', cadet.dob != null ? DateFormat('MMM d, yyyy').format(cadet.dob!) : 'Unknown'),
              _buildDetailRow('Personal Phone', cadet.phone ?? 'N/A'),
              _buildDetailRow('Personal Email', cadet.personalEmail ?? 'N/A'),
              _buildDetailRow('Cadet Email', cadet.cadetEmail ?? 'N/A'),
            ]),
            
            const SizedBox(height: 32),

            // Address
            _buildSection(theme, 'Address', [
              _buildDetailRow('Street', cadet.address?['street'] ?? 'N/A'),
              _buildDetailRow('City', cadet.address?['city'] ?? 'N/A'),
              _buildDetailRow('Province', cadet.address?['province'] ?? 'N/A'),
              _buildDetailRow('Postal Code', cadet.address?['postalCode'] ?? 'N/A'),
            ]),

            const SizedBox(height: 32),

            // Guardians
            if (cadet.parents != null && cadet.parents!.isNotEmpty)
              _buildSection(theme, 'Guardians', cadet.parents!.map((p) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['name'] ?? 'Unknown Parent', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${p['relationship'] ?? 'Guardian'} • ${p['phone'] ?? 'No Phone'}', style: const TextStyle(fontSize: 12, color: Colors.white30)),
                  const SizedBox(height: 12),
                ],
              )).toList()),

            const SizedBox(height: 32),

            // Medical
            _buildSection(theme, 'Medical Information', [
              _buildDetailRow('Health #', cadet.provincialHealthNumber ?? 'N/A'),
              _buildDetailRow('Insurance', cadet.privateInsuranceProvider ?? 'N/A'),
            ]),
            
            const SizedBox(height: 32),
            
            _buildSection(theme, 'Training Progress', _buildProgressList(cadet)),

            const SizedBox(height: 32),

            // Uniform Sizes
            _buildSection(theme, 'Uniform Sizes', [
              _buildDetailRow('Headdress', cadet.uniformSizes['headdress'] ?? 'N/A'),
              _buildDetailRow('Tunic/Shirt', cadet.uniformSizes['tunic'] ?? 'N/A'),
              _buildDetailRow('Trousers', cadet.uniformSizes['trousers'] ?? 'N/A'),
              _buildDetailRow('Boots', cadet.uniformSizes['boots'] ?? 'N/A'),
            ]),

            const SizedBox(height: 32),

            // Issued Kit
            _buildSection(theme, 'Issued Kit Ledger', [
              if (cadet.issuedKit.isEmpty)
                const Center(child: Text('No kit currently issued', style: TextStyle(color: Colors.white24, fontSize: 12)))
              else
                ...cadet.issuedKit.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Icon(LucideIcons.package, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['item'] ?? 'Unknown Item', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('S/N: ${item['serial'] ?? '---'} • Issued: ${item['date'] ?? '---'}', style: const TextStyle(fontSize: 10, color: Colors.white30)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
            ]),

            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => _showAwardMeritsDialog(context, auth),
                icon: const Icon(LucideIcons.award),
                label: const Text('AWARD MERITS', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => _confirmSOS(context, auth),
                icon: const Icon(LucideIcons.userMinus),
                label: const Text('STRIKE OFF STRENGTH', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSOS(BuildContext context, AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('STRIKE OFF STRENGTH?'),
        content: Text('Are you sure you want to permanently remove ${cadet.name} from the roster? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final corpsId = auth.userData?.corpsId;
      if (corpsId == null) return;

      final corpsRef = FirebaseFirestore.instance.collection('corps').doc(corpsId);
      final corpsDoc = await corpsRef.get();
      if (!corpsDoc.exists) return;

      final List<dynamic> cadets = List.from(corpsDoc.data()?['settings']?['cadets'] ?? []);
      cadets.removeWhere((c) => c['uid'] == cadet.id);
      
      await corpsRef.update({
        'settings.cadets': cadets,
      });

      if (context.mounted) {
        Navigator.pop(context); // Go back to roster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${cadet.name} has been struck off strength.')),
        );
      }
    }
  }

  void _showAwardMeritsDialog(BuildContext context, AuthProvider auth) {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Award Merits', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Reason (e.g. Sharp Uniform)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final amount = int.tryParse(amountController.text) ?? 0;
              if (amount > 0) {
                await _awardMerits(auth, amount, reasonController.text);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('AWARD'),
          ),
        ],
      ),
    );
  }

  Future<void> _awardMerits(AuthProvider auth, int amount, String reason) async {
    final corpsId = auth.userData?.corpsId;
    if (corpsId == null) return;

    // 1. Log the transaction
    await FirebaseFirestore.instance
        .collection('corps')
        .doc(corpsId)
        .collection('cadets')
        .doc(cadet.id)
        .collection('transactions')
        .add({
      'type': 'Award',
      'amount': amount,
      'description': reason,
      'issuer': auth.userData?.name ?? 'Staff',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. Update the cadet in the roster array
    // Note: We're currently storing cadets in an array in settings.cadets.
    // We need to find the cadet in the array and update them.
    final corpsRef = FirebaseFirestore.instance.collection('corps').doc(corpsId);
    final corpsDoc = await corpsRef.get();
    if (!corpsDoc.exists) return;

    final List<dynamic> cadets = List.from(corpsDoc.data()?['settings']?['cadets'] ?? []);
    final index = cadets.indexWhere((c) => c['uid'] == cadet.id);
    
    if (index != -1) {
      final currentMerits = cadets[index]['merits'] ?? 0;
      cadets[index]['merits'] = currentMerits + amount;
      
      await corpsRef.update({
        'settings.cadets': cadets,
      });
    }
  }

  int _calculateAge(DateTime? dob) {
    if (dob == null) return 0;
    return DateTime.now().year - dob.year;
  }
  List<Widget> _buildProgressList(UserData cadet) {
    final phase = cadet.phase ?? 'Phase 1';
    final records = List<String>.from(cadet.trainingRecords[phase] ?? []);
    final eos = Curriculum.getPhaseEOs(phase);
    
    // Group EOs by PO (first 3 chars of ID, e.g., M108 -> 108)
    Map<String, List<Map<String, dynamic>>> poGroups = {};
    for (var eo in eos) {
      final poId = eo['id'].substring(1, 4);
      poGroups.putIfAbsent(poId, () => []).add(eo);
    }

    return poGroups.entries.map((entry) {
      final poId = entry.key;
      final poEos = entry.value;
      final completedInPo = poEos.where((eo) => records.contains(eo['id'])).length;
      final totalInPo = poEos.length;
      final progress = totalInPo > 0 ? completedInPo / totalInPo : 0.0;
      
      // Find a title for the PO (usually matches the first EO's theme)
      String title = "PO $poId";
      if (poEos.isNotEmpty) {
        final fullTitle = poEos.first['title'];
        if (fullTitle.contains(' - ')) {
          title = "PO $poId (${fullTitle.split(' - ')[0]})";
        }
      }

      return _buildProgressRow(title, progress);
    }).toList();
  }

  Widget _buildSection(ThemeData theme, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: theme.colorScheme.primary, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white30, fontSize: 14)),
          Expanded(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String title, double progress) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 12, color: Colors.white30)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            minHeight: 6,
          ),
        ],
      ),
    );
  }
}

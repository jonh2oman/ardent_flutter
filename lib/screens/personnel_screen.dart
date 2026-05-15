import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';
import '../models/user_data.dart';
import 'cadet_detail_screen.dart';

class PersonnelScreen extends StatefulWidget {
  const PersonnelScreen({super.key});

  @override
  State<PersonnelScreen> createState() => _PersonnelScreenState();
}

class _PersonnelScreenState extends State<PersonnelScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    
    final List<dynamic> cadets = authProvider.corpsData?.settings['cadets'] ?? [];
    
    final filteredCadets = cadets.where((c) {
      final name = "${c['firstName']} ${c['lastName']}".toLowerCase();
      final rank = (c['rank'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || rank.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCadetDialog(context, authProvider),
        child: const Icon(LucideIcons.plus),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PERSONNEL MANAGEMENT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Unit Roster',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.0),
              ),
              const SizedBox(height: 24),
              TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search by name or rank...',
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  filled: true,
                  fillColor: theme.colorScheme.surface.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            itemCount: filteredCadets.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.white.withOpacity(0.05)),
            itemBuilder: (context, index) {
              final cadet = filteredCadets[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    cadet['rank']?.substring(0, 1) ?? 'C',
                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  "${cadet['firstName']} ${cadet['lastName']}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "${cadet['rank'] ?? 'Cadet'} • Phase ${cadet['phase'] ?? 'N/A'}",
                  style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                ),
                trailing: Icon(LucideIcons.chevronRight, size: 16, color: theme.iconTheme.color?.withOpacity(0.3)),
                onTap: () {
                  final userData = UserData(
                    id: cadet['uid'] ?? '',
                    email: cadet['email'] ?? '',
                    firstName: cadet['firstName'],
                    lastName: cadet['lastName'],
                    rank: cadet['rank'] ?? 'Cadet',
                    corpsId: authProvider.userData?.corpsId ?? '',
                    element: authProvider.corpsData?.element ?? 'Sea',
                    dob: cadet['dob'] != null ? DateTime.tryParse(cadet['dob'].toString()) : null,
                    phase: cadet['phase']?.toString(),
                  );
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => CadetDetailScreen(cadet: userData))
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddCadetDialog(BuildContext context, AuthProvider auth) {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    String selectedRank = 'Ordinary Cadet';
    int selectedPhase = 1;
    DateTime selectedDob = DateTime.now().subtract(const Duration(days: 365 * 12));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Cadet', style: TextStyle(fontWeight: FontWeight.w900)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                ),
                TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRank,
                  decoration: const InputDecoration(labelText: 'Rank'),
                  items: ['Ordinary Cadet', 'Able Cadet', 'Leading Cadet', 'Master Cadet', 'Petty Officer 2nd Class', 'Petty Officer 1st Class', 'Chief Petty Officer 2nd Class', 'Chief Petty Officer 1st Class']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedRank = v!),
                ),
                DropdownButtonFormField<int>(
                  value: selectedPhase,
                  decoration: const InputDecoration(labelText: 'Phase'),
                  items: [1, 2, 3, 4, 5]
                      .map((p) => DropdownMenuItem(value: p, child: Text('Phase $p')))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedPhase = v!),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Date of Birth'),
                  subtitle: Text(DateFormat('MMM d, yyyy').format(selectedDob)),
                  trailing: const Icon(LucideIcons.calendar),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDob,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setDialogState(() => selectedDob = date);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (firstNameController.text.isEmpty || lastNameController.text.isEmpty) return;
                
                final newCadet = {
                  'uid': 'temp_${DateTime.now().millisecondsSinceEpoch}',
                  'firstName': firstNameController.text,
                  'lastName': lastNameController.text,
                  'rank': selectedRank,
                  'phase': selectedPhase,
                  'dob': selectedDob.toIso8601String(),
                  'role': 'cadet',
                };

                final corpsRef = FirebaseFirestore.instance.collection('corps').doc(auth.corpsData!.id);
                await corpsRef.update({
                  'settings.cadets': FieldValue.arrayUnion([newCadet])
                });

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add Cadet'),
            ),
          ],
        ),
      ),
    );
  }
}

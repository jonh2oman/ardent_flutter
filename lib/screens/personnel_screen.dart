import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../models/user_data.dart';
import 'cadet_detail_screen.dart';
import 'staff_detail_screen.dart';

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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddCadetDialog(context, authProvider),
          child: const Icon(LucideIcons.plus),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
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
                  const SizedBox(height: 16),
                  const TabBar(
                    isScrollable: true,
                    tabs: [
                      Tab(text: 'CADETS'),
                      Tab(text: 'STAFF'),
                    ],
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
              child: TabBarView(
                children: [
                  _buildCadetList(context, theme, filteredCadets),
                  _buildStaffList(context, authProvider, theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCadetList(BuildContext context, ThemeData theme, List<dynamic> cadets) {
    return ListView.separated(
      padding: const EdgeInsets.all(32),
      itemCount: cadets.length,
      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.white.withOpacity(0.05)),
      itemBuilder: (context, index) {
        final cadet = cadets[index];
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
            final userData = UserData.fromMap(cadet as Map<String, dynamic>, cadet['uid'] ?? '');
            Navigator.push(context, MaterialPageRoute(builder: (_) => CadetDetailScreen(cadet: userData)));
          },
        );
      },
    );
  }

  Widget _buildStaffList(BuildContext context, AuthProvider auth, ThemeData theme) {
    final List<dynamic> staff = auth.corpsData?.settings['staff'] ?? [];
    final filteredStaff = staff.where((s) {
      final name = "${s['firstName']} ${s['lastName']}".toLowerCase();
      final rank = (s['rank'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || rank.contains(_searchQuery.toLowerCase());
    }).toList();

    return ListView.separated(
      padding: const EdgeInsets.all(32),
      itemCount: filteredStaff.length,
      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.white.withOpacity(0.05)),
      itemBuilder: (context, index) {
        final person = filteredStaff[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          leading: CircleAvatar(
            backgroundColor: Colors.blueAccent.withOpacity(0.1),
            child: const Icon(LucideIcons.shield, size: 16, color: Colors.blueAccent),
          ),
          title: Text(
            "${person['firstName']} ${person['lastName']}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            "${person['rank'] ?? 'Staff'} • ${person['position'] ?? 'Unit Staff'}",
            style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
          ),
          trailing: Icon(LucideIcons.chevronRight, size: 16, color: theme.iconTheme.color?.withOpacity(0.3)),
          onTap: () {
            final userData = UserData.fromMap(person as Map<String, dynamic>, person['uid'] ?? '');
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => StaffDetailScreen(staff: userData))
            );
          },
        );
      },
    );
  }
  }

  void _showAddCadetDialog(BuildContext context, AuthProvider auth) {
    int currentStep = 0;
    
    // Basic Info Controllers
    final firstName = TextEditingController();
    final lastName = TextEditingController();
    final cin = TextEditingController();
    String selectedRank = 'Ordinary Cadet';
    String selectedPhase = '1';
    DateTime selectedDob = DateTime.now().subtract(const Duration(days: 365 * 12));

    // Contact Controllers
    final phone = TextEditingController();
    final personalEmail = TextEditingController();
    final cadetEmail = TextEditingController();
    final street = TextEditingController();
    final city = TextEditingController();
    final province = TextEditingController(text: 'ON');
    final postalCode = TextEditingController();

    // Parent Info
    final parent1Name = TextEditingController();
    final parent1Rel = TextEditingController();
    final parent1Phone = TextEditingController();
    final parent2Name = TextEditingController();
    final parent2Rel = TextEditingController();
    final parent2Phone = TextEditingController();

    // Medical Info
    final healthNumber = TextEditingController();
    final insurance = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          List<Step> steps = [
            Step(
              title: const Text('Basic Info'),
              isActive: currentStep >= 0,
              content: Column(
                children: [
                  TextField(controller: firstName, decoration: const InputDecoration(labelText: 'First Name')),
                  TextField(controller: lastName, decoration: const InputDecoration(labelText: 'Last Name')),
                  TextField(controller: cin, decoration: const InputDecoration(labelText: 'CIN (Optional)')),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRank,
                    items: ['Ordinary Cadet', 'Able Cadet', 'Leading Cadet', 'Master Cadet', 'Petty Officer 2nd Class', 'Petty Officer 1st Class', 'Chief Petty Officer 2nd Class', 'Chief Petty Officer 1st Class']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (v) => setDialogState(() => selectedRank = v!),
                    decoration: const InputDecoration(labelText: 'Rank'),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Date of Birth'),
                    subtitle: Text(DateFormat('MMM d, yyyy').format(selectedDob)),
                    onTap: () async {
                      final d = await showDatePicker(context: context, initialDate: selectedDob, firstDate: DateTime(1900), lastDate: DateTime.now());
                      if (d != null) setDialogState(() => selectedDob = d);
                    },
                  ),
                ],
              ),
            ),
            Step(
              title: const Text('Contact'),
              isActive: currentStep >= 1,
              content: Column(
                children: [
                  TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
                  TextField(controller: personalEmail, decoration: const InputDecoration(labelText: 'Personal Email')),
                  TextField(controller: street, decoration: const InputDecoration(labelText: 'Street Address')),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: city, decoration: const InputDecoration(labelText: 'City'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: postalCode, decoration: const InputDecoration(labelText: 'Postal Code'))),
                    ],
                  ),
                ],
              ),
            ),
            Step(
              title: const Text('Guardians'),
              isActive: currentStep >= 2,
              content: Column(
                children: [
                  Text('Guardian 1', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                  TextField(controller: parent1Name, decoration: const InputDecoration(labelText: 'Full Name')),
                  TextField(controller: parent1Rel, decoration: const InputDecoration(labelText: 'Relationship')),
                  TextField(controller: parent1Phone, decoration: const InputDecoration(labelText: 'Phone')),
                  const SizedBox(height: 16),
                  Text('Guardian 2 (Optional)', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                  TextField(controller: parent2Name, decoration: const InputDecoration(labelText: 'Full Name')),
                  TextField(controller: parent2Phone, decoration: const InputDecoration(labelText: 'Phone')),
                ],
              ),
            ),
            Step(
              title: const Text('Medical'),
              isActive: currentStep >= 3,
              content: Column(
                children: [
                  TextField(controller: healthNumber, decoration: const InputDecoration(labelText: 'Provincial Health #')),
                  TextField(controller: insurance, decoration: const InputDecoration(labelText: 'Private Insurance Provider')),
                ],
              ),
            ),
          ];

          return AlertDialog(
            title: const Text('Add Full Cadet Profile', style: TextStyle(fontWeight: FontWeight.w900)),
            content: SizedBox(
              width: 500,
              child: Stepper(
                type: StepperType.vertical,
                currentStep: currentStep,
                onStepContinue: () {
                  if (currentStep < steps.length - 1) {
                    setDialogState(() => currentStep++);
                  } else {
                    _saveFullCadet(context, auth, {
                      'firstName': firstName.text,
                      'lastName': lastName.text,
                      'cin': cin.text,
                      'rank': selectedRank,
                      'phase': selectedPhase,
                      'dob': selectedDob.toIso8601String(),
                      'phone': phone.text,
                      'personalEmail': personalEmail.text,
                      'address': {
                        'street': street.text,
                        'city': city.text,
                        'province': province.text,
                        'postalCode': postalCode.text,
                      },
                      'parents': [
                        {'name': parent1Name.text, 'relationship': parent1Rel.text, 'phone': parent1Phone.text},
                        if (parent2Name.text.isNotEmpty) {'name': parent2Name.text, 'phone': parent2Phone.text},
                      ],
                      'provincialHealthNumber': healthNumber.text,
                      'privateInsuranceProvider': insurance.text,
                    });
                  }
                },
                onStepCancel: () {
                  if (currentStep > 0) setDialogState(() => currentStep--);
                },
                steps: steps,
              ),
            ),
          );
        },
      ),
    );
  }

  void _saveFullCadet(BuildContext context, AuthProvider auth, Map<String, dynamic> data) async {
    final newCadet = {
      ...data,
      'uid': 'cadet_${DateTime.now().millisecondsSinceEpoch}',
      'role': 'cadet',
    };

    final corpsRef = FirebaseFirestore.instance.collection('corps').doc(auth.corpsData!.id);
    await corpsRef.update({
      'settings.cadets': FieldValue.arrayUnion([newCadet])
    });

    if (context.mounted) Navigator.pop(context);
  }
}

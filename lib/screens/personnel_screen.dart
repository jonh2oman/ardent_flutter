import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import '../providers/auth_provider.dart';
import '../models/user_data.dart';
import 'cadet_detail_screen.dart';
import 'staff_detail_screen.dart';
import '../data/curriculum.dart';

class PersonnelScreen extends StatefulWidget {
  const PersonnelScreen({super.key});

  @override
  State<PersonnelScreen> createState() => _PersonnelScreenState();
}

class _PersonnelScreenState extends State<PersonnelScreen> {
  String _searchQuery = "";
  bool _isSelectionMode = false;
  final Set<String> _selectedCadetIds = {};

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    
    final List<dynamic> cadets = authProvider.corpsData?.settings?['cadets'] ?? [];
    
    final filteredCadets = cadets.where((c) {
      if (c['isArchived'] == true) return false;
      final firstName = (c['firstName'] ?? '').toString();
      final lastName = (c['lastName'] ?? '').toString();
      final name = "$firstName $lastName".toLowerCase();
      final rank = (c['rank'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || rank.contains(_searchQuery.toLowerCase());
    }).toList();

    return DefaultTabController(
      length: 3,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isSelectionMode ? '${_selectedCadetIds.length} SELECTED' : 'PERSONNEL MANAGEMENT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (!_isSelectionMode)
                        TextButton.icon(
                          onPressed: () => setState(() => _isSelectionMode = true),
                          icon: const Icon(LucideIcons.checkSquare, size: 14),
                          label: const Text('SELECT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      else
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                if (_selectedCadetIds.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select cadets first')));
                                  return;
                                }
                                _showBulkTrainingUpdate(context, authProvider);
                              },
                              child: const Text('BULK COMPLETE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                            ),
                            TextButton(
                              onPressed: () => setState(() {
                                _isSelectionMode = false;
                                _selectedCadetIds.clear();
                              }),
                              child: const Text('CANCEL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const TabBar(
                    isScrollable: true,
                    tabs: [
                      Tab(text: 'CADETS'),
                      Tab(text: 'STAFF'),
                      Tab(text: 'MAINTENANCE'),
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
                  _buildCadetList(context, authProvider, theme, filteredCadets),
                  _buildStaffList(context, authProvider, theme),
                  _buildMaintenanceTab(context, authProvider, theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCadetList(BuildContext context, AuthProvider auth, ThemeData theme, List<dynamic> cadets) {
    return ListView.separated(
      padding: const EdgeInsets.all(32),
      itemCount: cadets.length,
      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.white.withOpacity(0.05)),
      itemBuilder: (context, index) {
        final cadet = cadets[index];
        final userData = UserData.fromMap(cadet as Map<String, dynamic>, (cadet['uid'] ?? cadet['id'] ?? '').toString());

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          leading: _isSelectionMode 
              ? Checkbox(
                  value: _selectedCadetIds.contains(userData.id),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedCadetIds.add(userData.id);
                      } else {
                        _selectedCadetIds.remove(userData.id);
                      }
                    });
                  },
                )
              : CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    userData.rank?.substring(0, 1) ?? 'C',
                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
          title: Text(
            userData.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: userData.firstName == null || userData.firstName!.toLowerCase() == 'null' ? Colors.redAccent : null,
            ),
          ),
          subtitle: Text(
            "${cadet['rank'] ?? 'Cadet'} • Phase ${cadet['phase'] ?? 'N/A'}",
            style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
          ),
          trailing: _isSelectionMode ? null : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(LucideIcons.userMinus, size: 16, color: Colors.redAccent),
                onPressed: () => _removeCadet(context, auth, cadet),
                tooltip: 'Strike Off Strength',
              ),
              Icon(LucideIcons.chevronRight, size: 16, color: theme.iconTheme.color?.withOpacity(0.3)),
            ],
          ),
          onTap: () {
            if (_isSelectionMode) {
              setState(() {
                if (_selectedCadetIds.contains(userData.id)) {
                  _selectedCadetIds.remove(userData.id);
                } else {
                  _selectedCadetIds.add(userData.id);
                }
              });
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => CadetDetailScreen(cadet: userData)));
            }
          },
        );
      },
    );
  }

  Widget _buildStaffList(BuildContext context, AuthProvider auth, ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('corpsId', isEqualTo: auth.corpsData?.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final staffDocs = snapshot.data?.docs ?? [];
        final filteredStaff = staffDocs.where((doc) {
          final s = doc.data() as Map<String, dynamic>;
          if (s['isArchived'] == true) return false;
          
          final name = "${s['firstName']} ${s['lastName']}".toLowerCase();
          final rank = (s['rank'] ?? '').toString().toLowerCase();
          final pos = (s['position'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery.toLowerCase()) || 
                 rank.contains(_searchQuery.toLowerCase()) ||
                 pos.contains(_searchQuery.toLowerCase());
        }).toList();

        if (filteredStaff.isEmpty) {
          return const Center(child: Text('No staff found matching search.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(32),
          itemCount: filteredStaff.length,
          separatorBuilder: (context, index) => Divider(height: 1, color: Colors.white.withOpacity(0.05)),
          itemBuilder: (context, index) {
            final doc = filteredStaff[index];
            final person = doc.data() as Map<String, dynamic>;
            final uid = doc.id;
            final userData = UserData.fromMap(person, uid);

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              leading: CircleAvatar(
                backgroundColor: userData.isValid ? Colors.blueAccent.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
                child: Icon(
                  userData.isValid ? LucideIcons.shield : LucideIcons.alertTriangle, 
                  size: 16, 
                  color: userData.isValid ? Colors.blueAccent : Colors.redAccent
                ),
              ),
              title: Text(
                userData.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: userData.isValid ? null : Colors.redAccent,
                ),
              ),
              subtitle: Text(
                userData.isValid 
                  ? "${userData.rank ?? 'Staff'} • ${userData.position ?? 'Unit Staff'}"
                  : "MALFORMED RECORD - ACTION REQUIRED",
                style: TextStyle(
                  fontSize: 12, 
                  color: userData.isValid 
                    ? theme.textTheme.bodyMedium?.color?.withOpacity(0.6)
                    : Colors.redAccent.withOpacity(0.8)
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.userMinus, size: 16, color: Colors.redAccent),
                    onPressed: () => _archiveStaff(context, userData),
                    tooltip: 'Strike Off Strength',
                  ),
                  Icon(LucideIcons.chevronRight, size: 16, color: theme.iconTheme.color?.withOpacity(0.3)),
                ],
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => StaffDetailScreen(staff: userData)));
              },
            );
          },
        );
      },
    );
  }

  Future<void> _archiveStaff(BuildContext context, UserData staff) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('STRIKE OFF STRENGTH'),
        content: Text('Are you sure you want to strike off ${staff.name}? They will be moved to the archive and removed from the active roster.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('STRIKE OFF'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(staff.id)
            .update({'isArchived': true});
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${staff.name} struck off strength')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error archiving staff: $e')),
          );
        }
      }
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
    DateTime selectedEnrolment = DateTime.now();

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
                    value: ['Ordinary Cadet', 'Able Cadet', 'Leading Cadet', 'Master Cadet', 'Petty Officer 2nd Class', 'Petty Officer 1st Class', 'Chief Petty Officer 2nd Class', 'Chief Petty Officer 1st Class', 'OC', 'AC', 'LC', 'MC', 'PO2', 'PO1', 'CPO2', 'CPO1'].contains(selectedRank) ? selectedRank : null,
                    items: ['Ordinary Cadet', 'Able Cadet', 'Leading Cadet', 'Master Cadet', 'Petty Officer 2nd Class', 'Petty Officer 1st Class', 'Chief Petty Officer 2nd Class', 'Chief Petty Officer 1st Class', 'OC', 'AC', 'LC', 'MC', 'PO2', 'PO1', 'CPO2', 'CPO1']
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
                  const SizedBox(height: 8),
                  ListTile(
                    title: const Text('Enrolment Date'),
                    subtitle: Text(DateFormat('MMM d, yyyy').format(selectedEnrolment)),
                    onTap: () async {
                      final d = await showDatePicker(context: context, initialDate: selectedEnrolment, firstDate: DateTime(1900), lastDate: DateTime.now());
                      if (d != null) setDialogState(() => selectedEnrolment = d);
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
                      'enrolmentDate': selectedEnrolment.toIso8601String(),
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
    // PREVENT BLANK PROFILES
    if ((data['firstName'] ?? '').toString().trim().isEmpty || 
        (data['lastName'] ?? '').toString().trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: First and Last Name are required.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final newCadet = {
      ...data,
      'uid': 'cadet_${DateTime.now().millisecondsSinceEpoch}',
      'role': 'cadet',
      'merits': 0,
      'cashBalance': 0.0,
      'isArchived': false,
    };

    final corpsRef = FirebaseFirestore.instance.collection('corps').doc(auth.corpsData!.id);
    await corpsRef.update({
      'settings.cadets': FieldValue.arrayUnion([newCadet])
    });

    if (context.mounted) Navigator.pop(context);
  }

   Future<void> _removeCadet(BuildContext context, AuthProvider auth, Map<String, dynamic> cadet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('STRIKE OFF STRENGTH?'),
        content: Text('Are you sure you want to strike off ${cadet['firstName'] ?? "this cadet"}? They will be moved to the archive.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('STRIKE OFF'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final corpsRef = FirebaseFirestore.instance.collection('corps').doc(auth.corpsData!.id);
      
      // Update the cadet record in the array
      final updatedCadet = Map<String, dynamic>.from(cadet);
      updatedCadet['isArchived'] = true;
      
      await corpsRef.update({
        'settings.cadets': FieldValue.arrayRemove([cadet])
      });
      await corpsRef.update({
        'settings.cadets': FieldValue.arrayUnion([updatedCadet])
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cadet struck off strength and archived')),
        );
      }
    }
  }

  Widget _buildMaintenanceTab(BuildContext context, AuthProvider auth, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        Text(
          'DATA INTEGRITY & MAINTENANCE',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        _buildMaintenanceCard(
          context,
          'Validate Roster',
          'Scan all records for missing critical data or formatting errors.',
          LucideIcons.shieldCheck,
          () => _validateRoster(context, auth),
        ),
        const SizedBox(height: 16),
        _buildMaintenanceCard(
          context,
          'Bulk Archive',
          'Move all graduated or inactive personnel to the archives.',
          LucideIcons.archive,
          () => _bulkArchive(context, auth),
        ),
        const SizedBox(height: 16),
        _buildMaintenanceCard(
          context,
          'Export Roster',
          'Download the current roster as a CSV file for external reporting.',
          LucideIcons.download,
          () => _exportRoster(context, auth),
        ),
      ],
    );
  }

  Widget _buildMaintenanceCard(BuildContext context, String title, String description, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: Colors.white.withOpacity(0.2)),
          ],
        ),
      ),
    );
  }
  void _showBulkTrainingUpdate(BuildContext context, AuthProvider auth) {
    String selectedPhase = 'Phase 1';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('BULK COMPLETE PHASE'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mark selected ${_selectedCadetIds.length} cadets as having completed all mandatory EOs for:'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedPhase,
              items: ['Phase 1', 'Phase 2', 'Phase 3', 'Phase 4', 'Phase 5'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) => setState(() => selectedPhase = v!),
              decoration: const InputDecoration(labelText: 'Target Phase'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final eos = Curriculum.getPhaseEOs(selectedPhase);
              final mandatoryIds = eos.where((e) => e['type'] == 'M').map((e) => e['id'].toString()).toList();
              
              final corpsRef = FirebaseFirestore.instance.collection('corps').doc(auth.userData!.corpsId);
              final snapshot = await corpsRef.get();
              final cadets = List<Map<String, dynamic>>.from(snapshot.data()?['settings']?['cadets'] ?? []);

              for (var cadetId in _selectedCadetIds) {
                final index = cadets.indexWhere((c) => (c['uid'] ?? c['id'] ?? '').toString() == cadetId);
                if (index != -1) {
                  final records = Map<String, dynamic>.from(cadets[index]['trainingRecords'] ?? {});
                  final current = List<String>.from(records[selectedPhase] ?? []);
                  for (var id in mandatoryIds) {
                    if (!current.contains(id)) current.add(id);
                  }
                  records[selectedPhase] = current;
                  cadets[index]['trainingRecords'] = records;
                }
              }

              await corpsRef.update({'settings.cadets': cadets});

              if (context.mounted) {
                Navigator.pop(context);
                setState(() {
                  _isSelectionMode = false;
                  _selectedCadetIds.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bulk update completed successfully.')),
                );
              }
            },
            child: const Text('COMPLETE'),
          ),
        ],
      ),
    );
  }

  void _validateRoster(BuildContext context, AuthProvider auth) {
    final cadets = List<Map<String, dynamic>>.from(auth.corpsData?.settings?['cadets'] ?? []);
    final issues = <String, List<String>>{};

    for (var c in cadets) {
      if (c['isArchived'] == true) continue;
      final name = "${c['firstName'] ?? ''} ${c['lastName'] ?? ''}".trim();
      final cIssues = <String>[];
      
      if ((c['firstName'] ?? '').toString().isEmpty || (c['firstName'] ?? '').toString().toLowerCase() == 'null') cIssues.add('Missing First Name');
      if ((c['lastName'] ?? '').toString().isEmpty || (c['lastName'] ?? '').toString().toLowerCase() == 'null') cIssues.add('Missing Last Name');
      if ((c['cin'] ?? '').toString().isEmpty || (c['cin'] ?? '').toString().toLowerCase() == 'null') cIssues.add('Missing CIN');
      if ((c['dob'] ?? '').toString().isEmpty) cIssues.add('Missing Date of Birth');
      
      if (cIssues.isNotEmpty) {
        issues[name.isEmpty ? 'Unknown Cadet' : name] = cIssues;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Roster Validation Results'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: issues.isEmpty 
            ? const Center(child: Text('✅ No critical issues found!'))
            : ListView(
                children: issues.entries.map((e) => ListTile(
                  leading: const Icon(LucideIcons.alertTriangle, color: Colors.orangeAccent),
                  title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(e.value.join(', ')),
                )).toList(),
              ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
        ],
      ),
    );
  }

  void _bulkArchive(BuildContext context, AuthProvider auth) {
    final cadets = List<Map<String, dynamic>>.from(auth.corpsData?.settings?['cadets'] ?? []);
    final activeCadets = cadets.where((c) => c['isArchived'] != true).toList();
    
    final selectedToArchive = <String>{};
    for (var c in activeCadets) {
      if (c['dob'] != null && c['dob'].toString().isNotEmpty) {
        try {
          final dob = DateTime.parse(c['dob'].toString());
          final age = DateTime.now().difference(dob).inDays / 365.25;
          if (age >= 19.0) {
            selectedToArchive.add((c['uid'] ?? c['id'] ?? '').toString());
          }
        } catch (_) {}
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Bulk Archive Personnel'),
          content: SizedBox(
            width: 400,
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select personnel to move to the archives. Cadets over 19 are pre-selected.', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: activeCadets.length,
                    itemBuilder: (context, index) {
                      final c = activeCadets[index];
                      final id = (c['uid'] ?? c['id'] ?? '').toString();
                      final name = "${c['firstName'] ?? ''} ${c['lastName'] ?? ''}";
                      return CheckboxListTile(
                        value: selectedToArchive.contains(id),
                        title: Text(name),
                        subtitle: Text(c['rank'] ?? 'Cadet'),
                        onChanged: (val) {
                          setDialogState(() {
                            if (val == true) selectedToArchive.add(id);
                            else selectedToArchive.remove(id);
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                if (selectedToArchive.isEmpty) {
                  Navigator.pop(context);
                  return;
                }
                for (var i = 0; i < cadets.length; i++) {
                  final id = (cadets[i]['uid'] ?? cadets[i]['id'] ?? '').toString();
                  if (selectedToArchive.contains(id)) {
                    cadets[i]['isArchived'] = true;
                  }
                }
                await FirebaseFirestore.instance.collection('corps').doc(auth.corpsData!.id).update({'settings.cadets': cadets});
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Archived ${selectedToArchive.length} personnel.')));
                }
              },
              child: const Text('ARCHIVE SELECTED'),
            ),
          ],
        ),
      ),
    );
  }

  void _exportRoster(BuildContext context, AuthProvider auth) async {
    try {
      final cadets = List<Map<String, dynamic>>.from(auth.corpsData?.settings?['cadets'] ?? []);
      final activeCadets = cadets.where((c) => c['isArchived'] != true).toList();
      
      final sb = StringBuffer();
      sb.writeln('First Name,Last Name,Rank,Phase,CIN,Phone,Email');
      
      for (var c in activeCadets) {
        final first = (c['firstName'] ?? '').toString().replaceAll(',', ' ');
        final last = (c['lastName'] ?? '').toString().replaceAll(',', ' ');
        final rank = (c['rank'] ?? '').toString().replaceAll(',', ' ');
        final phase = (c['phase'] ?? '').toString().replaceAll(',', ' ');
        final cin = (c['cin'] ?? '').toString().replaceAll(',', ' ');
        final phone = (c['phone'] ?? '').toString().replaceAll(',', ' ');
        final email = (c['personalEmail'] ?? '').toString().replaceAll(',', ' ');
        
        sb.writeln('$first,$last,$rank,$phase,$cin,$phone,$email');
      }

      final downloadsDir = "${Platform.environment['HOME']}/Downloads";
      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final file = File('$downloadsDir/Roster_Export_$timestamp.csv');
      
      await file.writeAsString(sb.toString());
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Roster exported to Downloads/Roster_Export_$timestamp.csv')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export roster: $e')),
        );
      }
    }
  }
}

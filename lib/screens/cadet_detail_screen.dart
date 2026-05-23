import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_data.dart';
import '../widgets/stat_card.dart';
import '../providers/auth_provider.dart';
import '../data/curriculum.dart';

class CadetDetailScreen extends StatefulWidget {
  final UserData cadet;

  const CadetDetailScreen({super.key, required this.cadet});

  @override
  State<CadetDetailScreen> createState() => _CadetDetailScreenState();
}

class _CadetDetailScreenState extends State<CadetDetailScreen> {
  late UserData cadet;

  @override
  void initState() {
    super.initState();
    cadet = widget.cadet;
  }

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
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.edit),
            onPressed: () => _showEditCadetDialog(context, auth),
            tooltip: 'Edit Profile',
          ),
        ],
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
                const SizedBox(width: 12),
                Expanded(child: StatCard(title: 'Attend', value: '$attendancePercent%', icon: LucideIcons.checkCircle, iconColor: Colors.greenAccent)),
                const SizedBox(width: 12),
                Expanded(child: StatCard(title: 'Merits', value: '${cadet.merits}', icon: LucideIcons.coins, iconColor: Colors.amberAccent)),
                const SizedBox(width: 12),
                Expanded(child: StatCard(title: 'Cash', value: '\$${cadet.cashBalance.toStringAsFixed(2)}', icon: LucideIcons.wallet, iconColor: Colors.greenAccent)),
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

            // Tags
            _buildSection(theme, 'Tags & Teams', [
              if (cadet.tags.isEmpty)
                const Text('No tags assigned', style: TextStyle(color: Colors.white30, fontSize: 12))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: cadet.tags.map((t) => Chip(
                    label: Text(t, style: const TextStyle(fontSize: 10)),
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                    side: BorderSide.none,
                  )).toList(),
                ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showEditTagsDialog(context, auth),
                  icon: const Icon(LucideIcons.tag, size: 14),
                  label: const Text('EDIT TAGS'),
                ),
              ),
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

  void _showEditCadetDialog(BuildContext context, AuthProvider auth) {
    int currentStep = 0;
    
    // Basic Info Controllers
    final firstName = TextEditingController(text: cadet.firstName);
    final lastName = TextEditingController(text: cadet.lastName);
    final cin = TextEditingController(text: cadet.cin);
    String selectedRank = cadet.rank ?? 'Ordinary Cadet';
    String selectedPhase = cadet.phase ?? '1';
    DateTime selectedDob = cadet.dob ?? DateTime.now().subtract(const Duration(days: 365 * 12));
    DateTime selectedEnrolment = cadet.enrolmentDate ?? DateTime.now();

    // Contact Controllers
    final phone = TextEditingController(text: cadet.phone);
    final personalEmail = TextEditingController(text: cadet.personalEmail);
    final street = TextEditingController(text: cadet.address?['street']);
    final city = TextEditingController(text: cadet.address?['city']);
    final province = TextEditingController(text: cadet.address?['province'] ?? 'ON');
    final postalCode = TextEditingController(text: cadet.address?['postalCode']);

    // Parent Info
    final parent1Name = TextEditingController(text: (cadet.parents != null && cadet.parents!.isNotEmpty) ? cadet.parents![0]['name'] : '');
    final parent1Rel = TextEditingController(text: (cadet.parents != null && cadet.parents!.isNotEmpty) ? cadet.parents![0]['relationship'] : '');
    final parent1Phone = TextEditingController(text: (cadet.parents != null && cadet.parents!.isNotEmpty) ? cadet.parents![0]['phone'] : '');
    final parent2Name = TextEditingController(text: (cadet.parents != null && cadet.parents!.length > 1) ? cadet.parents![1]['name'] : '');
    final parent2Rel = TextEditingController(text: (cadet.parents != null && cadet.parents!.length > 1) ? cadet.parents![1]['relationship'] : '');
    final parent2Phone = TextEditingController(text: (cadet.parents != null && cadet.parents!.length > 1) ? cadet.parents![1]['phone'] : '');

    // Medical Info
    final healthNumber = TextEditingController(text: cadet.provincialHealthNumber);
    final insurance = TextEditingController(text: cadet.privateInsuranceProvider);

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
            title: const Text('Edit Cadet Profile', style: TextStyle(fontWeight: FontWeight.w900)),
            content: SizedBox(
              width: 500,
              child: Stepper(
                type: StepperType.vertical,
                currentStep: currentStep,
                onStepContinue: () {
                  if (currentStep < steps.length - 1) {
                    setDialogState(() => currentStep++);
                  } else {
                    _saveEditedCadet(context, auth, {
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

  void _saveEditedCadet(BuildContext context, AuthProvider auth, Map<String, dynamic> data) async {
    if ((data['firstName'] ?? '').toString().trim().isEmpty || 
        (data['lastName'] ?? '').toString().trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: First and Last Name are required.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final corpsId = auth.userData?.corpsId;
    if (corpsId == null) return;

    final corpsRef = FirebaseFirestore.instance.collection('corps').doc(corpsId);
    final corpsDoc = await corpsRef.get();
    if (!corpsDoc.exists) return;

    final List<dynamic> cadets = List.from(corpsDoc.data()?['settings']?['cadets'] ?? []);
    final index = cadets.indexWhere((c) => (c['uid'] ?? c['id'] ?? '').toString() == cadet.id);
    
    if (index != -1) {
      final updatedCadetMap = Map<String, dynamic>.from(cadets[index]);
      
      updatedCadetMap['firstName'] = data['firstName'];
      updatedCadetMap['lastName'] = data['lastName'];
      updatedCadetMap['cin'] = data['cin'];
      updatedCadetMap['rank'] = data['rank'];
      updatedCadetMap['phase'] = data['phase'];
      updatedCadetMap['dob'] = data['dob'];
      updatedCadetMap['enrolmentDate'] = data['enrolmentDate'];
      updatedCadetMap['phone'] = data['phone'];
      updatedCadetMap['personalEmail'] = data['personalEmail'];
      updatedCadetMap['address'] = data['address'];
      updatedCadetMap['parents'] = data['parents'];
      updatedCadetMap['provincialHealthNumber'] = data['provincialHealthNumber'];
      updatedCadetMap['privateInsuranceProvider'] = data['privateInsuranceProvider'];

      cadets[index] = updatedCadetMap;
      
      await corpsRef.update({
        'settings.cadets': cadets,
      });

      if (context.mounted) {
        setState(() {
          cadet = UserData(
            id: cadet.id,
            email: cadet.email,
            corpsId: cadet.corpsId,
            firstName: data['firstName'],
            lastName: data['lastName'],
            rank: data['rank'],
            position: cadet.position,
            phase: data['phase'],
            cin: data['cin'],
            merits: cadet.merits,
            cashBalance: cadet.cashBalance,
            isArchived: cadet.isArchived,
            dob: DateTime.parse(data['dob']),
            phone: data['phone'],
            personalEmail: data['personalEmail'],
            cadetEmail: cadet.cadetEmail,
            address: data['address'],
            parents: List<Map<String, dynamic>>.from(data['parents']),
            provincialHealthNumber: data['provincialHealthNumber'],
            privateInsuranceProvider: data['privateInsuranceProvider'],
            uniformSizes: cadet.uniformSizes,
            issuedKit: cadet.issuedKit,
            trainingRecords: cadet.trainingRecords,
            enrolmentDate: DateTime.parse(data['enrolmentDate']),
            tags: cadet.tags,
          );
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
      }
    }
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

  void _showEditTagsDialog(BuildContext context, AuthProvider auth) {
    final tagsCtrl = TextEditingController(text: cadet.tags.join(', '));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Tags'),
        content: TextField(
          controller: tagsCtrl,
          decoration: const InputDecoration(labelText: 'Tags (comma separated)', hintText: 'e.g. Band, Guard, Marksmanship'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final newTags = tagsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
              final corpsRef = FirebaseFirestore.instance.collection('corps').doc(auth.userData!.corpsId);
              final corpsDoc = await corpsRef.get();
              if (corpsDoc.exists) {
                final List<dynamic> cadets = List.from(corpsDoc.data()?['settings']?['cadets'] ?? []);
                final index = cadets.indexWhere((c) => (c['uid'] ?? c['id'] ?? '').toString() == cadet.id);
                if (index != -1) {
                  cadets[index]['tags'] = newTags;
                  await corpsRef.update({'settings.cadets': cadets});
                }
              }
              if (context.mounted) {
                setState(() {
                  cadet = UserData(
                    id: cadet.id,
                    email: cadet.email,
                    corpsId: cadet.corpsId,
                    firstName: cadet.firstName,
                    lastName: cadet.lastName,
                    rank: cadet.rank,
                    position: cadet.position,
                    phase: cadet.phase,
                    cin: cadet.cin,
                    merits: cadet.merits,
                    cashBalance: cadet.cashBalance,
                    isArchived: cadet.isArchived,
                    dob: cadet.dob,
                    phone: cadet.phone,
                    personalEmail: cadet.personalEmail,
                    cadetEmail: cadet.cadetEmail,
                    address: cadet.address,
                    parents: cadet.parents,
                    uniformSizes: cadet.uniformSizes,
                    issuedKit: cadet.issuedKit,
                    trainingRecords: cadet.trainingRecords,
                    enrolmentDate: cadet.enrolmentDate,
                    tags: newTags,
                  );
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tags updated successfully!')));
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
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

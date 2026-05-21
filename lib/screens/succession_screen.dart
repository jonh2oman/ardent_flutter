import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../models/user_data.dart';
import '../models/succession_plan.dart';

class SuccessionScreen extends StatefulWidget {
  const SuccessionScreen({super.key});

  @override
  State<SuccessionScreen> createState() => _SuccessionScreenState();
}

class _SuccessionScreenState extends State<SuccessionScreen> {
  final List<Map<String, String>> _defaultPositions = [
    {'id': 'co', 'name': 'Commanding Officer'},
    {'id': 'xo', 'name': 'Executive Officer'},
    {'id': 'trgo', 'name': 'Training Officer'},
    {'id': 'admino', 'name': 'Administration Officer'},
  ];

  Map<String, UserData> _staffMap = {};
  bool _isLoadingStaff = true;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final corpsId = auth.userData?.corpsId;
    if (corpsId == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('corpsId', isEqualTo: corpsId)
        .where('isArchived', isEqualTo: false)
        .get();

    final map = <String, UserData>{};
    for (var doc in snapshot.docs) {
      final user = UserData.fromMap(doc.data(), doc.id);
      map[user.id] = user;
    }

    if (mounted) {
      setState(() {
        _staffMap = map;
        _isLoadingStaff = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final corpsId = auth.userData?.corpsId;

    if (corpsId == null || _isLoadingStaff) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.gitMerge, color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 16),
                const Text(
                  'SUCCESSION PLANNING',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.0),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Manage the leadership pipeline for your Command Team.',
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 16),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('corps')
                    .doc(corpsId)
                    .collection('succession_plans')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final planDocs = snapshot.data!.docs;
                  final Map<String, SuccessionPlan> plans = {};
                  for (var doc in planDocs) {
                    plans[doc.id] = SuccessionPlan.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                  }

                  return ListView.builder(
                    itemCount: _defaultPositions.length,
                    itemBuilder: (context, index) {
                      final pos = _defaultPositions[index];
                      final posId = pos['id']!;
                      final posName = pos['name']!;
                      
                      final plan = plans[posId] ?? SuccessionPlan(
                        id: posId,
                        positionId: posId,
                        positionName: posName,
                      );

                      return _buildPositionCard(context, theme, plan, corpsId);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionCard(BuildContext context, ThemeData theme, SuccessionPlan plan, String corpsId) {
    final incumbent = plan.currentIncumbentId != null ? _staffMap[plan.currentIncumbentId] : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.positionName.toUpperCase(),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 4),
                    if (incumbent != null) ...[
                      Row(
                        children: [
                          const Icon(LucideIcons.userCheck, size: 14, color: Colors.greenAccent),
                          const SizedBox(width: 8),
                          Text(
                            'Current: ${incumbent.name}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          if (plan.expectedRotationDate != null) ...[
                            const SizedBox(width: 16),
                            const Icon(LucideIcons.calendarClock, size: 14, color: Colors.amberAccent),
                            const SizedBox(width: 8),
                            Text(
                              'Rotates: ${DateFormat('MMM yyyy').format(plan.expectedRotationDate!)}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ],
                      ),
                    ] else ...[
                      const Text('No incumbent assigned', style: TextStyle(color: Colors.white30, fontStyle: FontStyle.italic)),
                    ]
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _showEditIncumbentDialog(context, plan, corpsId),
                  icon: const Icon(LucideIcons.edit3, size: 14),
                  label: const Text('EDIT'),
                ),
              ],
            ),
          ),
          
          // Pipeline
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PIPELINE CANDIDATES',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white30, letterSpacing: 1.2),
                    ),
                    TextButton.icon(
                      onPressed: () => _showEditCandidateDialog(context, plan, corpsId, null),
                      icon: const Icon(LucideIcons.plus, size: 14),
                      label: const Text('ADD CANDIDATE'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPipelineLane(context, plan, corpsId, 'Ready Now', 'ready_now', Colors.green),
                    const SizedBox(width: 16),
                    _buildPipelineLane(context, plan, corpsId, 'Ready 1-2 Years', '1_2_years', Colors.blue),
                    const SizedBox(width: 16),
                    _buildPipelineLane(context, plan, corpsId, 'Ready 3+ Years', '3_plus_years', Colors.purple),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineLane(BuildContext context, SuccessionPlan plan, String corpsId, String title, String readinessKey, MaterialColor color) {
    final candidates = plan.candidates.where((c) => c.readiness == readinessKey).toList();

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.circleDot, size: 12, color: color[300]),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color[200], letterSpacing: 1.0),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${candidates.length}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color[200]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (candidates.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('No candidates', style: TextStyle(color: Colors.white24, fontSize: 12, fontStyle: FontStyle.italic)),
                ),
              )
            else
              ...candidates.map((c) {
                final staff = _staffMap[c.staffId];
                return InkWell(
                  onTap: () => _showEditCandidateDialog(context, plan, corpsId, c),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          staff?.name ?? 'Unknown Staff',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        if (c.notes.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            c.notes,
                            style: const TextStyle(fontSize: 11, color: Colors.white60),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _showEditIncumbentDialog(BuildContext context, SuccessionPlan plan, String corpsId) {
    String? selectedStaffId = plan.currentIncumbentId;
    DateTime? rotationDate = plan.expectedRotationDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Edit Incumbent - ${plan.positionName}'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Current Incumbent',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    value: _staffMap.containsKey(selectedStaffId) ? selectedStaffId : null,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None / Vacant')),
                      ..._staffMap.values.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                    ],
                    onChanged: (val) => setState(() => selectedStaffId = val),
                  ),
                  const SizedBox(height: 24),
                  const Text('Expected Rotation Date', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final dt = await showDatePicker(
                        context: context,
                        initialDate: rotationDate ?? DateTime.now().add(const Duration(days: 365)),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (dt != null) {
                        setState(() => rotationDate = dt);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(rotationDate != null ? DateFormat('MMMM yyyy').format(rotationDate!) : 'Select Date...'),
                          const Icon(LucideIcons.calendar, size: 16, color: Colors.white54),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
              ElevatedButton(
                onPressed: () async {
                  final ref = FirebaseFirestore.instance.collection('corps').doc(corpsId).collection('succession_plans').doc(plan.id);
                  
                  final updatedPlan = SuccessionPlan(
                    id: plan.id,
                    positionId: plan.positionId,
                    positionName: plan.positionName,
                    currentIncumbentId: selectedStaffId,
                    expectedRotationDate: rotationDate,
                    candidates: plan.candidates,
                  );

                  await ref.set(updatedPlan.toMap(), SetOptions(merge: true));
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('SAVE'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showEditCandidateDialog(BuildContext context, SuccessionPlan plan, String corpsId, SuccessionCandidate? existingCandidate) {
    String? selectedStaffId = existingCandidate?.staffId;
    String readiness = existingCandidate?.readiness ?? 'ready_now';
    final notesCtrl = TextEditingController(text: existingCandidate?.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(existingCandidate == null ? 'Add Candidate' : 'Edit Candidate'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Staff Member',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    value: _staffMap.containsKey(selectedStaffId) ? selectedStaffId : null,
                    items: _staffMap.values.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                    onChanged: existingCandidate == null ? (val) => setState(() => selectedStaffId = val) : null, // Prevent changing staff once added
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Readiness Level',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    value: readiness,
                    items: const [
                      DropdownMenuItem(value: 'ready_now', child: Text('Ready Now')),
                      DropdownMenuItem(value: '1_2_years', child: Text('Ready 1-2 Years')),
                      DropdownMenuItem(value: '3_plus_years', child: Text('Ready 3+ Years')),
                    ],
                    onChanged: (val) => setState(() => readiness = val!),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Training Needs / Notes',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (existingCandidate != null)
                TextButton(
                  onPressed: () async {
                    final newCandidates = plan.candidates.where((c) => c.staffId != existingCandidate.staffId).toList();
                    final ref = FirebaseFirestore.instance.collection('corps').doc(corpsId).collection('succession_plans').doc(plan.id);
                    await ref.update({'candidates': newCandidates.map((c) => c.toMap()).toList()});
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  child: const Text('REMOVE'),
                ),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
              ElevatedButton(
                onPressed: () async {
                  if (selectedStaffId == null) return;

                  final newCandidate = SuccessionCandidate(
                    staffId: selectedStaffId!,
                    readiness: readiness,
                    notes: notesCtrl.text.trim(),
                  );

                  List<SuccessionCandidate> updatedCandidates = List.from(plan.candidates);
                  
                  if (existingCandidate != null) {
                    final idx = updatedCandidates.indexWhere((c) => c.staffId == existingCandidate.staffId);
                    if (idx != -1) updatedCandidates[idx] = newCandidate;
                  } else {
                    // Prevent duplicates
                    if (!updatedCandidates.any((c) => c.staffId == newCandidate.staffId)) {
                      updatedCandidates.add(newCandidate);
                    }
                  }

                  final ref = FirebaseFirestore.instance.collection('corps').doc(corpsId).collection('succession_plans').doc(plan.id);
                  
                  final updatedPlan = SuccessionPlan(
                    id: plan.id,
                    positionId: plan.positionId,
                    positionName: plan.positionName,
                    currentIncumbentId: plan.currentIncumbentId,
                    expectedRotationDate: plan.expectedRotationDate,
                    candidates: updatedCandidates,
                  );

                  await ref.set(updatedPlan.toMap(), SetOptions(merge: true));
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('SAVE'),
              ),
            ],
          );
        }
      ),
    );
  }
}

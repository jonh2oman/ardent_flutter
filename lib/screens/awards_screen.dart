import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';
import '../models/award.dart';
import '../models/user_data.dart';
import '../services/award_service.dart';

class AwardsScreen extends StatefulWidget {
  const AwardsScreen({super.key});

  @override
  State<AwardsScreen> createState() => _AwardsScreenState();
}

class _AwardsScreenState extends State<AwardsScreen> {
  List<UserData> _allCadets = [];
  Map<String, double> _attendanceMap = {};
  bool _isLoadingCadets = true;

  @override
  void initState() {
    super.initState();
    _loadCadets();
  }

  Future<void> _loadCadets() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final corpsId = auth.userData?.corpsId;
    if (corpsId == null) return;

    final corpsDoc = await FirebaseFirestore.instance
        .collection('corps')
        .doc(corpsId)
        .get();

    final List<dynamic> rawCadets = corpsDoc.data()?['settings']?['cadets'] ?? [];

    final attMap = await AwardService.fetchCorpsAttendance(corpsId);

    if (mounted) {
      setState(() {
        _allCadets = rawCadets
            .where((c) => c['isArchived'] != true)
            .map((c) => UserData.fromMap(c as Map<String, dynamic>, (c['uid'] ?? c['id'] ?? '').toString()))
            .toList();
        _attendanceMap = attMap;
        _isLoadingCadets = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final corpsId = auth.userData?.corpsId;

    if (corpsId == null || _isLoadingCadets) {
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.medal, color: theme.colorScheme.primary, size: 28),
                    const SizedBox(width: 16),
                    const Text(
                      'AWARDS & RECOGNITION',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.0),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAwardForm(context, null),
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('NEW AWARD'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Track eligibility and manage unit and general awards',
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 16),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: StreamBuilder<List<Award>>(
                stream: AwardService.streamAwards(corpsId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final awards = snapshot.data!;
                  if (awards.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.award, size: 64, color: Colors.white.withOpacity(0.1)),
                          const SizedBox(height: 16),
                          const Text('No awards configured', style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: awards.length,
                    itemBuilder: (context, index) {
                      return _buildAwardCard(context, awards[index], theme);
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

  Widget _buildAwardCard(BuildContext context, Award award, ThemeData theme) {
    // Calculate stats
    int eligible = 0;
    for (var cadet in _allCadets) {
      if (AwardService.isEligible(cadet, award, attendanceMap: _attendanceMap)) {
        eligible++;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  award.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(LucideIcons.moreVertical, size: 16, color: Colors.white54),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit Award')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete Award', style: TextStyle(color: Colors.red))),
                ],
                onSelected: (val) {
                  if (val == 'edit') {
                    _showAwardForm(context, award);
                  } else if (val == 'delete') {
                    _confirmDelete(context, award);
                  }
                },
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 4, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: award.type == 'General' ? Colors.blue.withOpacity(0.1) : Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              award.type.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: award.type == 'General' ? Colors.blue : Colors.purpleAccent,
              ),
            ),
          ),
          Text(
            award.description,
            style: const TextStyle(fontSize: 12, color: Colors.white54),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Awarded: ${award.awardedTo.length}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    Text('Eligible: $eligible', style: TextStyle(fontSize: 12, color: eligible > 0 ? Colors.greenAccent : Colors.white70, fontWeight: eligible > 0 ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _showEligibilityReport(context, award),
                icon: const Icon(LucideIcons.clipboardList, size: 14),
                label: const Text('REPORT'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAwardForm(BuildContext context, Award? existingAward) {
    showDialog(
      context: context,
      builder: (context) => _AwardFormDialog(award: existingAward),
    );
  }

  void _showEligibilityReport(BuildContext context, Award award) {
    showDialog(
      context: context,
      builder: (context) => _EligibilityReportDialog(
        award: award,
        allCadets: _allCadets,
        attendanceMap: _attendanceMap,
      ),
    );
  }

  void _confirmDelete(BuildContext context, Award award) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Award?'),
        content: Text('Are you sure you want to permanently delete "${award.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              await AwardService.deleteAward(award.id);
              nav.pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}

// --- AWARD FORM DIALOG ---
class _AwardFormDialog extends StatefulWidget {
  final Award? award;
  const _AwardFormDialog({this.award});

  @override
  State<_AwardFormDialog> createState() => _AwardFormDialogState();
}

class _AwardFormDialogState extends State<_AwardFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  String _type = 'Unit';
  
  // Criteria
  final TextEditingController _minPhaseCtrl = TextEditingController();
  final TextEditingController _exactPhaseCtrl = TextEditingController();
  final TextEditingController _minMonthsCtrl = TextEditingController();
  final TextEditingController _minMeritsCtrl = TextEditingController();
  final TextEditingController _minAttendanceCtrl = TextEditingController();
  final TextEditingController _requiredTagsCtrl = TextEditingController();
  final TextEditingController _manualPrereqCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.award?.name);
    _descCtrl = TextEditingController(text: widget.award?.description);
    _type = widget.award?.type ?? 'Unit';
    _manualPrereqCtrl.text = widget.award?.manualPrerequisites ?? '';

    if (widget.award != null) {
      final c = widget.award!.criteria;
      if (c.containsKey('minPhase')) _minPhaseCtrl.text = c['minPhase'].toString();
      if (c.containsKey('exactPhase')) _exactPhaseCtrl.text = c['exactPhase'].toString();
      if (c.containsKey('minMonthsInCorps')) _minMonthsCtrl.text = c['minMonthsInCorps'].toString();
      if (c.containsKey('minMerits')) _minMeritsCtrl.text = c['minMerits'].toString();
      if (c.containsKey('minAttendance')) _minAttendanceCtrl.text = c['minAttendance'].toString();
      if (c.containsKey('requiredTags')) {
        _requiredTagsCtrl.text = (c['requiredTags'] as List).join(', ');
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _minPhaseCtrl.dispose();
    _exactPhaseCtrl.dispose();
    _minMonthsCtrl.dispose();
    _minMeritsCtrl.dispose();
    _minAttendanceCtrl.dispose();
    _requiredTagsCtrl.dispose();
    _manualPrereqCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    Map<String, dynamic> criteria = {};
    if (_minPhaseCtrl.text.isNotEmpty) criteria['minPhase'] = int.tryParse(_minPhaseCtrl.text) ?? 0;
    if (_exactPhaseCtrl.text.isNotEmpty) criteria['exactPhase'] = int.tryParse(_exactPhaseCtrl.text) ?? 0;
    if (_minMonthsCtrl.text.isNotEmpty) criteria['minMonthsInCorps'] = int.tryParse(_minMonthsCtrl.text) ?? 0;
    if (_minMeritsCtrl.text.isNotEmpty) criteria['minMerits'] = int.tryParse(_minMeritsCtrl.text) ?? 0;
    if (_minAttendanceCtrl.text.isNotEmpty) criteria['minAttendance'] = int.tryParse(_minAttendanceCtrl.text) ?? 0;
    if (_requiredTagsCtrl.text.isNotEmpty) {
      criteria['requiredTags'] = _requiredTagsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    final award = Award(
      id: widget.award?.id ?? '', // Handled by add() if empty
      corpsId: auth.userData!.corpsId,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      type: _type,
      manualPrerequisites: _manualPrereqCtrl.text.trim(),
      criteria: criteria,
      awardedTo: widget.award?.awardedTo ?? [],
      awardedDates: widget.award?.awardedDates ?? {},
    );

    try {
      if (widget.award == null) {
        await AwardService.createAward(award);
      } else {
        await AwardService.updateAward(award);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.award == null ? 'Create New Award' : 'Edit Award'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Award Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(labelText: 'Award Type'),
                  items: const [
                    DropdownMenuItem(value: 'General', child: Text('General (National/Regional)')),
                    DropdownMenuItem(value: 'Unit', child: Text('Unit Specific (Local)')),
                  ],
                  onChanged: (val) => setState(() => _type = val!),
                ),
                const SizedBox(height: 24),
                const Text('ELIGIBILITY CRITERIA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white54)),
                const Divider(),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _minPhaseCtrl,
                  decoration: const InputDecoration(labelText: 'Minimum Phase / Level (e.g. 3)', hintText: 'Leave blank if none'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _exactPhaseCtrl,
                  decoration: const InputDecoration(labelText: 'Exact Phase / Level Required (e.g. 4)', hintText: 'Overrides min phase if set'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _minMonthsCtrl,
                  decoration: const InputDecoration(labelText: 'Minimum Months in Corps (e.g. 24)', hintText: 'Leave blank if none'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _minMeritsCtrl,
                  decoration: const InputDecoration(labelText: 'Minimum Merits Required (e.g. 100)', hintText: 'Leave blank if none'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _minAttendanceCtrl,
                  decoration: const InputDecoration(labelText: 'Minimum Attendance % (e.g. 75)', hintText: 'Leave blank if none'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _requiredTagsCtrl,
                  decoration: const InputDecoration(labelText: 'Required Tags (comma separated)', hintText: 'e.g. Band, Guard, Marksmanship'),
                ),
                const SizedBox(height: 24),
                const Text('MANUAL PREREQUISITES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white54)),
                const Divider(),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _manualPrereqCtrl,
                  decoration: const InputDecoration(labelText: 'Subjective criteria to display on report (e.g. Exceptional Leadership)'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('SAVE AWARD'),
        ),
      ],
    );
  }
}

// --- ELIGIBILITY REPORT DIALOG ---
class _EligibilityReportDialog extends StatefulWidget {
  final Award award;
  final List<UserData> allCadets;
  final Map<String, double> attendanceMap;

  const _EligibilityReportDialog({required this.award, required this.allCadets, required this.attendanceMap});

  @override
  State<_EligibilityReportDialog> createState() => _EligibilityReportDialogState();
}

class _EligibilityReportDialogState extends State<_EligibilityReportDialog> {
  String _filter = 'Eligible'; // 'Eligible', 'Awarded', 'All'

  @override
  Widget build(BuildContext context) {
    List<UserData> eligible = [];
    List<UserData> awarded = [];
    List<UserData> notEligible = [];

    for (var cadet in widget.allCadets) {
      if (widget.award.awardedTo.contains(cadet.id)) {
        awarded.add(cadet);
      } else if (AwardService.isEligible(cadet, widget.award, attendanceMap: widget.attendanceMap)) {
        eligible.add(cadet);
      } else {
        notEligible.add(cadet);
      }
    }

    List<UserData> displayList = [];
    if (_filter == 'Eligible') displayList = eligible;
    if (_filter == 'Awarded') displayList = awarded;
    if (_filter == 'All') {
      displayList = [...eligible, ...awarded, ...notEligible];
    }

    return AlertDialog(
      title: Text('${widget.award.name} Report'),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          children: [
            Row(
              children: [
                _buildFilterTab('Eligible', eligible.length, Colors.greenAccent),
                const SizedBox(width: 8),
                _buildFilterTab('Awarded', awarded.length, Colors.blueAccent),
                const SizedBox(width: 8),
                _buildFilterTab('All', widget.allCadets.length, Colors.white54),
              ],
            ),
            if (widget.award.manualPrerequisites.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.alertCircle, color: Colors.amber, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('MANUAL PREREQUISITES', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(widget.award.manualPrerequisites, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(height: 32),
            Expanded(
              child: displayList.isEmpty
                  ? const Center(child: Text('No personnel in this category.'))
                  : ListView.builder(
                      itemCount: displayList.length,
                      itemBuilder: (context, index) {
                        final cadet = displayList[index];
                        final isAwarded = widget.award.awardedTo.contains(cadet.id);
                        final isElig = isAwarded ? false : AwardService.isEligible(cadet, widget.award, attendanceMap: widget.attendanceMap);

                        return ListTile(
                          title: Text(cadet.name),
                          subtitle: Text(cadet.rank ?? 'No Rank'),
                          trailing: isAwarded
                              ? ElevatedButton.icon(
                                  onPressed: () => _revokeAward(cadet.id),
                                  icon: const Icon(LucideIcons.x, size: 14),
                                  label: const Text('REVOKE'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.2), foregroundColor: Colors.redAccent),
                                )
                              : ElevatedButton.icon(
                                  onPressed: () => _grantAward(cadet.id),
                                  icon: const Icon(LucideIcons.check, size: 14),
                                  label: const Text('GRANT AWARD'),
                                  style: ElevatedButton.styleFrom(backgroundColor: isElig ? Colors.green.withOpacity(0.2) : Colors.white10, foregroundColor: isElig ? Colors.greenAccent : Colors.white54),
                                ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
      ],
    );
  }

  Widget _buildFilterTab(String title, int count, Color color) {
    final isSelected = _filter == title;
    return InkWell(
      onTap: () => setState(() => _filter = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          border: Border.all(color: isSelected ? color : Colors.white10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(title, style: TextStyle(color: isSelected ? color : Colors.white54, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: Text('$count', style: TextStyle(fontSize: 10, color: color)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _grantAward(String cadetId) async {
    await AwardService.grantAward(widget.award.id, cadetId);
    if (mounted) setState(() {});
  }

  Future<void> _revokeAward(String cadetId) async {
    await AwardService.revokeAward(widget.award.id, cadetId);
    if (mounted) setState(() {});
  }
}

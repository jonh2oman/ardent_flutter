import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';

class ShipsLogScreen extends StatefulWidget {
  const ShipsLogScreen({super.key});

  @override
  State<ShipsLogScreen> createState() => _ShipsLogScreenState();
}

class _ShipsLogScreenState extends State<ShipsLogScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  Map<String, dynamic> _formData = {};

  @override
  void initState() {
    super.initState();
    _initEmptyForm();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLogForDate());
  }

  void _initEmptyForm() {
    _formData = {
      'dutyPersonnel': {
        'OOD': '',
        'ODS': '',
        'POOD': '',
        'CMDS': '',
        'Cpl of Gangway': '',
        'Duty Watch/Div': '',
      },
      'attendance': {
        'Cadets': {'present': 0, 'absentLeave': 0, 'absentNoLeave': 0, 'total': 0},
        'Officers': {'present': 0, 'absentLeave': 0, 'absentNoLeave': 0, 'total': 0},
        'Civilians': {'present': 0, 'absentLeave': 0, 'absentNoLeave': 0, 'total': 0},
      },
      'personnelChanges': {
        'joined': 0,
        'discharged': 0,
      },
      'rounds': {
        'Rifles': false,
        'Ammunition': false,
        'Stores': false,
        'Offices': false,
        'Classrooms': false,
        'Firegear': false,
        'Doors': false,
        'Windows': false,
        'Lights': false,
        'Keys': false,
        'External Buildings': false,
      },
      'entries': [],
      'approvals': {
        'OOD': {'approved': false, 'name': ''},
        'Commanding Officer': {'approved': false, 'name': ''},
        'Admin Officer': {'approved': false, 'name': ''},
      }
    };
  }

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);

  Future<void> _loadLogForDate() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final corpsId = auth.userData?.corpsId;
    if (corpsId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('corps')
          .doc(corpsId)
          .collection('ships_logs')
          .doc(_dateKey)
          .get();

      if (doc.exists && doc.data() != null) {
        // Merge data to ensure all keys exist
        _initEmptyForm();
        final data = doc.data()!;
        _deepMerge(_formData, data);
      } else {
        _initEmptyForm();
      }
    } catch (e) {
      debugPrint('Error loading log: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _deepMerge(Map<String, dynamic> target, Map<String, dynamic> source) {
    source.forEach((key, value) {
      if (value is Map<String, dynamic> && target.containsKey(key) && target[key] is Map<String, dynamic>) {
        _deepMerge(target[key], value);
      } else {
        target[key] = value;
      }
    });
  }

  Future<void> _saveLog() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final corpsId = auth.userData?.corpsId;
    if (corpsId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('corps')
          .doc(corpsId)
          .collection('ships_logs')
          .doc(_dateKey)
          .set(_formData, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Log Saved Successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ship\'s Log', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildDateSelector(theme),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildDutyPersonnelCard(theme)),
                            const SizedBox(width: 24),
                            Expanded(flex: 4, child: _buildAttendanceCard(theme)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildRoundsChecklistCard(theme),
                        const SizedBox(height: 24),
                        _buildLogEntriesCard(theme),
                        const SizedBox(height: 24),
                        _buildApprovalsCard(theme),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveLog,
        icon: const Icon(LucideIcons.save),
        label: const Text('Save Log Entry'),
      ),
    );
  }

  Widget _buildDateSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          const Text('Select a Log Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null && picked != _selectedDate) {
                setState(() => _selectedDate = picked);
                _loadLogForDate();
              }
            },
            icon: const Icon(LucideIcons.calendar, size: 16),
            label: Text(DateFormat('MMMM d, yyyy').format(_selectedDate)),
          ),
        ],
      ),
    );
  }

  Widget _buildDutyPersonnelCard(ThemeData theme) {
    final dp = _formData['dutyPersonnel'] as Map<String, dynamic>;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Duty Personnel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...dp.keys.map((role) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: role,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                controller: TextEditingController(text: dp[role])..selection = TextSelection.collapsed(offset: (dp[role] ?? '').length),
                onChanged: (val) => dp[role] = val,
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(ThemeData theme) {
    final att = _formData['attendance'] as Map<String, dynamic>;
    final changes = _formData['personnelChanges'] as Map<String, dynamic>;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Routine Occurrences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Attendance & Personnel', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildAttendanceColumn('Cadets', att['Cadets'], theme)),
                Expanded(child: _buildAttendanceColumn('Officers', att['Officers'], theme)),
                Expanded(child: _buildAttendanceColumn('Civilians', att['Civilians'], theme)),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildNumberInput('Joined / Enrolled', changes['joined'], (val) => setState(() => changes['joined'] = val)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildNumberInput('Discharged / Libérés', changes['discharged'], (val) => setState(() => changes['discharged'] = val)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceColumn(String title, Map<String, dynamic> data, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildNumberInput('Present', data['present'], (val) => setState(() => data['present'] = val)),
        _buildNumberInput('Absent w/ Leave', data['absentLeave'], (val) => setState(() => data['absentLeave'] = val)),
        _buildNumberInput('Absent w/o Leave', data['absentNoLeave'], (val) => setState(() => data['absentNoLeave'] = val)),
        const SizedBox(height: 8),
        Text('Total Strength: ${data['total']}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
        _buildNumberInput('Override Total', data['total'], (val) => setState(() => data['total'] = val)), // Simple override
      ],
    );
  }

  Widget _buildNumberInput(String label, int value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: const TextStyle(fontSize: 12))),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 30,
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(8), border: OutlineInputBorder()),
                controller: TextEditingController(text: value.toString())..selection = TextSelection.collapsed(offset: value.toString().length),
                onChanged: (val) => onChanged(int.tryParse(val) ?? 0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundsChecklistCard(ThemeData theme) {
    final rounds = _formData['rounds'] as Map<String, dynamic>;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rounds Checklist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: rounds.keys.map((item) => SizedBox(
                width: 180,
                child: CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(item, style: const TextStyle(fontSize: 13)),
                  value: rounds[item],
                  onChanged: (val) => setState(() => rounds[item] = val ?? false),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogEntriesCard(ThemeData theme) {
    final entries = _formData['entries'] as List<dynamic>;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Log Entries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      entries.add({'time': DateFormat('HH:mm').format(DateTime.now()), 'text': ''});
                    });
                  },
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('Add Entry'),
                )
              ],
            ),
            const SizedBox(height: 16),
            ...entries.asMap().entries.map((e) {
              final index = e.key;
              final entry = e.value as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Time', isDense: true, border: OutlineInputBorder()),
                        controller: TextEditingController(text: entry['time'])..selection = TextSelection.collapsed(offset: (entry['time'] ?? '').length),
                        onChanged: (val) => entry['time'] = val,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Entry', isDense: true, border: OutlineInputBorder()),
                        controller: TextEditingController(text: entry['text'])..selection = TextSelection.collapsed(offset: (entry['text'] ?? '').length),
                        onChanged: (val) => entry['text'] = val,
                        maxLines: null,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 18),
                      onPressed: () => setState(() => entries.removeAt(index)),
                    )
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalsCard(ThemeData theme) {
    final approvals = _formData['approvals'] as Map<String, dynamic>;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Approvals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, backgroundColor: Colors.white24)),
            const SizedBox(height: 16),
            ...approvals.keys.map((role) {
              final app = approvals[role] as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: app['approved'],
                        onChanged: (val) => setState(() => app['approved'] = val ?? false),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(role, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, backgroundColor: Colors.white24)),
                              const SizedBox(height: 4),
                              TextField(
                                decoration: const InputDecoration(
                                  hintText: 'Type name to approve',
                                  isDense: true,
                                  border: InputBorder.none,
                                  fillColor: Colors.black12,
                                  filled: true,
                                ),
                                controller: TextEditingController(text: app['name'])..selection = TextSelection.collapsed(offset: (app['name'] ?? '').length),
                                onChanged: (val) => app['name'] = val,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

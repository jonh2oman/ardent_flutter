import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/parade_day.dart';
import '../models/user_data.dart';
import '../services/pdf_service.dart';

class RoutineOrdersScreen extends StatefulWidget {
  const RoutineOrdersScreen({super.key});

  @override
  State<RoutineOrdersScreen> createState() => _RoutineOrdersScreenState();
}

class _RoutineOrdersScreenState extends State<RoutineOrdersScreen> {
  String? _selectedDate;
  List<UserData> _staff = [];
  bool _loadingStaff = true;

  @override
  void initState() {
    super.initState();
    // Initial fetch happens in didChangeDependencies
  }

  String? _lastCorpsId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context);
    final corpsId = auth.userData?.corpsId;
    if (corpsId != _lastCorpsId) {
      _lastCorpsId = corpsId;
      _fetchStaff();
    }
  }

  Future<void> _fetchStaff() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final corpsId = auth.userData?.corpsId;
    if (corpsId == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('corpsId', isEqualTo: corpsId)
        .get();

    if (mounted) {
      setState(() {
        _staff = snapshot.docs
            .map((doc) => UserData.fromMap(doc.data(), doc.id))
            .where((u) => u.isArchived != true)
            .toList();
        _loadingStaff = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    
    final trainingYear = auth.corpsData?.trainingYears['current'] ?? {};
    final calendar = Map<String, dynamic>.from(trainingYear['calendar'] ?? {});
    final dates = calendar.keys.toList()..sort();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.fileText, color: Colors.orangeAccent, size: 28),
                const SizedBox(width: 16),
                Text('Routine Orders', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            
            // Date Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedDate,
                  hint: const Text('Select a Parade Night', style: TextStyle(color: Colors.white30)),
                  dropdownColor: const Color(0xFF1A1A1A),
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white),
                  items: dates.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (val) => setState(() => _selectedDate = val),
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_selectedDate != null)
              Expanded(
                child: _buildROForm(context, auth, ParadeDay.fromMap(calendar[_selectedDate]!, _selectedDate!)),
              )
            else
              const Expanded(
                child: Center(child: Text('Select a date to generate Routine Orders', style: TextStyle(color: Colors.white24))),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildROForm(BuildContext context, AuthProvider auth, ParadeDay day) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            title: 'Duty Roster',
            icon: LucideIcons.userCheck,
            children: _loadingStaff 
              ? [const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))]
              : [
                _buildStaffDropdown(context, auth, day, 'Duty Officer', 'dutyOfficer'),
                _buildCadetDropdown(context, auth, day, 'Duty Petty Officer', 'dutyPO'),
                _buildCadetDropdown(context, auth, day, 'Duty Coxswain', 'dutyCoxn'),
                _buildDivisionDropdown(context, auth, day, 'Duty Division', 'dutyDivision'),
              ],
          ),
          const SizedBox(height: 24),
          _buildCard(
            title: 'Announcements',
            icon: LucideIcons.megaphone,
            children: [
              ...day.announcements.map((a) => ListTile(
                title: Text(a, style: const TextStyle(fontSize: 13)),
                trailing: IconButton(
                  icon: const Icon(LucideIcons.x, size: 14),
                  onPressed: () => _removeAnnouncement(auth, day, a),
                ),
              )).toList(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  onSubmitted: (val) => _addAnnouncement(auth, day, val),
                  decoration: const InputDecoration(
                    hintText: 'Add a new announcement...',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.white24),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.all(20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => _showROPreview(context, auth, day),
                  icon: const Icon(LucideIcons.eye),
                  label: const Text('PREVIEW', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.all(20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    if (auth.corpsData != null) {
                      PdfService.exportRoutineOrders(day, auth.corpsData!);
                    }
                  },
                  icon: const Icon(LucideIcons.download),
                  label: const Text('EXPORT PDF', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStaffDropdown(BuildContext context, AuthProvider auth, ParadeDay day, String label, String key) {
    final currentValue = day.dutyRoster[key];
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        value: _staff.any((s) => s.name == currentValue) ? currentValue : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 10, color: Colors.white30),
        ),
        dropdownColor: const Color(0xFF1A1A1A),
        style: const TextStyle(fontSize: 14, color: Colors.white),
        items: _staff.map((s) => DropdownMenuItem<String>(
          value: s.name,
          child: Text("${s.rank ?? ''} ${s.name}"),
        )).toList(),
        onChanged: (val) {
          if (val != null) _updateDuty(auth, day, key, val);
        },
      ),
    );
  }

  Widget _buildCadetDropdown(BuildContext context, AuthProvider auth, ParadeDay day, String label, String key) {
    final currentValue = day.dutyRoster[key];
    final List<dynamic> cadetsRaw = auth.corpsData?.settings['cadets'] ?? [];
    final List<UserData> cadets = cadetsRaw.map((c) => UserData.fromMap(Map<String, dynamic>.from(c), c['id'] ?? c['uid'] ?? '')).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        value: cadets.any((c) => c.name == currentValue) ? currentValue : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 10, color: Colors.white30),
        ),
        dropdownColor: const Color(0xFF1A1A1A),
        style: const TextStyle(fontSize: 14, color: Colors.white),
        items: cadets.map((c) => DropdownMenuItem<String>(
          value: c.name,
          child: Text("${c.rank ?? 'Cadet'} ${c.name}"),
        )).toList(),
        onChanged: (val) {
          if (val != null) _updateDuty(auth, day, key, val);
        },
      ),
    );
  }

  Widget _buildDivisionDropdown(BuildContext context, AuthProvider auth, ParadeDay day, String label, String key) {
    final currentValue = day.dutyRoster[key];
    final List<String> divisions = List<String>.from(auth.corpsData?.settings['divisions'] ?? ['Main Deck', 'Quarterdeck', 'Forecastle', 'Aft Deck', 'Training Office']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        value: divisions.contains(currentValue) ? currentValue : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 10, color: Colors.white30),
        ),
        dropdownColor: const Color(0xFF1A1A1A),
        style: const TextStyle(fontSize: 14, color: Colors.white),
        items: divisions.map((d) => DropdownMenuItem(
          value: d,
          child: Text(d),
        )).toList(),
        onChanged: (val) {
          if (val != null) _updateDuty(auth, day, key, val);
        },
      ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.orangeAccent),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Future<void> _updateDuty(AuthProvider auth, ParadeDay day, String key, String value) async {
    final corpsId = auth.userData?.corpsId;
    if (corpsId == null) return;

    final Map<String, dynamic> trainingYear = auth.corpsData?.trainingYears['current'] ?? {};
    final Map<String, dynamic> calendar = Map<String, dynamic>.from(trainingYear['calendar'] ?? {});
    
    final Map<String, String> duty = Map<String, String>.from(day.dutyRoster);
    duty[key] = value;
    
    calendar[day.date]['dutyRoster'] = duty;

    await FirebaseFirestore.instance.collection('corps').doc(corpsId).update({
      'trainingYears.current.calendar': calendar,
    });
  }

  Future<void> _addAnnouncement(AuthProvider auth, ParadeDay day, String text) async {
    if (text.isEmpty) return;
    final corpsId = auth.userData?.corpsId;
    if (corpsId == null) return;

    final Map<String, dynamic> trainingYear = auth.corpsData?.trainingYears['current'] ?? {};
    final Map<String, dynamic> calendar = Map<String, dynamic>.from(trainingYear['calendar'] ?? {});
    
    final List<String> announcements = List<String>.from(day.announcements);
    announcements.add(text);
    
    calendar[day.date]['announcements'] = announcements;

    await FirebaseFirestore.instance.collection('corps').doc(corpsId).update({
      'trainingYears.current.calendar': calendar,
    });
  }

  Future<void> _removeAnnouncement(AuthProvider auth, ParadeDay day, String text) async {
    final corpsId = auth.userData?.corpsId;
    if (corpsId == null) return;

    final Map<String, dynamic> trainingYear = auth.corpsData?.trainingYears['current'] ?? {};
    final Map<String, dynamic> calendar = Map<String, dynamic>.from(trainingYear['calendar'] ?? {});
    
    final List<String> announcements = List<String>.from(day.announcements);
    announcements.remove(text);
    
    calendar[day.date]['announcements'] = announcements;

    await FirebaseFirestore.instance.collection('corps').doc(corpsId).update({
      'trainingYears.current.calendar': calendar,
    });
  }

  void _showROPreview(BuildContext context, AuthProvider auth, ParadeDay day) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.blueGrey[900],
              title: const Text('Routine Orders Preview'),
              actions: [
                IconButton(
                  icon: const Icon(LucideIcons.download), 
                  onPressed: () {
                    if (auth.corpsData != null) {
                      PdfService.exportRoutineOrders(day, auth.corpsData!);
                    }
                  },
                  tooltip: 'Download PDF',
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
                          if (auth.corpsData?.logoUrl != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Image.network(
                                auth.corpsData!.logoUrl!,
                                height: 80,
                                fit: BoxFit.contain,
                              ),
                            ),
                          Text('ROUTINE ORDERS', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black)),
                          Text('Issued by ${auth.corpsData?.coRank} ${auth.corpsData?.coName}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          Text(auth.corpsData?.unitDesignation.toUpperCase() ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                          const SizedBox(height: 10),
                          Container(height: 2, width: 200, color: Colors.black),
                          const SizedBox(height: 10),
                          Text('FOR THE PERIOD OF ${day.date.toUpperCase()}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildROSection('PART 1 - TRAINING', [
                      ...day.periods.entries.map((p) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('PERIOD ${p.key.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 13)),
                              ...(p.value as Map).entries.map((lvl) {
                                return Text('• ${lvl.key}: ${lvl.value['lessonId']} (${lvl.value['instructor'] ?? 'TBD'}) at ${lvl.value['location'] ?? 'Main Deck'}', style: const TextStyle(color: Colors.black87, fontSize: 12));
                              }).toList(),
                            ],
                          ),
                        );
                      }).toList(),
                    ]),
                    const SizedBox(height: 30),
                    _buildROSection('PART 2 - DUTY ROSTER', [
                      ...day.dutyRoster.entries.map((e) => Text('• ${e.key.replaceAll(RegExp(r'(?=[A-Z])'), ' ').toUpperCase()}: ${e.value}', style: const TextStyle(color: Colors.black87, fontSize: 12))).toList(),
                    ]),
                    const SizedBox(height: 30),
                    _buildROSection('PART 3 - ANNOUNCEMENTS', [
                      ...day.announcements.map((a) => Text('• $a', style: const TextStyle(color: Colors.black87, fontSize: 12))).toList(),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildROSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, decoration: TextDecoration.underline, color: Colors.black)),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

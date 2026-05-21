import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/parade_day.dart';
import '../models/user_data.dart';
import '../models/military_order.dart';
import '../services/pdf_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Routine Orders States
  String? _selectedDate;
  List<UserData> _staff = [];
  bool _loadingStaff = true;
  String? _lastCorpsId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.orangeAccent,
            labelColor: Colors.orangeAccent,
            unselectedLabelColor: Colors.white30,
            tabs: const [
              Tab(text: 'ROUTINE ORDERS', icon: Icon(LucideIcons.fileText, size: 18)),
              Tab(text: 'WARNING ORDERS', icon: Icon(LucideIcons.alertTriangle, size: 18)),
              Tab(text: 'OPERATION ORDERS', icon: Icon(LucideIcons.shield, size: 18)),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRoutineOrdersTab(context),
          _buildWarningOrdersTab(context),
          _buildOperationOrdersTab(context),
        ],
      ),
    );
  }

  // ==========================================
  // ROUTINE ORDERS TAB
  // ==========================================
  Widget _buildRoutineOrdersTab(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    
    final trainingYear = auth.corpsData?.trainingYears['current'] ?? {};
    final calendar = Map<String, dynamic>.from(trainingYear['calendar'] ?? {});
    final dates = calendar.keys.toList()..sort();

    return Padding(
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

  // ==========================================
  // WARNING ORDERS TAB
  // ==========================================
  String _warningSearchQuery = '';

  Widget _buildWarningOrdersTab(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final corpsId = auth.userData?.corpsId;
    if (corpsId == null) {
      return const Center(child: Text('Corpse/Squadron ID not found.'));
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Header & Create Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.alertTriangle, color: Colors.amberAccent, size: 28),
                  const SizedBox(width: 16),
                  Text('Warning Orders', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _openWarningOrderForm(context, corpsId, null),
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('CREATE WARNING ORDER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search Bar
          TextField(
            onChanged: (val) => setState(() => _warningSearchQuery = val.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search warning orders by subject...',
              prefixIcon: const Icon(LucideIcons.search, size: 18, color: Colors.white30),
              filled: true,
              fillColor: Colors.white.withOpacity(0.03),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),

          // Orders List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('corps')
                  .doc(corpsId)
                  .collection('warning_orders')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                final orders = docs
                    .map((doc) => WarningOrder.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                    .where((o) => o.subject.toLowerCase().contains(_warningSearchQuery))
                    .toList();

                if (orders.isEmpty) {
                  return const Center(
                    child: Text('No Warning Orders found.', style: TextStyle(color: Colors.white24)),
                  );
                }

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          order.subject,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        subtitle: Text(
                          'Date: ${order.date}  |  Ref: ${order.fileNumber}',
                          style: const TextStyle(color: Colors.white30, fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(LucideIcons.eye, color: Colors.white60, size: 18),
                              onPressed: () => _viewWarningOrder(context, auth, order),
                              tooltip: 'Preview',
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.edit2, color: Colors.amberAccent, size: 18),
                              onPressed: () => _openWarningOrderForm(context, corpsId, order),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 18),
                              onPressed: () => _deleteWarningOrder(context, corpsId, order),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // OPERATION ORDERS TAB
  // ==========================================
  String _opordSearchQuery = '';

  Widget _buildOperationOrdersTab(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final corpsId = auth.userData?.corpsId;
    if (corpsId == null) {
      return const Center(child: Text('Corpse/Squadron ID not found.'));
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Header & Create Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.shield, color: Colors.greenAccent, size: 28),
                  const SizedBox(width: 16),
                  Text('Operation Orders', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _openOperationOrderForm(context, corpsId, null),
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('CREATE OPERATION ORDER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search Bar
          TextField(
            onChanged: (val) => setState(() => _opordSearchQuery = val.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search operation orders by subject...',
              prefixIcon: const Icon(LucideIcons.search, size: 18, color: Colors.white30),
              filled: true,
              fillColor: Colors.white.withOpacity(0.03),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),

          // Orders List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('corps')
                  .doc(corpsId)
                  .collection('operation_orders')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                final orders = docs
                    .map((doc) => OperationOrder.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                    .where((o) => o.subject.toLowerCase().contains(_opordSearchQuery))
                    .toList();

                if (orders.isEmpty) {
                  return const Center(
                    child: Text('No Operation Orders found.', style: TextStyle(color: Colors.white24)),
                  );
                }

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          order.subject,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        subtitle: Text(
                          'Date: ${order.date}  |  Ref: ${order.fileNumber}',
                          style: const TextStyle(color: Colors.white30, fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(LucideIcons.eye, color: Colors.white60, size: 18),
                              onPressed: () => _viewOperationOrder(context, auth, order),
                              tooltip: 'Preview',
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.edit2, color: Colors.greenAccent, size: 18),
                              onPressed: () => _openOperationOrderForm(context, corpsId, order),
                              tooltip: 'Edit / Fill Blanks',
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 18),
                              onPressed: () => _deleteOperationOrder(context, corpsId, order),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ACTION / HELPER METHODS FOR WNG ORDERS
  // ==========================================
  Future<void> _deleteWarningOrder(BuildContext context, String corpsId, WarningOrder order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Warning Order'),
        content: Text('Are you sure you want to delete "${order.subject}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('corps')
          .doc(corpsId)
          .collection('warning_orders')
          .doc(order.id)
          .delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Warning Order deleted successfully.')),
        );
      }
    }
  }

  void _viewWarningOrder(BuildContext context, AuthProvider auth, WarningOrder order) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.amber[800],
              title: const Text('Warning Order Details'),
              actions: [
                IconButton(
                  icon: const Icon(LucideIcons.download), 
                  onPressed: () => PdfService.exportWarningOrder(order, auth.corpsData!),
                  tooltip: 'Export PDF',
                ),
                IconButton(
                  icon: const Icon(LucideIcons.shieldAlert), 
                  onPressed: () async {
                    Navigator.pop(context);
                    await _generateOpordFromWarning(context, auth, order);
                  },
                  tooltip: 'Generate Operation Order',
                ),
                IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: SystemMouseCursors.click == MouseCursor.defer ? CrossAxisAlignment.start : CrossAxisAlignment.start,
                  children: [
                    // Heading Text
                    Center(
                      child: Column(
                        children: [
                          const Text('CAN UNCLASSIFIED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(auth.corpsData?.ordersHeaderEn ?? '', style: const TextStyle(fontSize: 9, color: Colors.black)),
                              Text(auth.corpsData?.ordersHeaderFr ?? '', style: const TextStyle(fontSize: 9, color: Colors.black), textAlign: TextAlign.right),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(order.fileNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black)),
                              Text(order.date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(order.subject.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, decoration: TextDecoration.underline, color: Colors.black), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildMilitaryTextSection('REFERENCES', order.references.join(';\n')),
                    _buildMilitaryTextSection('SITUATION', order.situation),
                    _buildMilitaryTextSection('MISSION', order.mission),
                    _buildMilitaryTextSection('EXECUTION (ADMIN INSTRUCTIONS)', 
                      '• Orders: ${order.adminOrders}\n'
                      '• JIs: ${order.adminJIs}\n'
                      '• Eligibility: ${order.participantEligibility}\n'
                      '• Registration: ${order.registrationOfParticipants}\n'
                      '• Support Opportunities: ${order.supportCadetOpportunities}\n'
                      '• Adult Staffing: ${order.adultStaffingOpportunities}\n'
                      '• Accommodation: ${order.requestForAccommodation}\n'
                      '• Contingency: ${order.contingencyPlans}\n'
                      '• Lessons: ${order.lessonsLearned}\n'
                      '• GBA+: ${order.gbaPlus}'
                    ),
                    _buildMilitaryTextSection('SERVICE SUPPORT', 
                      '• Pay: ${order.pay}\n'
                      '• Travel: ${order.travel}\n'
                      '• Rations: ${order.rations}\n'
                      '• Lodgings: ${order.lodgings}\n'
                      '• Transportation: ${order.transportation}\n'
                      '• Equipment: ${order.equipment}\n'
                      '• Public Affairs: ${order.publicAffairs}\n'
                      '• Financial Auth: ${order.financialAuthorization}'
                    ),
                    _buildMilitaryTextSection('COMMAND & SIGNALS', 
                      order.contacts.map((c) => '• ${c['role']}: ${c['name']} (${c['phone']} / ${c['email']})').join('\n')
                    ),
                    const SizedBox(height: 30),
                    const Text('ANNEX A - SERIALS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black, decoration: TextDecoration.underline)),
                    const SizedBox(height: 10),
                    Table(
                      border: TableBorder.all(color: Colors.black45),
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: Colors.grey[200]),
                          children: const [
                            TableCell(child: Padding(padding: EdgeInsets.all(6), child: Text('SERIAL', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 10)))),
                            TableCell(child: Padding(padding: EdgeInsets.all(6), child: Text('DATE/LOC', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 10)))),
                            TableCell(child: Padding(padding: EdgeInsets.all(6), child: Text('ELEMENT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 10)))),
                            TableCell(child: Padding(padding: EdgeInsets.all(6), child: Text('UNITS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 10)))),
                          ],
                        ),
                        ...order.serials.map((s) => TableRow(
                          children: [
                            TableCell(child: Padding(padding: const EdgeInsets.all(6), child: Text('${s['serial'] ?? ''}\n${s['code'] ?? ''}', style: const TextStyle(color: Colors.black, fontSize: 10)))),
                            TableCell(child: Padding(padding: const EdgeInsets.all(6), child: Text('${s['dates'] ?? ''}\n${s['location'] ?? ''}', style: const TextStyle(color: Colors.black, fontSize: 10)))),
                            TableCell(child: Padding(padding: const EdgeInsets.all(6), child: Text(s['element'] ?? '', style: const TextStyle(color: Colors.black, fontSize: 10)))),
                            TableCell(child: Padding(padding: const EdgeInsets.all(6), child: Text(s['units'] ?? '', style: const TextStyle(color: Colors.black, fontSize: 10)))),
                          ],
                        )).toList(),
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

  Widget _buildMilitaryTextSection(String heading, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading, style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline, fontSize: 12, color: Colors.black)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(content.isEmpty ? 'Nil' : content, style: const TextStyle(color: Colors.black87, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Future<void> _generateOpordFromWarning(BuildContext context, AuthProvider auth, WarningOrder warning) async {
    final corpsId = auth.userData?.corpsId;
    if (corpsId == null) return;

    final draft = OperationOrder.fromWarningOrder(warning);

    // Save draft to Firestore
    final docRef = await FirebaseFirestore.instance
        .collection('corps')
        .doc(corpsId)
        .collection('operation_orders')
        .add(draft.toMap());

    // Retrieve saved doc and open editor
    final docSnap = await docRef.get();
    final createdOpord = OperationOrder.fromMap(docSnap.data() as Map<String, dynamic>, docSnap.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Operation Order generated from Warning Order: "${warning.subject}"')),
      );
      _openOperationOrderForm(context, corpsId, createdOpord);
    }
  }

  // ==========================================
  // ACTION / HELPER METHODS FOR OP ORDERS
  // ==========================================
  Future<void> _deleteOperationOrder(BuildContext context, String corpsId, OperationOrder order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Operation Order'),
        content: Text('Are you sure you want to delete "${order.subject}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('corps')
          .doc(corpsId)
          .collection('operation_orders')
          .doc(order.id)
          .delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Operation Order deleted successfully.')),
        );
      }
    }
  }

  void _viewOperationOrder(BuildContext context, AuthProvider auth, OperationOrder order) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.green[800],
              title: const Text('Operation Order Details'),
              actions: [
                IconButton(
                  icon: const Icon(LucideIcons.download), 
                  onPressed: () => PdfService.exportOperationOrder(order, auth.corpsData!),
                  tooltip: 'Export PDF',
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
                          const Text('CAN UNCLASSIFIED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(auth.corpsData?.ordersHeaderEn ?? '', style: const TextStyle(fontSize: 9, color: Colors.black)),
                              Text(auth.corpsData?.ordersHeaderFr ?? '', style: const TextStyle(fontSize: 9, color: Colors.black), textAlign: TextAlign.right),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(order.fileNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black)),
                              Text(order.date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(order.subject.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, decoration: TextDecoration.underline, color: Colors.black), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildMilitaryTextSection('REFERENCES', order.references.join(';\n')),
                    _buildMilitaryTextSection('SITUATION', order.situation),
                    _buildMilitaryTextSection('MISSION', order.mission),
                    _buildMilitaryTextSection('EXECUTION (CONCEPT OF OPERATIONS)', 
                      '• Command Intent: ${order.conceptCommandIntent}\n'
                      '• Scheme of Maneuver: ${order.conceptSchemeOfManeuver}\n'
                      '• General Outline: ${order.conceptGeneralOutline}\n'
                      '• End State: ${order.conceptEndState}\n'
                      '• Contingency Plan: ${order.contingencyPlan}\n'
                      '• Groupings: ${order.groupings}\n'
                      '• Taskings: ${order.taskings}'
                    ),
                    _buildMilitaryTextSection('EXECUTION (COORDINATING INSTRUCTIONS)', 
                      '• Orders: ${order.adminOrders}\n'
                      '• Eligibility: ${order.participantEligibility}\n'
                      '• Registration: ${order.registrationOfParticipants}\n'
                      '• Support Eligibility: ${order.supportCadetEligibility}\n'
                      '• Adult Staffing: ${order.adultStaffingOpportunities}\n'
                      '• Lessons: ${order.lessonsLearned}\n'
                      '• Dress: ${order.dress}\n'
                      '• Medical / Emergency: ${order.medicalEmergency}\n'
                      '• Conduct / Discipline: ${order.conductDiscipline}\n'
                      '• GBA+: ${order.gbaPlus}'
                    ),
                    _buildMilitaryTextSection('SERVICE SUPPORT', 
                      '• Pay: ${order.pay}\n'
                      '• Lodgings: ${order.lodgings}\n'
                      '• Transportation: ${order.transportation}\n'
                      '• Rations: ${order.rations}\n'
                      '• Accommodation: ${order.requestForAccommodation}\n'
                      '• Equipment: ${order.equipment}\n'
                      '• Info Tech: ${order.informationTechnology}\n'
                      '• Travel Claims: ${order.travelClaims}\n'
                      '• Public Affairs: ${order.publicAffairs}'
                    ),
                    _buildMilitaryTextSection('COMMAND & SIGNALS', 
                      '• Contacts:\n' + order.contacts.map((c) => '  - ${c['role']}: ${c['name']} (${c['phone']} / ${c['email']})').join('\n') + '\n' +
                      '• Emergency Comms: ${order.emergencyCommunications}'
                    ),
                    _buildMilitaryTextSection('ANNEXES LIST', order.annexes.join('\n')),
                    const SizedBox(height: 30),
                    const Text('ANNEX C - SERIALS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black, decoration: TextDecoration.underline)),
                    const SizedBox(height: 10),
                    Table(
                      border: TableBorder.all(color: Colors.black45),
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: Colors.grey[200]),
                          children: const [
                            TableCell(child: Padding(padding: EdgeInsets.all(6), child: Text('SERIAL', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 10)))),
                            TableCell(child: Padding(padding: EdgeInsets.all(6), child: Text('DATE/LOC', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 10)))),
                            TableCell(child: Padding(padding: EdgeInsets.all(6), child: Text('ELEMENT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 10)))),
                            TableCell(child: Padding(padding: EdgeInsets.all(6), child: Text('UNITS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 10)))),
                          ],
                        ),
                        ...order.serials.map((s) => TableRow(
                          children: [
                            TableCell(child: Padding(padding: const EdgeInsets.all(6), child: Text('${s['serial'] ?? ''}\n${s['code'] ?? ''}', style: const TextStyle(color: Colors.black, fontSize: 10)))),
                            TableCell(child: Padding(padding: const EdgeInsets.all(6), child: Text('${s['dates'] ?? ''}\n${s['location'] ?? ''}', style: const TextStyle(color: Colors.black, fontSize: 10)))),
                            TableCell(child: Padding(padding: const EdgeInsets.all(6), child: Text(s['element'] ?? '', style: const TextStyle(color: Colors.black, fontSize: 10)))),
                            TableCell(child: Padding(padding: const EdgeInsets.all(6), child: Text(s['units'] ?? '', style: const TextStyle(color: Colors.black, fontSize: 10)))),
                          ],
                        )).toList(),
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

  // ==========================================
  // FORMS / EDITORS FOR WARNING & OP ORDERS
  // ==========================================
  void _openWarningOrderForm(BuildContext context, String corpsId, WarningOrder? existing) {
    final isNew = existing == null;

    final fileNumberCtrl = TextEditingController(text: isNew ? '1085-3-5 (Area Trg O)' : existing.fileNumber);
    final subjectCtrl = TextEditingController(text: isNew ? '' : existing.subject);
    final dateCtrl = TextEditingController(text: isNew ? '' : existing.date);
    final referencesCtrl = TextEditingController(text: isNew ? '' : existing.references.join('\n'));
    final situationCtrl = TextEditingController(text: isNew ? '' : existing.situation);
    final missionCtrl = TextEditingController(text: isNew ? '' : existing.mission);
    
    final adminOrdersCtrl = TextEditingController(text: isNew ? '' : existing.adminOrders);
    final adminJIsCtrl = TextEditingController(text: isNew ? '' : existing.adminJIs);
    final participantEligibilityCtrl = TextEditingController(text: isNew ? '' : existing.participantEligibility);
    final registrationCtrl = TextEditingController(text: isNew ? '' : existing.registrationOfParticipants);
    final supportCtrl = TextEditingController(text: isNew ? '' : existing.supportCadetOpportunities);
    final adultStaffCtrl = TextEditingController(text: isNew ? '' : existing.adultStaffingOpportunities);
    final accommodationCtrl = TextEditingController(text: isNew ? '' : existing.requestForAccommodation);
    final contingencyCtrl = TextEditingController(text: isNew ? '' : existing.contingencyPlans);
    final lessonsCtrl = TextEditingController(text: isNew ? '' : existing.lessonsLearned);
    final gbaPlusCtrl = TextEditingController(text: isNew ? '' : existing.gbaPlus);

    final payCtrl = TextEditingController(text: isNew ? '' : existing.pay);
    final travelCtrl = TextEditingController(text: isNew ? '' : existing.travel);
    final rationsCtrl = TextEditingController(text: isNew ? '' : existing.rations);
    final lodgingsCtrl = TextEditingController(text: isNew ? '' : existing.lodgings);
    final transportationCtrl = TextEditingController(text: isNew ? '' : existing.transportation);
    final equipmentCtrl = TextEditingController(text: isNew ? '' : existing.equipment);
    final publicAffairsCtrl = TextEditingController(text: isNew ? '' : existing.publicAffairs);
    final financialAuthCtrl = TextEditingController(text: isNew ? '' : existing.financialAuthorization);

    final distActionCtrl = TextEditingController(text: isNew ? '' : existing.distributionAction.join('\n'));
    final distInfoCtrl = TextEditingController(text: isNew ? '' : existing.distributionInfo.join('\n'));

    List<Map<String, String>> serials = isNew ? [] : List<Map<String, String>>.from(existing.serials);
    List<Map<String, String>> contacts = isNew ? [] : List<Map<String, String>>.from(existing.contacts);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog.fullscreen(
          backgroundColor: const Color(0xFF151515),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.black,
              title: Text(isNew ? 'New Warning Order' : 'Edit Warning Order'),
              actions: [
                TextButton(
                  onPressed: () async {
                    final data = {
                      'fileNumber': fileNumberCtrl.text,
                      'subject': subjectCtrl.text,
                      'date': dateCtrl.text,
                      'references': referencesCtrl.text.split('\n').where((s) => s.trim().isNotEmpty).toList(),
                      'situation': situationCtrl.text,
                      'mission': missionCtrl.text,
                      'adminOrders': adminOrdersCtrl.text,
                      'adminJIs': adminJIsCtrl.text,
                      'participantEligibility': participantEligibilityCtrl.text,
                      'registrationOfParticipants': registrationCtrl.text,
                      'supportCadetOpportunities': supportCtrl.text,
                      'adultStaffingOpportunities': adultStaffCtrl.text,
                      'requestForAccommodation': accommodationCtrl.text,
                      'contingencyPlans': contingencyCtrl.text,
                      'lessonsLearned': lessonsCtrl.text,
                      'gbaPlus': gbaPlusCtrl.text,
                      'pay': payCtrl.text,
                      'travel': travelCtrl.text,
                      'rations': rationsCtrl.text,
                      'lodgings': lodgingsCtrl.text,
                      'transportation': transportationCtrl.text,
                      'equipment': equipmentCtrl.text,
                      'publicAffairs': publicAffairsCtrl.text,
                      'financialAuthorization': financialAuthCtrl.text,
                      'distributionAction': distActionCtrl.text.split('\n').where((s) => s.trim().isNotEmpty).toList(),
                      'distributionInfo': distInfoCtrl.text.split('\n').where((s) => s.trim().isNotEmpty).toList(),
                      'serials': serials,
                      'contacts': contacts,
                    };

                    if (isNew) {
                      await FirebaseFirestore.instance
                          .collection('corps')
                          .doc(corpsId)
                          .collection('warning_orders')
                          .add(data);
                    } else {
                      await FirebaseFirestore.instance
                          .collection('corps')
                          .doc(corpsId)
                          .collection('warning_orders')
                          .doc(existing.id)
                          .update(data);
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isNew ? 'Warning Order created.' : 'Warning Order updated.')),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('SAVE', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                ),
                IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormHeader('General details'),
                  _buildField('File Number', fileNumberCtrl),
                  _buildField('Subject (e.g. WARNING ORDER – NL AREA DIRECTED ACTIVITY)', subjectCtrl),
                  _buildField('Date Issued (e.g. 24 Mar 26)', dateCtrl),
                  _buildField('References (one per line)', referencesCtrl, maxLines: 4),

                  const SizedBox(height: 24),
                  _buildFormHeader('SITUATION & MISSION'),
                  _buildField('Situation Statement', situationCtrl, maxLines: 5),
                  _buildField('Mission Statement', missionCtrl, maxLines: 3),

                  const SizedBox(height: 24),
                  _buildFormHeader('EXECUTION (ADMIN INSTRUCTIONS)'),
                  _buildField('Orders / Directives', adminOrdersCtrl, maxLines: 2),
                  _buildField('Joining Instructions (JIs)', adminJIsCtrl, maxLines: 2),
                  _buildField('Participant Eligibility', participantEligibilityCtrl, maxLines: 2),
                  _buildField('Registration Details', registrationCtrl, maxLines: 2),
                  _buildField('Support Cadet Opportunities', supportCtrl, maxLines: 2),
                  _buildField('Adult Staffing Opportunities', adultStaffCtrl, maxLines: 2),
                  _buildField('Accommodation Requests', accommodationCtrl, maxLines: 2),
                  _buildField('Contingency Plans', contingencyCtrl, maxLines: 2),
                  _buildField('Lessons Learned / Safety', lessonsCtrl, maxLines: 2),
                  _buildField('Gender Based Analysis Plus (GBA+)', gbaPlusCtrl, maxLines: 2),

                  const SizedBox(height: 24),
                  _buildFormHeader('SERVICE SUPPORT'),
                  _buildField('Pay Instructions', payCtrl, maxLines: 2),
                  _buildField('Travel Guidelines', travelCtrl, maxLines: 2),
                  _buildField('Rations Plan', rationsCtrl, maxLines: 2),
                  _buildField('Lodgings Arrangements', lodgingsCtrl, maxLines: 2),
                  _buildField('Transportation Details', transportationCtrl, maxLines: 2),
                  _buildField('Equipment and Facilities', equipmentCtrl, maxLines: 2),
                  _buildField('Public Affairs Coverage', publicAffairsCtrl, maxLines: 2),
                  _buildField('Financial Authorization', financialAuthCtrl, maxLines: 2),

                  const SizedBox(height: 24),
                  _buildFormHeader('DISTRIBUTION & CONTACTS'),
                  _buildField('Distribution Action (one per line)', distActionCtrl, maxLines: 4),
                  _buildField('Distribution Info (one per line)', distInfoCtrl, maxLines: 4),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFormHeader('Contacts List'),
                      IconButton(
                        icon: const Icon(LucideIcons.plusCircle, color: Colors.amberAccent),
                        onPressed: () {
                          setState(() {
                            contacts.add({'role': '', 'name': '', 'phone': '', 'email': ''});
                          });
                        },
                      ),
                    ],
                  ),
                  ...contacts.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final contact = entry.value;
                    return Card(
                      color: Colors.white10,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Contact #${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 16),
                                  onPressed: () => setState(() => contacts.removeAt(idx)),
                                ),
                              ],
                            ),
                            TextField(
                              controller: TextEditingController(text: contact['role'])..selection = TextSelection.collapsed(offset: (contact['role'] ?? '').length),
                              decoration: const InputDecoration(labelText: 'Role (e.g. Area Trg O)'),
                              onChanged: (val) => contact['role'] = val,
                            ),
                            TextField(
                              controller: TextEditingController(text: contact['name'])..selection = TextSelection.collapsed(offset: (contact['name'] ?? '').length),
                              decoration: const InputDecoration(labelText: 'Name'),
                              onChanged: (val) => contact['name'] = val,
                            ),
                            TextField(
                              controller: TextEditingController(text: contact['phone'])..selection = TextSelection.collapsed(offset: (contact['phone'] ?? '').length),
                              decoration: const InputDecoration(labelText: 'Phone'),
                              onChanged: (val) => contact['phone'] = val,
                            ),
                            TextField(
                              controller: TextEditingController(text: contact['email'])..selection = TextSelection.collapsed(offset: (contact['email'] ?? '').length),
                              decoration: const InputDecoration(labelText: 'Email'),
                              onChanged: (val) => contact['email'] = val,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFormHeader('Serials & Schedule'),
                      IconButton(
                        icon: const Icon(LucideIcons.plusCircle, color: Colors.amberAccent),
                        onPressed: () {
                          setState(() {
                            serials.add({'serial': '', 'code': '', 'dates': '', 'location': '', 'element': '', 'units': ''});
                          });
                        },
                      ),
                    ],
                  ),
                  ...serials.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final serial = entry.value;
                    return Card(
                      color: Colors.white10,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Serial #${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 16),
                                  onPressed: () => setState(() => serials.removeAt(idx)),
                                ),
                              ],
                            ),
                            TextField(
                              controller: TextEditingController(text: serial['serial'])..selection = TextSelection.collapsed(offset: (serial['serial'] ?? '').length),
                              decoration: const InputDecoration(labelText: 'Serial No. (e.g. 1)'),
                              onChanged: (val) => serial['serial'] = val,
                            ),
                            TextField(
                              controller: TextEditingController(text: serial['code'])..selection = TextSelection.collapsed(offset: (serial['code'] ?? '').length),
                              decoration: const InputDecoration(labelText: 'Code / Name'),
                              onChanged: (val) => serial['code'] = val,
                            ),
                            TextField(
                              controller: TextEditingController(text: serial['dates'])..selection = TextSelection.collapsed(offset: (serial['dates'] ?? '').length),
                              decoration: const InputDecoration(labelText: 'Dates'),
                              onChanged: (val) => serial['dates'] = val,
                            ),
                            TextField(
                              controller: TextEditingController(text: serial['location'])..selection = TextSelection.collapsed(offset: (serial['location'] ?? '').length),
                              decoration: const InputDecoration(labelText: 'Location'),
                              onChanged: (val) => serial['location'] = val,
                            ),
                            TextField(
                              controller: TextEditingController(text: serial['element'])..selection = TextSelection.collapsed(offset: (serial['element'] ?? '').length),
                              decoration: const InputDecoration(labelText: 'Element (e.g. Sea / Army / Air)'),
                              onChanged: (val) => serial['element'] = val,
                            ),
                            TextField(
                              controller: TextEditingController(text: serial['units'])..selection = TextSelection.collapsed(offset: (serial['units'] ?? '').length),
                              decoration: const InputDecoration(labelText: 'Units / Corps Assigned'),
                              onChanged: (val) => serial['units'] = val,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openOperationOrderForm(BuildContext context, String corpsId, OperationOrder? existing) {
    final isNew = existing == null;

    final fileNumberCtrl = TextEditingController(text: isNew ? '1085-3-5 (ADA OIC)' : existing.fileNumber);
    final subjectCtrl = TextEditingController(text: isNew ? '' : existing.subject);
    final dateCtrl = TextEditingController(text: isNew ? '' : existing.date);
    final referencesCtrl = TextEditingController(text: isNew ? '' : existing.references.join('\n'));
    final situationCtrl = TextEditingController(text: isNew ? '' : existing.situation);
    final missionCtrl = TextEditingController(text: isNew ? '' : existing.mission);

    // Concept of Ops
    final cmdIntentCtrl = TextEditingController(text: isNew ? '' : existing.conceptCommandIntent);
    final schemeCtrl = TextEditingController(text: isNew ? '' : existing.conceptSchemeOfManeuver);
    final outlineCtrl = TextEditingController(text: isNew ? '' : existing.conceptGeneralOutline);
    final endStateCtrl = TextEditingController(text: isNew ? '' : existing.conceptEndState);

    // Coordinating Instructions / Execution
    final contingencyCtrl = TextEditingController(text: isNew ? '' : existing.contingencyPlan);
    final groupingsCtrl = TextEditingController(text: isNew ? '' : existing.groupings);
    final taskingsCtrl = TextEditingController(text: isNew ? '' : existing.taskings);
    final adminOrdersCtrl = TextEditingController(text: isNew ? '' : existing.adminOrders);
    final participantEligibilityCtrl = TextEditingController(text: isNew ? '' : existing.participantEligibility);
    final registrationCtrl = TextEditingController(text: isNew ? '' : existing.registrationOfParticipants);
    final supportCtrl = TextEditingController(text: isNew ? '' : existing.supportCadetEligibility);
    final adultStaffCtrl = TextEditingController(text: isNew ? '' : existing.adultStaffingOpportunities);
    final lessonsCtrl = TextEditingController(text: isNew ? '' : existing.lessonsLearned);
    final dressCtrl = TextEditingController(text: isNew ? '' : existing.dress);
    final medicalCtrl = TextEditingController(text: isNew ? '' : existing.medicalEmergency);
    final conductCtrl = TextEditingController(text: isNew ? '' : existing.conductDiscipline);
    final gbaPlusCtrl = TextEditingController(text: isNew ? '' : existing.gbaPlus);

    // Service Support
    final payCtrl = TextEditingController(text: isNew ? '' : existing.pay);
    final lodgingsCtrl = TextEditingController(text: isNew ? '' : existing.lodgings);
    final transportationCtrl = TextEditingController(text: isNew ? '' : existing.transportation);
    final rationsCtrl = TextEditingController(text: isNew ? '' : existing.rations);
    final accommodationCtrl = TextEditingController(text: isNew ? '' : existing.requestForAccommodation);
    final equipmentCtrl = TextEditingController(text: isNew ? '' : existing.equipment);
    final itCtrl = TextEditingController(text: isNew ? '' : existing.informationTechnology);
    final travelClaimsCtrl = TextEditingController(text: isNew ? '' : existing.travelClaims);
    final publicAffairsCtrl = TextEditingController(text: isNew ? '' : existing.publicAffairs);

    // Command & Signals
    final emergencyCommsCtrl = TextEditingController(text: isNew ? '' : existing.emergencyCommunications);

    final annexesCtrl = TextEditingController(
      text: isNew 
        ? '' 
        : existing.annexes.join('\n')
    );

    final distActionCtrl = TextEditingController(text: isNew ? '' : existing.distributionAction.join('\n'));
    final distInfoCtrl = TextEditingController(text: isNew ? '' : existing.distributionInfo.join('\n'));

    List<Map<String, String>> serials = isNew ? [] : List<Map<String, String>>.from(existing.serials);
    List<Map<String, String>> contacts = isNew ? [] : List<Map<String, String>>.from(existing.contacts);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog.fullscreen(
          backgroundColor: const Color(0xFF151515),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.black,
              title: Text(isNew ? 'New Operation Order' : 'Edit Operation Order'),
              actions: [
                TextButton(
                  onPressed: () async {
                    final data = {
                      'parentWarningOrderId': existing?.parentWarningOrderId,
                      'fileNumber': fileNumberCtrl.text,
                      'subject': subjectCtrl.text,
                      'date': dateCtrl.text,
                      'references': referencesCtrl.text.split('\n').where((s) => s.trim().isNotEmpty).toList(),
                      'situation': situationCtrl.text,
                      'mission': missionCtrl.text,
                      'conceptCommandIntent': cmdIntentCtrl.text,
                      'conceptSchemeOfManeuver': schemeCtrl.text,
                      'conceptGeneralOutline': outlineCtrl.text,
                      'conceptEndState': endStateCtrl.text,
                      'contingencyPlan': contingencyCtrl.text,
                      'groupings': groupingsCtrl.text,
                      'taskings': taskingsCtrl.text,
                      'adminOrders': adminOrdersCtrl.text,
                      'participantEligibility': participantEligibilityCtrl.text,
                      'registrationOfParticipants': registrationCtrl.text,
                      'supportCadetEligibility': supportCtrl.text,
                      'adultStaffingOpportunities': adultStaffCtrl.text,
                      'lessonsLearned': lessonsCtrl.text,
                      'dress': dressCtrl.text,
                      'medicalEmergency': medicalCtrl.text,
                      'conductDiscipline': conductCtrl.text,
                      'gbaPlus': gbaPlusCtrl.text,
                      'pay': payCtrl.text,
                      'lodgings': lodgingsCtrl.text,
                      'transportation': transportationCtrl.text,
                      'rations': rationsCtrl.text,
                      'requestForAccommodation': accommodationCtrl.text,
                      'equipment': equipmentCtrl.text,
                      'informationTechnology': itCtrl.text,
                      'travelClaims': travelClaimsCtrl.text,
                      'publicAffairs': publicAffairsCtrl.text,
                      'emergencyCommunications': emergencyCommsCtrl.text,
                      'annexes': annexesCtrl.text.split('\n').where((s) => s.trim().isNotEmpty).toList(),
                      'distributionAction': distActionCtrl.text.split('\n').where((s) => s.trim().isNotEmpty).toList(),
                      'distributionInfo': distInfoCtrl.text.split('\n').where((s) => s.trim().isNotEmpty).toList(),
                      'serials': serials,
                      'contacts': contacts,
                    };

                    if (isNew) {
                      await FirebaseFirestore.instance
                          .collection('corps')
                          .doc(corpsId)
                          .collection('operation_orders')
                          .add(data);
                    } else {
                      await FirebaseFirestore.instance
                          .collection('corps')
                          .doc(corpsId)
                          .collection('operation_orders')
                          .doc(existing.id)
                          .update(data);
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isNew ? 'Operation Order created.' : 'Operation Order updated.')),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('SAVE', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                ),
                IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormHeader('General details'),
                  _buildField('File Number', fileNumberCtrl),
                  _buildField('Subject (e.g. OPERATION ORDER – NL AREA DIRECTED ACTIVITY)', subjectCtrl),
                  _buildField('Date Issued', dateCtrl),
                  _buildField('References (one per line)', referencesCtrl, maxLines: 4),

                  const SizedBox(height: 24),
                  _buildFormHeader('SITUATION & MISSION'),
                  _buildField('Situation Statement', situationCtrl, maxLines: 5),
                  _buildField('Mission Statement', missionCtrl, maxLines: 3),

                  const SizedBox(height: 24),
                  _buildFormHeader('EXECUTION (CONCEPT OF OPERATIONS)'),
                  _buildField('Command Intent', cmdIntentCtrl, maxLines: 3),
                  _buildField('Scheme of Maneuver', schemeCtrl, maxLines: 3),
                  _buildField('General Outline', outlineCtrl, maxLines: 4),
                  _buildField('End State', endStateCtrl, maxLines: 3),

                  const SizedBox(height: 24),
                  _buildFormHeader('EXECUTION (COORDINATION)'),
                  _buildField('Contingency Plan', contingencyCtrl, maxLines: 2),
                  _buildField('Groupings / Formations', groupingsCtrl, maxLines: 2),
                  _buildField('Taskings / Assignments', taskingsCtrl, maxLines: 4),

                  const SizedBox(height: 24),
                  _buildFormHeader('EXECUTION (COORDINATING INSTRUCTIONS)'),
                  _buildField('Orders / Directives', adminOrdersCtrl, maxLines: 2),
                  _buildField('Participant Eligibility', participantEligibilityCtrl, maxLines: 2),
                  _buildField('Registration Details', registrationCtrl, maxLines: 2),
                  _buildField('Support Cadet Eligibility', supportCtrl, maxLines: 2),
                  _buildField('Adult Staffing Opportunities', adultStaffCtrl, maxLines: 2),
                  _buildField('Lessons Learned / Safety', lessonsCtrl, maxLines: 2),
                  _buildField('Dress / Kit list', dressCtrl, maxLines: 3),
                  _buildField('Medical & Emergency Plan', medicalCtrl, maxLines: 3),
                  _buildField('Conduct & Discipline', conductCtrl, maxLines: 2),
                  _buildField('Gender Based Analysis Plus (GBA+)', gbaPlusCtrl, maxLines: 2),

                  const SizedBox(height: 24),
                  _buildFormHeader('SERVICE SUPPORT'),
                  _buildField('Pay Instructions', payCtrl, maxLines: 2),
                  _buildField('Lodgings Arrangements', lodgingsCtrl, maxLines: 2),
                  _buildField('Transportation Details', transportationCtrl, maxLines: 2),
                  _buildField('Rations Plan', rationsCtrl, maxLines: 2),
                  _buildField('Accommodation Requests', accommodationCtrl, maxLines: 2),
                  _buildField('Equipment and Facilities Support', equipmentCtrl, maxLines: 2),
                  _buildField('Information Technology / Comms', itCtrl, maxLines: 2),
                  _buildField('Travel Claims', travelClaimsCtrl, maxLines: 2),
                  _buildField('Public Affairs Communications', publicAffairsCtrl, maxLines: 2),

                  const SizedBox(height: 24),
                  _buildFormHeader('COMMAND & SIGNALS'),
                  _buildField('Emergency Communications Plan', emergencyCommsCtrl, maxLines: 2),
                  _buildField('Annexes list (one per line)', annexesCtrl, maxLines: 6),
                  _buildField('Distribution Action (one per line)', distActionCtrl, maxLines: 4),
                  _buildField('Distribution Info (one per line)', distInfoCtrl, maxLines: 4),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFormHeader('Contacts List'),
                      IconButton(
                        icon: const Icon(LucideIcons.plusCircle, color: Colors.greenAccent),
                        onPressed: () {
                          setState(() {
                            contacts.add({'role': '', 'name': '', 'phone': '', 'email': ''});
                          });
                        },
                      ),
                    ],
                  ),
                  ...contacts.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final contact = entry.value;
                    return Card(
                      color: Colors.white10,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Contact #${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 16),
                                  onPressed: () => setState(() => contacts.removeAt(idx)),
                                ),
                              ],
                            ),
                            TextField(
                              controller: TextEditingController(text: contact['role'])..selection = TextSelection.collapsed(offset: (contact['role'] ?? '').length),
                              decoration: const InputDecoration(labelText: 'Role (e.g. OIC)'),
                              onChanged: (val) => contact['role'] = val,
                            ),
                            TextField(
                              controller: TextEditingController(text: contact['name'])..selection = TextSelection.collapsed(offset: (contact['name'] ?? '').length),
                              decoration: const InputDecoration(labelText: 'Name'),
                              onChanged: (val) => contact['name'] = val,
                            ),
                            TextField(
                              controller: TextEditingController(text: contact['phone'])..selection = TextSelection.collapsed(offset: (contact['phone'] ?? '').length),
                              decoration: const InputDecoration(labelText: 'Phone'),
                              onChanged: (val) => contact['phone'] = val,
                            ),
                            TextField(
                              controller: TextEditingController(text: contact['email'])..selection = TextSelection.collapsed(offset: (contact['email'] ?? '').length),
                              decoration: const InputDecoration(labelText: 'Email'),
                              onChanged: (val) => contact['email'] = val,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFormHeader('Serials & Schedule'),
                      IconButton(
                        icon: const Icon(LucideIcons.plusCircle, color: Colors.greenAccent),
                        onPressed: () {
                          setState(() {
                            serials.add({'serial': '', 'code': '', 'dates': '', 'location': '', 'element': '', 'units': ''});
                          });
                        },
                      ),
                    ],
                  ),
                  ...serials.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final serial = entry.value;
                    return Card(
                      color: Colors.white10,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Serial #${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 16),
                                  onPressed: () => setState(() => serials.removeAt(idx)),
                                ),
                              ],
                            ),
                            TextField(
                              controller: TextEditingController(text: serial['serial'])..selection = TextSelection.collapsed(offset: (serial['serial'] ?? '').length),
                              decoration: const InputDecoration(labelText: 'Serial No. (e.g. 1)'),
                              onChanged: (val) => serial['serial'] = val,
                            ),
                            TextField(
                              controller: TextEditingController(text: serial['code'])..selection = TextSelection.collapsed(offset: (serial['code'] ?? '').length),
                              decoration: const InputDecoration(labelText: 'Code / Name'),
                              onChanged: (val) => serial['code'] = val,
                            ),
                            TextField(
                              controller: TextEditingController(text: serial['dates'])..selection = TextSelection.collapsed(offset: (serial['dates'] ?? '').length),
                              decoration: const InputDecoration(labelText: 'Dates'),
                              onChanged: (val) => serial['dates'] = val,
                            ),
                            TextField(
                              controller: TextEditingController(text: serial['location'])..selection = TextSelection.collapsed(offset: (serial['location'] ?? '').length),
                              decoration: const InputDecoration(labelText: 'Location'),
                              onChanged: (val) => serial['location'] = val,
                            ),
                            TextField(
                              controller: TextEditingController(text: serial['element'])..selection = TextSelection.collapsed(offset: (serial['element'] ?? '').length),
                              decoration: const InputDecoration(labelText: 'Element (e.g. Sea / Army / Air)'),
                              onChanged: (val) => serial['element'] = val,
                            ),
                            TextField(
                              controller: TextEditingController(text: serial['units'])..selection = TextSelection.collapsed(offset: (serial['units'] ?? '').length),
                              decoration: const InputDecoration(labelText: 'Units / Corps Assigned'),
                              onChanged: (val) => serial['units'] = val,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white54, fontSize: 13, letterSpacing: 1.1),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white30, fontSize: 13),
          alignLabelWithHint: true,
        ),
      ),
    );
  }
}

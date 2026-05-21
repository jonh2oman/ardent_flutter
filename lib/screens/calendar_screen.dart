import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/calendar.dart';
import '../data/curriculum.dart';
import 'attendance_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _showRoadmap = false;
  String _viewMode = 'list'; // 'list', 'kanban', 'grid'
  DateTime _gridMonth = DateTime.now();
  String _selectedYearKey = 'current';

  @override
  void initState() {
    super.initState();
    // Auto-show roadmap if calendar is empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final calendar = auth.corpsData?.trainingYears[_selectedYearKey]?['calendar'] ?? {};
      if (calendar.isEmpty) {
        setState(() => _showRoadmap = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    
    // Get calendar data from Firestore
    final Map<String, dynamic> trainingYear = authProvider.corpsData?.trainingYears[_selectedYearKey] ?? {};
    final calendarMap = Map<String, dynamic>.from(trainingYear['calendar'] ?? {});
    final String mode = trainingYear['mode'] ?? 'Academic'; // Academic vs Full Year
    
    // Determine which dates to show based on view mode
    final List<String> displayDates = calendarMap.keys.where((k) {
      if (_viewMode == 'list') {
        final date = DateTime.parse(k);
        return date.isAfter(DateTime.now().subtract(const Duration(days: 1)));
      }
      return true; // Show all for Kanban/Grid
    }).toList()..sort();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TRAINING CALENDAR (${mode.toUpperCase()} MODE)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _viewMode == 'list' ? 'Upcoming Schedule' : 'Yearly Overview',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.0),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildYearSelector(authProvider, theme),
                    const SizedBox(width: 16),
                    if (_selectedYearKey != 'current')
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: TextButton.icon(
                          onPressed: () => _setAsActiveYear(authProvider),
                          icon: const Icon(LucideIcons.checkCircle, size: 18),
                          label: const Text('SET AS ACTIVE YEAR'),
                          style: TextButton.styleFrom(foregroundColor: Colors.greenAccent),
                        ),
                      ),
                    _buildViewSwitcher(),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: () => setState(() => _showRoadmap = !_showRoadmap),
                      icon: Icon(_showRoadmap ? LucideIcons.chevronUp : LucideIcons.map, size: 18),
                      label: Text(_showRoadmap ? 'HIDE ROADMAP' : 'SETUP ROADMAP'),
                      style: TextButton.styleFrom(foregroundColor: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 8),
                    _buildModeToggle(authProvider, mode),
                  ],
                ),
              ],
            ),
          ),

          if (_showRoadmap) _buildSetupRoadmap(authProvider, theme),

          Expanded(
            child: displayDates.isEmpty 
              ? _buildEmptyState(theme)
              : _buildMainView(context, theme, displayDates, calendarMap),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(context, authProvider),
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  Widget _buildModeToggle(AuthProvider auth, String currentMode) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _ModeButton(
            label: 'Academic',
            isActive: currentMode == 'Academic',
            onTap: () => _updateCalendarMode(auth, 'Academic'),
          ),
          _ModeButton(
            label: 'Full Year',
            isActive: currentMode == 'Full Year',
            onTap: () => _updateCalendarMode(auth, 'Full Year'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCalendarMode(AuthProvider auth, String mode) async {
    final corpsId = auth.userData?.corpsId;
    if (corpsId == null) return;
    await FirebaseFirestore.instance.collection('corps').doc(corpsId).update({
      'trainingYears.${_selectedYearKey}.mode': mode,
    });
  }

  Widget _buildSetupRoadmap(AuthProvider auth, ThemeData theme) {
    final calendar = auth.corpsData?.trainingYears[_selectedYearKey]?['calendar'] ?? {};
    final hasDates = calendar.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.map, color: Colors.amberAccent, size: 20),
              SizedBox(width: 12),
              Text('INITIAL SETUP ROADMAP', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _RoadmapStep(
                title: 'Initialize Dates',
                subtitle: hasDates ? 'Calendar generated' : 'Create parade nights',
                isComplete: hasDates,
                icon: LucideIcons.calendarPlus,
                onTap: () => _showBatchInitDialog(context, auth),
              ),
              _RoadmapDivider(),
              _RoadmapStep(
                title: 'Assign Lessons',
                subtitle: 'Map curriculum',
                isComplete: false, // Placeholder check
                icon: LucideIcons.bookOpen,
                onTap: () {},
              ),
              _RoadmapDivider(),
              _RoadmapStep(
                title: 'Verify Roster',
                subtitle: 'Assign phases',
                isComplete: (auth.corpsData?.settings['cadets'] as List?)?.isNotEmpty ?? false,
                icon: LucideIcons.users,
                onTap: () {},
              ),
              _RoadmapDivider(),
              _RoadmapStep(
                title: 'Auto-Plan',
                subtitle: 'Smart mapping',
                isComplete: false,
                icon: LucideIcons.zap,
                isExperimental: true,
                onTap: () => _runAutoPlan(context, auth),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBatchInitDialog(BuildContext context, AuthProvider auth) {
    final mode = auth.corpsData?.trainingYears[_selectedYearKey]?['mode'] ?? 'Academic';
    
    DateTime startDate;
    DateTime endDate;
    
    if (mode == 'Academic') {
      // Sept to June
      int startYear = DateTime.now().month >= 9 ? DateTime.now().year : DateTime.now().year - 1;
      startDate = DateTime(startYear, 9, 1);
      endDate = DateTime(startYear + 1, 6, 30);
    } else {
      // Jan to Dec
      startDate = DateTime(DateTime.now().year, 1, 1);
      endDate = DateTime(DateTime.now().year, 12, 31);
    }
    
    int dayOfWeek = 2; // Tuesday

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Batch Initialize ($mode Mode)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Initialize LHQ nights between these dates:', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('START', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      subtitle: Text(DateFormat('MMM d, yyyy').format(startDate)),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setDialogState(() => startDate = picked);
                      },
                    ),
                  ),
                  const Icon(LucideIcons.arrowRight, size: 16, color: Colors.white10),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('END', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.end),
                      subtitle: Text(DateFormat('MMM d, yyyy').format(endDate), textAlign: TextAlign.end),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setDialogState(() => endDate = picked);
                      },
                    ),
                  ),
                ],
              ),
              const Divider(height: 32, color: Colors.white10),
              DropdownButtonFormField<int>(
                value: [1, 2, 3, 4, 5].contains(dayOfWeek) ? dayOfWeek : 2,
                items: [
                  const DropdownMenuItem(value: 1, child: Text('Monday')),
                  const DropdownMenuItem(value: 2, child: Text('Tuesday')),
                  const DropdownMenuItem(value: 3, child: Text('Wednesday')),
                  const DropdownMenuItem(value: 4, child: Text('Thursday')),
                  const DropdownMenuItem(value: 5, child: Text('Friday')),
                ],
                onChanged: (val) => setDialogState(() => dayOfWeek = val!),
                decoration: const InputDecoration(labelText: 'Weekly Parade Night'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                await _batchInitCalendar(auth, startDate, endDate, dayOfWeek);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('GENERATE CALENDAR'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _batchInitCalendar(AuthProvider auth, DateTime start, DateTime end, int dayOfWeek) async {
    final corpsId = auth.userData?.corpsId;
    if (corpsId == null) return;

    final Map<String, dynamic> calendar = {};
    DateTime current = start;
    
    // Find first day of week
    while (current.weekday != dayOfWeek) {
      current = current.add(const Duration(days: 1));
    }

    while (current.isBefore(end)) {
      final dateKey = DateFormat('yyyy-MM-dd').format(current);
      calendar[dateKey] = {
        'type': 'lhq',
        'title': 'Training Night',
        'periods': {'1': {}, '2': {}, '3': {}},
      };
      current = current.add(const Duration(days: 7));
    }

    await FirebaseFirestore.instance.collection('corps').doc(corpsId).update({
      'trainingYears.${_selectedYearKey}.calendar': calendar,
    });
  }

  Future<void> _showAddEventDialog(BuildContext context, AuthProvider auth) async {
    DateTime selectedDate = DateTime.now();
    String selectedType = 'lhq';
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Training Event', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(DateFormat('EEEE, MMM d, yyyy').format(selectedDate)),
                trailing: const Icon(LucideIcons.calendar),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setDialogState(() => selectedDate = picked);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                items: [
                  const DropdownMenuItem(value: 'lhq', child: Text('LHQ Night')),
                  const DropdownMenuItem(value: 'training-day', child: Text('Training Day')),
                  const DropdownMenuItem(value: 'weekend', child: Text('Weekend Session')),
                  const DropdownMenuItem(value: 'other', child: Text('Special Event')),
                ],
                onChanged: (val) => setDialogState(() => selectedType = val!),
                decoration: const InputDecoration(labelText: 'Event Type'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                await _createNewEvent(selectedDate, auth, type: selectedType);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('ADD TO CALENDAR'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runAutoPlan(BuildContext context, AuthProvider auth) async {
    final corpsId = auth.userData?.corpsId;
    if (corpsId == null) return;

    final Map<String, dynamic> trainingYear = auth.corpsData?.trainingYears[_selectedYearKey] ?? {};
    final Map<String, dynamic> calendar = Map<String, dynamic>.from(trainingYear['calendar'] ?? {});
    
    // Sort dates to ensure we plan chronologically
    final sortedDates = calendar.keys.where((k) => calendar[k]['type'] == 'lhq').toList()..sort();
    
    if (sortedDates.isEmpty) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No LHQ nights found. Initialize dates first!')));
      return;
    }

    // Pre-load curriculum for each phase
    final Map<String, List<Map<String, dynamic>>> phaseEos = {
      "Phase 1": Curriculum.getPhaseEOs("Phase 1").where((eo) => eo['type'] == 'M').toList(),
      "Phase 2": Curriculum.getPhaseEOs("Phase 2").where((eo) => eo['type'] == 'M').toList(),
      "Phase 3": Curriculum.getPhaseEOs("Phase 3").where((eo) => eo['type'] == 'M').toList(),
      "Phase 4": Curriculum.getPhaseEOs("Phase 4").where((eo) => eo['type'] == 'M').toList(),
    };

    // Track progress for each phase
    final Map<String, int> lessonPointers = {"Phase 1": 0, "Phase 2": 0, "Phase 3": 0, "Phase 4": 0};
    final Map<String, int> carryOverPeriods = {"Phase 1": 0, "Phase 2": 0, "Phase 3": 0, "Phase 4": 0};
    final Map<String, String?> currentLessons = {"Phase 1": null, "Phase 2": null, "Phase 3": null, "Phase 4": null};

    for (var dateKey in sortedDates) {
      final dayData = Map<String, dynamic>.from(calendar[dateKey]);
      final periods = Map<String, dynamic>.from(dayData['periods'] ?? {});

      for (int p = 1; p <= 3; p++) {
        final pKey = p.toString();
        final pData = Map<String, dynamic>.from(periods[pKey] ?? {});

        for (var phase in phaseEos.keys) {
          // If we are carrying over a multi-period lesson
          if (carryOverPeriods[phase]! > 0) {
            pData[phase] = {
              'lessonId': currentLessons[phase],
              'instructor': 'TBD',
              'location': 'TBD',
            };
            carryOverPeriods[phase] = carryOverPeriods[phase]! - 1;
          } else {
            // Get next lesson
            final idx = lessonPointers[phase]!;
            if (idx < phaseEos[phase]!.length) {
              final lesson = phaseEos[phase]![idx];
              final duration = (lesson['periods'] as num).toInt();
              
              currentLessons[phase] = lesson['id'];
              pData[phase] = {
                'lessonId': lesson['id'],
                'instructor': 'TBD',
                'location': 'TBD',
              };
              
              lessonPointers[phase] = idx + 1;
              if (duration > 1) {
                carryOverPeriods[phase] = duration - 1;
              }
            }
          }
        }
        periods[pKey] = pData;
      }
      dayData['periods'] = periods;
      calendar[dateKey] = dayData;
    }

    await FirebaseFirestore.instance.collection('corps').doc(corpsId).update({
      'trainingYears.${_selectedYearKey}.calendar': calendar,
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Auto-Plan Complete! Curriculum distributed.')));
    }
  }

  Future<void> _createNewEvent(DateTime date, AuthProvider auth, {String type = 'lhq'}) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final corpsId = auth.userData?.corpsId;
    if (corpsId == null) return;

    final Map<String, dynamic> trainingYear = auth.corpsData?.trainingYears[_selectedYearKey] ?? {};
    final Map<String, dynamic> calendar = Map<String, dynamic>.from(trainingYear['calendar'] ?? {});
    
    calendar[dateKey] = {
      'type': type,
      'title': type == 'lhq' ? 'Training Night' : 'Training Event',
      'periods': {'1': {}, '2': {}, '3': {}},
    };

    await FirebaseFirestore.instance.collection('corps').doc(corpsId).update({
      'trainingYears.${_selectedYearKey}.calendar': calendar,
    });
  }


  Widget _buildYearSelector(AuthProvider auth, ThemeData theme) {
    final Map<String, dynamic> trainingYears = auth.corpsData?.trainingYears ?? {};
    final keys = trainingYears.keys.toList()..sort();
    if (!keys.contains('current')) keys.insert(0, 'current');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedYearKey,
          icon: const Icon(LucideIcons.chevronDown, size: 16),
          isDense: true,
          dropdownColor: theme.colorScheme.surface,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
          items: [
            ...keys.map((k) => DropdownMenuItem(value: k, child: Text(k == 'current' ? 'Current Year' : k))),
            const DropdownMenuItem(value: 'ADD_NEW', child: Text('Add New Year...', style: TextStyle(color: Colors.amber))),
            const DropdownMenuItem(value: 'DUPLICATE', child: Text('Duplicate & Shift Year...', style: TextStyle(color: Colors.cyanAccent))),
          ],
          onChanged: (val) {
            if (val == 'ADD_NEW') {
              _showAddNewYearDialog(auth);
            } else if (val == 'DUPLICATE') {
              _showDuplicateYearDialog(auth);
            } else if (val != null) {
              setState(() => _selectedYearKey = val);
            }
          },
        ),
      ),
    );
  }

  void _showAddNewYearDialog(AuthProvider auth) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Training Year'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Year Name (e.g. 2024-2025)'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final val = controller.text.trim();
              if (val.isNotEmpty && val.toLowerCase() != 'current') {
                await _addNewTrainingYear(auth, val);
                if (context.mounted) {
                  Navigator.pop(context);
                  setState(() => _selectedYearKey = val);
                }
              }
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }

  Future<void> _addNewTrainingYear(AuthProvider auth, String yearKey) async {
    final corpsId = auth.userData?.corpsId;
    if (corpsId == null) return;
    await FirebaseFirestore.instance.collection('corps').doc(corpsId).update({
      'trainingYears.${yearKey}': {
        'mode': 'Academic',
        'calendar': {},
      },
    });
  }

  void _showDuplicateYearDialog(AuthProvider auth) {
    final nameController = TextEditingController();
    DateTime startDate = DateTime(DateTime.now().year, 9, 1);
    DateTime endDate = DateTime(DateTime.now().year + 1, 6, 30);
    int dayOfWeek = 2; // Tuesday
    String sourceYearKey = _selectedYearKey;

    final trainingYears = auth.corpsData?.trainingYears ?? {};
    final keys = trainingYears.keys.toList()..sort();
    if (!keys.contains('current')) keys.insert(0, 'current');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Duplicate & Shift Year'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'New Year Name (e.g. 2025-2026)'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: sourceYearKey,
                  decoration: const InputDecoration(labelText: 'Source Year to Copy'),
                  items: keys.map((k) => DropdownMenuItem(value: k, child: Text(k == 'current' ? 'Current Year' : k))).toList(),
                  onChanged: (val) => setDialogState(() => sourceYearKey = val!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: dayOfWeek,
                  decoration: const InputDecoration(labelText: 'New Parade Day'),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Monday')),
                    DropdownMenuItem(value: 2, child: Text('Tuesday')),
                    DropdownMenuItem(value: 3, child: Text('Wednesday')),
                    DropdownMenuItem(value: 4, child: Text('Thursday')),
                    DropdownMenuItem(value: 5, child: Text('Friday')),
                    DropdownMenuItem(value: 6, child: Text('Saturday')),
                    DropdownMenuItem(value: 7, child: Text('Sunday')),
                  ],
                  onChanged: (val) => setDialogState(() => dayOfWeek = val!),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('START DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        subtitle: Text(DateFormat('MMM d, yyyy').format(startDate)),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setDialogState(() => startDate = picked);
                        },
                      ),
                    ),
                    const Icon(LucideIcons.arrowRight, size: 16, color: Colors.white10),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('END DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.end),
                        subtitle: Text(DateFormat('MMM d, yyyy').format(endDate), textAlign: TextAlign.end),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setDialogState(() => endDate = picked);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Note: This will only carry over weekly LHQ training nights in chronological order.', style: TextStyle(fontSize: 12, color: Colors.amber.withValues(alpha: 0.8))),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                final val = nameController.text.trim();
                if (val.isNotEmpty && val.toLowerCase() != 'current') {
                  await _duplicateAndShiftYear(auth, sourceYearKey, val, startDate, endDate, dayOfWeek);
                  if (context.mounted) {
                    Navigator.pop(context);
                    setState(() => _selectedYearKey = val);
                  }
                }
              },
              child: const Text('DUPLICATE & SHIFT'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _duplicateAndShiftYear(AuthProvider auth, String sourceKey, String destKey, DateTime start, DateTime end, int dayOfWeek) async {
    final corpsId = auth.userData?.corpsId;
    if (corpsId == null) return;

    final sourceYear = auth.corpsData?.trainingYears[sourceKey] ?? {};
    final sourceCalendar = Map<String, dynamic>.from(sourceYear['calendar'] ?? {});
    final sourceMode = sourceYear['mode'] ?? 'Academic';

    // Extract sorted LHQ dates from source
    final sourceDates = sourceCalendar.keys.where((k) => sourceCalendar[k]['type'] == 'lhq').toList()..sort();

    final Map<String, dynamic> newCalendar = {};
    DateTime current = start;
    
    // Find first day of week
    while (current.weekday != dayOfWeek) {
      current = current.add(const Duration(days: 1));
    }

    int i = 0;
    while (current.isBefore(end)) {
      final dateKey = DateFormat('yyyy-MM-dd').format(current);
      if (i < sourceDates.length) {
        // Copy data from corresponding old week
        final oldData = Map<String, dynamic>.from(sourceCalendar[sourceDates[i]]);
        newCalendar[dateKey] = oldData; // Copies type, title, and periods
      } else {
        // Run out of old curriculum, just create empty night
        newCalendar[dateKey] = {
          'type': 'lhq',
          'title': 'Training Night',
          'periods': {'1': {}, '2': {}, '3': {}},
        };
      }
      current = current.add(const Duration(days: 7));
      i++;
    }

    await FirebaseFirestore.instance.collection('corps').doc(corpsId).update({
      'trainingYears.${destKey}': {
        'mode': sourceMode,
        'calendar': newCalendar,
      },
    });
  }


  Future<void> _setAsActiveYear(AuthProvider auth) async {
    final corpsId = auth.userData?.corpsId;
    if (corpsId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set as Active Year?'),
        content: const Text('This will overwrite the "Current Year" calendar with the data from this selected year. This action affects the entire app.\\n\\nAre you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('PUBLISH TO CURRENT', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final data = auth.corpsData?.trainingYears[_selectedYearKey] ?? {};
      await FirebaseFirestore.instance.collection('corps').doc(corpsId).update({
        'trainingYears.current': data,
      });
      if (context.mounted) {
        setState(() => _selectedYearKey = 'current');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Successfully published to Current Year!')));
      }
    }
  }

  Widget _buildViewSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _ViewButton(
            icon: LucideIcons.list,
            isActive: _viewMode == 'list',
            onTap: () => setState(() => _viewMode = 'list'),
          ),
          _ViewButton(
            icon: LucideIcons.columns,
            isActive: _viewMode == 'kanban',
            onTap: () => setState(() => _viewMode = 'kanban'),
          ),
          _ViewButton(
            icon: LucideIcons.calendar,
            isActive: _viewMode == 'grid',
            onTap: () => setState(() => _viewMode = 'grid'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainView(BuildContext context, ThemeData theme, List<String> upcomingDates, Map<String, dynamic> calendarMap) {
    switch (_viewMode) {
      case 'kanban':
        return _buildKanbanView(context, theme, upcomingDates, calendarMap);
      case 'grid':
        return _buildGridView(context, theme, upcomingDates, calendarMap);
      default:
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          itemCount: upcomingDates.length,
          itemBuilder: (context, index) {
            final dateStr = upcomingDates[index];
            final dayData = ParadeDay.fromMap(dateStr, calendarMap[dateStr]);
            return _buildCalendarCard(context, theme, dayData);
          },
        );
    }
  }

  Widget _buildKanbanView(BuildContext context, ThemeData theme, List<String> dates, Map<String, dynamic> calendarMap) {
    // Group dates by Month
    final Map<String, List<String>> months = {};
    for (var dateStr in dates) {
      final date = DateTime.parse(dateStr);
      final monthKey = DateFormat('MMMM yyyy').format(date);
      months.putIfAbsent(monthKey, () => []).add(dateStr);
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      itemCount: months.length,
      itemBuilder: (context, index) {
        final monthKey = months.keys.elementAt(index);
        final monthDates = months[monthKey]!;

        return Container(
          width: 320,
          margin: const EdgeInsets.only(right: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16, left: 4),
                child: Text(
                  monthKey.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.primary.withOpacity(0.7),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: monthDates.length,
                  itemBuilder: (context, idx) {
                    final dateStr = monthDates[idx];
                    final dayData = ParadeDay.fromMap(dateStr, calendarMap[dateStr]);
                    return _buildSmallCalendarCard(context, theme, dayData);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridView(BuildContext context, ThemeData theme, List<String> dates, Map<String, dynamic> calendarMap) {
    final firstDayOfMonth = DateTime(_gridMonth.year, _gridMonth.month, 1);
    final lastDayOfMonth = DateTime(_gridMonth.year, _gridMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startingWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_gridMonth).toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.chevronLeft, size: 20),
                    onPressed: () => setState(() => _gridMonth = DateTime(_gridMonth.year, _gridMonth.month - 1)),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.chevronRight, size: 20),
                    onPressed: () => setState(() => _gridMonth = DateTime(_gridMonth.year, _gridMonth.month + 1)),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                .map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(fontSize: 10, color: Colors.white24, fontWeight: FontWeight.bold))))).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: 42, // 6 weeks
            itemBuilder: (context, index) {
              final dayIndex = index - (startingWeekday - 1);
              if (dayIndex < 0 || dayIndex >= daysInMonth) return const SizedBox.shrink();

              final currentDay = DateTime(_gridMonth.year, _gridMonth.month, dayIndex + 1);
              final dateKey = DateFormat('yyyy-MM-dd').format(currentDay);
              final hasEvent = calendarMap.containsKey(dateKey);
              final dayData = hasEvent ? ParadeDay.fromMap(dateKey, calendarMap[dateKey]) : null;

              return InkWell(
                onTap: hasEvent ? () => _showDayDetailDialog(context, theme, dayData!) : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: hasEvent ? theme.colorScheme.primary.withOpacity(0.1) : Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasEvent ? theme.colorScheme.primary.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${dayIndex + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: hasEvent ? FontWeight.w900 : FontWeight.normal,
                          color: hasEvent ? Colors.white : Colors.white38,
                        ),
                      ),
                      if (hasEvent) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: dayData?.type == 'lhq' ? theme.colorScheme.primary : Colors.amber,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSmallCalendarCard(BuildContext context, ThemeData theme, ParadeDay day) {
    final date = DateTime.parse(day.date);
    return InkWell(
      onTap: () => _showDayDetailDialog(context, theme, day),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM d').format(date),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: day.type == 'lhq' ? theme.colorScheme.primary : Colors.amber,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              day.title.isEmpty ? 'Training' : day.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }

  void _showDayDetailDialog(BuildContext context, ThemeData theme, ParadeDay day) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: _buildCalendarCard(context, theme, day),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarCard(BuildContext context, ThemeData theme, ParadeDay day) {
    final date = DateTime.parse(day.date);
    final isLHQ = day.type == 'lhq';
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isLHQ ? theme.colorScheme.primary.withOpacity(0.1) : Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isLHQ ? 'LHQ NIGHT' : day.type.toUpperCase(),
                    style: TextStyle(
                      color: isLHQ ? theme.colorScheme.primary : Colors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  DateFormat('EEEE, MMM d').format(date),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.checkSquare, size: 18, color: Colors.white70),
                  tooltip: 'Mark Attendance',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AttendanceScreen(
                          dateId: day.date,
                          dateName: DateFormat('EEEE, MMM d').format(DateTime.parse(day.date)),
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(LucideIcons.checkCircle, size: 18, color: Colors.greenAccent),
                  tooltip: 'Finalize Night & Award Credits',
                  onPressed: () => _finalizeNight(context, auth, day),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.white30),
                  onPressed: () => _deleteEvent(day.date, auth),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (day.title.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(day.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                  ),
                _buildPeriodRow(context, theme, 'Period 1', day.periods['1'], day.date, '1', auth),
                const SizedBox(height: 12),
                _buildPeriodRow(context, theme, 'Period 2', day.periods['2'], day.date, '2', auth),
                const SizedBox(height: 12),
                _buildPeriodRow(context, theme, 'Period 3', day.periods['3'], day.date, '3', auth),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodRow(BuildContext context, ThemeData theme, String title, dynamic periodData, String dateKey, String periodKey, AuthProvider auth) {
    final Map<String, dynamic> levels = periodData != null ? Map<String, dynamic>.from(periodData) : {};
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.white30, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => _showEditPeriodDialog(context, auth, dateKey, periodKey, levels),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('EDIT', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: levels.isEmpty 
            ? const Text('No lessons assigned', style: TextStyle(fontSize: 10, color: Colors.white10))
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: levels.entries.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "${e.key}: ${e.value['lessonId'] ?? 'N/A'}",
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
        ),
      ],
    );
  }

  Future<void> _showEditPeriodDialog(BuildContext context, AuthProvider auth, String dateKey, String periodKey, Map<String, dynamic> currentLevels) async {
    final theme = Theme.of(context);
    String selectedPhase = 'Phase 1';
    final lessonController = TextEditingController();
    final instructorController = TextEditingController();
    final locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit Period $periodKey Assignments', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedPhase,
                  items: ['Phase 1', 'Phase 2', 'Phase 3', 'Phase 4', 'Phase 5'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        selectedPhase = val;
                        final current = currentLevels[val] ?? {};
                        lessonController.text = current['lessonId'] ?? '';
                        instructorController.text = current['instructor'] ?? '';
                        locationController.text = current['location'] ?? '';
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Phase/Level'),
                ),
                const SizedBox(height: 16),
                Autocomplete<Map<String, dynamic>>(
                  displayStringForOption: (option) => option['id'],
                  initialValue: TextEditingValue(text: lessonController.text),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) return const Iterable<Map<String, dynamic>>.empty();
                    return Curriculum.getPhaseEOs(selectedPhase).where((eo) {
                      return eo['id'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                             eo['title'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (Map<String, dynamic> selection) => setDialogState(() => lessonController.text = selection['id']),
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    controller.addListener(() => lessonController.text = controller.text);
                    if (controller.text.isEmpty && lessonController.text.isNotEmpty) controller.text = lessonController.text;
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Search Lesson (e.g. M108)',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(LucideIcons.search, size: 18),
                        helperText: Curriculum.findEO(selectedPhase, controller.text)?['title'] ?? 'Start typing...',
                        helperStyle: TextStyle(color: Curriculum.findEO(selectedPhase, controller.text)?['type'] == 'M' ? Colors.tealAccent : Colors.amberAccent),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(controller: instructorController, decoration: const InputDecoration(labelText: 'Instructor', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                await _updatePeriodAssignment(auth, dateKey, periodKey, selectedPhase, {
                  'lessonId': lessonController.text,
                  'instructor': instructorController.text,
                  'location': locationController.text,
                });
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePeriodAssignment(AuthProvider auth, String dateKey, String periodKey, String phase, Map<String, dynamic> data) async {
    final corpsId = auth.userData?.corpsId;
    if (corpsId == null) return;
    final Map<String, dynamic> calendar = Map<String, dynamic>.from(auth.corpsData?.trainingYears[_selectedYearKey]?['calendar'] ?? {});
    final dayData = Map<String, dynamic>.from(calendar[dateKey] ?? {});
    final periods = Map<String, dynamic>.from(dayData['periods'] ?? {});
    final periodData = Map<String, dynamic>.from(periods[periodKey] ?? {});
    periodData[phase] = data;
    periods[periodKey] = periodData;
    dayData['periods'] = periods;
    calendar[dateKey] = dayData;
    await FirebaseFirestore.instance.collection('corps').doc(corpsId).update({'trainingYears.current.calendar': calendar});
  }

  Future<void> _deleteEvent(String dateKey, AuthProvider auth) async {
    final corpsId = auth.userData?.corpsId;
    if (corpsId == null) return;
    final Map<String, dynamic> calendar = Map<String, dynamic>.from(auth.corpsData?.trainingYears[_selectedYearKey]?['calendar'] ?? {});
    calendar.remove(dateKey);
    await FirebaseFirestore.instance.collection('corps').doc(corpsId).update({'trainingYears.current.calendar': calendar});
  }

  Future<void> _finalizeNight(BuildContext context, AuthProvider auth, ParadeDay day) async {
    final corpsId = auth.userData?.corpsId;
    if (corpsId == null) return;
    final attendanceDoc = await FirebaseFirestore.instance.collection('corps').doc(corpsId).collection('attendance').doc(day.date).get();
    if (!attendanceDoc.exists) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mark attendance first!')));
      return;
    }
    final statuses = Map<String, String>.from(attendanceDoc.data()?['statuses'] ?? {});
    final List<dynamic> cadets = List.from(auth.corpsData?.settings['cadets'] ?? []);
    Map<String, Set<String>> phaseEos = {};
    day.periods.forEach((pId, pData) {
      Map<String, dynamic>.from(pData).forEach((phase, assignment) {
        if (assignment['lessonId']?.isNotEmpty == true) phaseEos.putIfAbsent(phase, () => {}).add(assignment['lessonId']);
      });
    });
    bool updated = false;
    for (var i = 0; i < cadets.length; i++) {
      final status = statuses[cadets[i]['uid']];
      if (status == 'Present' || status == 'Late') {
        final phase = cadets[i]['phase'] ?? 'Phase 1';
        final eos = phaseEos[phase] ?? {};
        if (eos.isNotEmpty) {
          final Map<String, dynamic> records = Map<String, dynamic>.from(cadets[i]['trainingRecords'] ?? {});
          final List<String> completed = List<String>.from(records[phase] ?? []);
          final initial = completed.length;
          for (var eo in eos) if (!completed.contains(eo)) completed.add(eo);
          if (completed.length > initial) {
            records[phase] = completed;
            cadets[i]['trainingRecords'] = records;
            updated = true;
          }
        }
      }
    }
    if (updated) {
      await FirebaseFirestore.instance.collection('corps').doc(corpsId).update({'settings.cadets': cadets});
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Night finalized! Progress bars updated.')));
    }
  }
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.calendarX, size: 48, color: Colors.white10),
          const SizedBox(height: 16),
          const Text('No upcoming events scheduled', style: TextStyle(color: Colors.white30)),
        ],
      ),
    );
  }
}

class _ViewButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  const _ViewButton({required this.icon, required this.isActive, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isActive ? Colors.white : Colors.white24, size: 18),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _ModeButton({required this.label, required this.isActive, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? Colors.white : Colors.white38)),
      ),
    );
  }
}

class _RoadmapStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isComplete;
  final IconData icon;
  final VoidCallback onTap;
  final bool isExperimental;

  const _RoadmapStep({
    required this.title,
    required this.subtitle,
    required this.isComplete,
    required this.icon,
    required this.onTap,
    this.isExperimental = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isComplete ? Colors.greenAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                    border: Border.all(color: isComplete ? Colors.greenAccent : Colors.white10),
                  ),
                  child: Icon(isComplete ? LucideIcons.check : icon, color: isComplete ? Colors.greenAccent : Colors.white38, size: 20),
                ),
                if (isExperimental)
                  Transform.translate(
                    offset: const Offset(10, -5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('EXPERIMENTAL', style: TextStyle(fontSize: 6, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _RoadmapDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 40, height: 1, color: Colors.white10, margin: const EdgeInsets.only(bottom: 40));
  }
}

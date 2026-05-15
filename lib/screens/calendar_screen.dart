import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/calendar.dart';
import '../data/curriculum.dart';
import 'attendance_screen.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    
    // Get calendar data from Firestore
    final Map<String, dynamic> trainingYear = authProvider.corpsData?.trainingYears['current'] ?? {};
    final Map<String, dynamic> calendarMap = trainingYear['calendar'] ?? {};
    
    // Sort dates
    final sortedDates = calendarMap.keys.toList()..sort();
    final upcomingDates = sortedDates.where((d) {
      final date = DateTime.parse(d);
      return date.isAfter(DateTime.now().subtract(const Duration(days: 1)));
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TRAINING CALENDAR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upcoming Schedule',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.0),
                ),
              ],
            ),
          ),
          Expanded(
            child: upcomingDates.isEmpty 
              ? _buildEmptyState(theme)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  itemCount: upcomingDates.length,
                  itemBuilder: (context, index) {
                    final dateStr = upcomingDates[index];
                    final dayData = ParadeDay.fromMap(dateStr, calendarMap[dateStr]);
                    return _buildCalendarCard(context, theme, dayData);
                  },
                ),
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

  Future<void> _showAddEventDialog(BuildContext context, AuthProvider auth) async {
    DateTime selectedDate = DateTime.now();
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Training Night', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setDialogState(() => selectedDate = picked);
                },
              ),
              const SizedBox(height: 16),
              Text('This will initialize a new LHQ night for all phases.', style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6))),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                await _createNewEvent(selectedDate, auth);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('INITIALIZE NIGHT'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createNewEvent(DateTime date, AuthProvider auth) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final corpsId = auth.userData?.corpsId;
    if (corpsId == null) return;

    final Map<String, dynamic> trainingYear = auth.corpsData?.trainingYears['current'] ?? {};
    final Map<String, dynamic> calendar = Map<String, dynamic>.from(trainingYear['calendar'] ?? {});
    
    // Initialize a blank LHQ night structure
    calendar[dateKey] = {
      'type': 'lhq',
      'title': 'Training Night',
      'periods': {
        '1': {},
        '2': {},
        '3': {},
      },
    };

    await FirebaseFirestore.instance.collection('corps').doc(corpsId).update({
      'trainingYears.current.calendar': calendar,
    });
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
          // Header
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
          // Content
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
    final List<String> availablePhases = ['Phase 1', 'Phase 2', 'Phase 3', 'Phase 4', 'Phase 5'];

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
                  onSelected: (Map<String, dynamic> selection) {
                    setDialogState(() {
                      lessonController.text = selection['id'];
                    });
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    // Sync the external controller if needed, but usually we just use this one
                    controller.addListener(() => lessonController.text = controller.text);
                    if (controller.text.isEmpty && lessonController.text.isNotEmpty) {
                      controller.text = lessonController.text;
                    }
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Search Lesson (e.g. M108)',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(LucideIcons.search, size: 18),
                        helperText: Curriculum.findEO(selectedPhase, controller.text)?['title'] ?? 'Start typing to search...',
                        helperStyle: TextStyle(
                          color: Curriculum.findEO(selectedPhase, controller.text)?['type'] == 'M' ? Colors.tealAccent : Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 300,
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final option = options.elementAt(index);
                              final isMandatory = option['type'] == 'M';
                              return ListTile(
                                dense: true,
                                title: Text(option['id'], style: TextStyle(fontWeight: FontWeight.bold, color: isMandatory ? Colors.tealAccent : Colors.amberAccent)),
                                subtitle: Text(option['title'], maxLines: 1, overflow: TextOverflow.ellipsis),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: instructorController,
                  decoration: const InputDecoration(labelText: 'Instructor', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
                ),
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
              child: const Text('SAVE ASSIGNMENT'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePeriodAssignment(AuthProvider auth, String dateKey, String periodKey, String phase, Map<String, dynamic> data) async {
    final corpsId = auth.userData?.corpsId;
    if (corpsId == null) return;

    final Map<String, dynamic> trainingYear = auth.corpsData?.trainingYears['current'] ?? {};
    final Map<String, dynamic> calendar = Map<String, dynamic>.from(trainingYear['calendar'] ?? {});
    
    if (calendar[dateKey] == null) return;
    
    final dayData = Map<String, dynamic>.from(calendar[dateKey]);
    final periods = Map<String, dynamic>.from(dayData['periods'] ?? {});
    final periodData = Map<String, dynamic>.from(periods[periodKey] ?? {});
    
    periodData[phase] = data;
    periods[periodKey] = periodData;
    dayData['periods'] = periods;
    calendar[dateKey] = dayData;

    await FirebaseFirestore.instance.collection('corps').doc(corpsId).update({
      'trainingYears.current.calendar': calendar,
    });
  }

  Future<void> _deleteEvent(String dateKey, AuthProvider auth) async {
    final corpsId = auth.userData?.corpsId;
    if (corpsId == null) return;

    final Map<String, dynamic> trainingYear = auth.corpsData?.trainingYears['current'] ?? {};
    final Map<String, dynamic> calendar = Map<String, dynamic>.from(trainingYear['calendar'] ?? {});
    
    calendar.remove(dateKey);

    await FirebaseFirestore.instance.collection('corps').doc(corpsId).update({
      'trainingYears.current.calendar': calendar,
    });
  }

  Future<void> _finalizeNight(BuildContext context, AuthProvider auth, ParadeDay day) async {
    final corpsId = auth.userData?.corpsId;
    if (corpsId == null) return;

    // 1. Get attendance for this night
    final attendanceDoc = await FirebaseFirestore.instance
        .collection('corps')
        .doc(corpsId)
        .collection('attendance')
        .doc(day.date)
        .get();
    
    if (!attendanceDoc.exists) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mark attendance before finalizing the night!')));
      }
      return;
    }

    final statuses = Map<String, String>.from(attendanceDoc.data()?['statuses'] ?? {});
    final List<dynamic> cadets = List.from(auth.corpsData?.settings['cadets'] ?? []);
    
    // 2. Identify EOs taught per phase
    Map<String, Set<String>> phaseEos = {};
    day.periods.forEach((pId, pData) {
      final levels = Map<String, dynamic>.from(pData);
      levels.forEach((phase, assignment) {
        final eoId = assignment['lessonId'];
        if (eoId != null && eoId.isNotEmpty) {
          phaseEos.putIfAbsent(phase, () => {}).add(eoId);
        }
      });
    });

    // 3. Update each cadet who was present
    bool updated = false;
    for (var i = 0; i < cadets.length; i++) {
      final cadet = cadets[i];
      final uid = cadet['uid'];
      final phase = cadet['phase'] ?? 'Phase 1';
      final status = statuses[uid];

      if (status == 'Present' || status == 'Late') {
        final eosForPhase = phaseEos[phase] ?? {};
        if (eosForPhase.isNotEmpty) {
          final Map<String, dynamic> records = Map<String, dynamic>.from(cadet['trainingRecords'] ?? {});
          final List<String> completed = List<String>.from(records[phase] ?? []);
          
          final int initialCount = completed.length;
          for (var eo in eosForPhase) {
            if (!completed.contains(eo)) completed.add(eo);
          }
          
          if (completed.length > initialCount) {
            records[phase] = completed;
            cadets[i]['trainingRecords'] = records;
            updated = true;
          }
        }
      }
    }

    if (updated) {
      await FirebaseFirestore.instance.collection('corps').doc(corpsId).update({
        'settings.cadets': cadets,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Night finalized! Progress bars updated for all present cadets.')));
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No new progress to record.')));
      }
    }
  }
}

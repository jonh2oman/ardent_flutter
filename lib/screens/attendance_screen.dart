import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/attendance.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    
    final String dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final List<dynamic> cadets = authProvider.corpsData?.settings['cadets'] ?? [];
    final activeCadets = cadets.where((c) => c['isArchived'] != true).toList();
    
    // Get current attendance for this date
    final Map<String, dynamic> trainingYear = authProvider.corpsData?.trainingYears['current'] ?? {};
    final Map<String, dynamic> attendanceMap = trainingYear['attendance'] ?? {};
    final List<dynamic> rawRecords = attendanceMap[dateKey] ?? [];
    final List<AttendanceRecord> records = rawRecords.map((r) => AttendanceRecord.fromMap(r)).toList();

    return Column(
      children: [
        _buildHeader(theme, dateKey),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(32),
            itemCount: activeCadets.length,
            itemBuilder: (context, index) {
              final cadet = activeCadets[index];
              final record = records.firstWhere(
                (r) => r.cadetId == cadet['id'],
                orElse: () => AttendanceRecord(cadetId: cadet['id'], status: 'none'),
              );
              return _buildCadetRow(theme, cadet, record, authProvider);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, String dateKey) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ATTENDANCE TRACKER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    DateFormat('MMMM d, yyyy').format(_selectedDate),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.calendar, size: 20),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2023),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                  ),
                ],
              ),
            ],
          ),
          _buildQuickStats(theme),
        ],
      ),
    );
  }

  Widget _buildQuickStats(ThemeData theme) {
    return Row(
      children: [
        _statChip(theme, 'Present', '0', Colors.greenAccent),
        const SizedBox(width: 12),
        _statChip(theme, 'Absent', '0', Colors.redAccent),
      ],
    );
  }

  Widget _statChip(ThemeData theme, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildCadetRow(ThemeData theme, dynamic cadet, AttendanceRecord record, AuthProvider auth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${cadet['rank']} ${cadet['lastName']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(cadet['firstName'] ?? '', style: const TextStyle(fontSize: 12, opacity: 0.6)),
              ],
            ),
          ),
          Row(
            children: [
              _statusButton(theme, 'P', 'present', record.status == 'present', Colors.greenAccent, () => _updateAttendance(cadet['id'], 'present', auth)),
              const SizedBox(width: 8),
              _statusButton(theme, 'A', 'absent', record.status == 'absent', Colors.redAccent, () => _updateAttendance(cadet['id'], 'absent', auth)),
              const SizedBox(width: 8),
              _statusButton(theme, 'E', 'excused', record.status == 'excused', Colors.amberAccent, () => _updateAttendance(cadet['id'], 'excused', auth)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusButton(ThemeData theme, String label, String status, bool isActive, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? color : Colors.white10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.black : Colors.white30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateAttendance(String cadetId, String status, AuthProvider auth) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final corpsId = auth.user?.corpsId;
    if (corpsId == null) return;

    // Get current attendance
    final Map<String, dynamic> trainingYear = auth.corpsData?.trainingYears['current'] ?? {};
    final Map<String, dynamic> attendance = Map<String, dynamic>.from(trainingYear['attendance'] ?? {});
    final List<dynamic> dayRecords = List<dynamic>.from(attendance[dateKey] ?? []);

    // Update or add record
    final int index = dayRecords.indexWhere((r) => r['cadetId'] == cadetId);
    if (index >= 0) {
      dayRecords[index]['status'] = status;
    } else {
      dayRecords.add({'cadetId': cadetId, 'status': status});
    }

    attendance[dateKey] = dayRecords;
    
    // Update Firestore
    await FirebaseFirestore.instance.collection('corps').doc(corpsId).update({
      'trainingYears.current.attendance': attendance,
    });
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';

class AttendanceScreen extends StatefulWidget {
  final String dateId;
  final String dateName;

  const AttendanceScreen({super.key, required this.dateId, required this.dateName});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  Map<String, String> _statuses = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingAttendance();
  }

  void _loadExistingAttendance() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final doc = await FirebaseFirestore.instance
        .collection('corps')
        .doc(auth.corpsData!.id)
        .collection('attendance')
        .doc(widget.dateId)
        .get();
    
    if (doc.exists) {
      setState(() {
        _statuses = Map<String, String>.from(doc.data()?['statuses'] ?? {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final List<dynamic> cadets = auth.corpsData?.settings['cadets'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('MARK ATTENDANCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            Text(widget.dateName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          if (_saving)
            const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
          else
            TextButton.icon(
              onPressed: _saveAttendance,
              icon: const Icon(LucideIcons.save, size: 18),
              label: const Text('SAVE'),
            ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: cadets.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final cadet = cadets[index];
          final uid = cadet['uid'] ?? '';
          final currentStatus = _statuses[uid] ?? 'Absent';

          return Container(
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
                      Text("${cadet['firstName']} ${cadet['lastName']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(cadet['rank'] ?? 'Cadet', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary)),
                    ],
                  ),
                ),
                _buildStatusButton('P', 'Present', Colors.green, uid, currentStatus),
                _buildStatusButton('A', 'Absent', Colors.red, uid, currentStatus),
                _buildStatusButton('E', 'Excused', Colors.orange, uid, currentStatus),
                _buildStatusButton('L', 'Late', Colors.blue, uid, currentStatus),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusButton(String label, String status, Color color, String uid, String currentStatus) {
    bool isSelected = currentStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _statuses[uid] = status),
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : color.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  void _saveAttendance() async {
    setState(() => _saving = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      await FirebaseFirestore.instance
          .collection('corps')
          .doc(auth.corpsData!.id)
          .collection('attendance')
          .doc(widget.dateId)
          .set({'statuses': _statuses});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance saved successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving attendance: $e')));
      }
    } finally {
      setState(() => _saving = false);
    }
  }
}

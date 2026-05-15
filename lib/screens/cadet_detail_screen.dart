import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/user_data.dart';
import '../widgets/stat_card.dart';

class CadetDetailScreen extends StatelessWidget {
  final UserData cadet;

  const CadetDetailScreen({super.key, required this.cadet});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final age = _calculateAge(cadet.dob);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(cadet.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cadet.rank ?? 'Cadet', style: TextStyle(fontSize: 18, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                    Text(cadet.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1.0)),
                    Text('PHASE ${cadet.phase ?? 'N/A'}', style: const TextStyle(fontSize: 12, color: Colors.white30, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Quick Stats
            Row(
              children: [
                Expanded(child: StatCard(title: 'Age', value: age > 0 ? '$age' : '--', icon: LucideIcons.user, iconColor: Colors.blueAccent)),
                const SizedBox(width: 16),
                Expanded(child: StatCard(title: 'Attendance', value: '92%', icon: LucideIcons.checkCircle, iconColor: Colors.greenAccent)),
              ],
            ),
            const SizedBox(height: 32),

            // Details Sections
            _buildSection(theme, 'Personal Information', [
              _buildDetailRow('Rank', cadet.rank ?? 'Cadet'),
              _buildDetailRow('Element', cadet.element ?? 'Sea'),
              _buildDetailRow('Date of Birth', cadet.dob != null ? DateFormat('MMM d, yyyy').format(cadet.dob!) : 'Unknown'),
              _buildDetailRow('Email', cadet.email),
            ]),
            
            const SizedBox(height: 32),
            
            _buildSection(theme, 'Training Progress', [
              _buildProgressRow('PO 107 (Sea Cadet Service)', 0.8),
              _buildProgressRow('PO 108 (Drill)', 0.4),
              _buildProgressRow('PO 121 (Ropework)', 1.0),
            ]),
          ],
        ),
      ),
    );
  }

  int _calculateAge(DateTime? dob) {
    if (dob == null) return 0;
    return DateTime.now().year - dob.year;
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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

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
    final age = _calculateAge(cadet.dateOfBirth);

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
                  child: Text(cadet.name[0], style: TextStyle(fontSize: 32, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cadet.rank, style: TextStyle(fontSize: 18, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                    Text(cadet.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1.0)),
                    Text(cadet.role.toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.white30, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Quick Stats
            Row(
              children: [
                Expanded(child: StatCard(title: 'Age', value: '$age', icon: LucideIcons.user, iconColor: Colors.blueAccent)),
                const SizedBox(width: 16),
                Expanded(child: StatCard(title: 'Attendance', value: '92%', icon: LucideIcons.checkCircle, iconColor: Colors.greenAccent)),
              ],
            ),
            const SizedBox(height: 32),

            // Details Sections
            _buildSection(theme, 'Personal Information', [
              _buildDetailRow('Rank', cadet.rank),
              _buildDetailRow('Element', cadet.element),
              _buildDetailRow('Division', 'Main Division'), // Placeholder
              _buildDetailRow('Date of Birth', DateFormat('MMM d, yyyy').format(cadet.dateOfBirth)),
            ]),
            
            const SizedBox(height: 32),
            
            _buildSection(theme, 'Training Progress (Phase 1)', [
              _buildProgressRow('PO 107 (Sea Cadet Service)', 0.8),
              _buildProgressRow('PO 108 (Drill)', 0.4),
              _buildProgressRow('PO 121 (Ropework)', 1.0),
            ]),
          ],
        ),
      ),
    );
  }

  int _calculateAge(DateTime dob) {
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

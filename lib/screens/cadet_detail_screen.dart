import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/user_data.dart';
import '../widgets/stat_card.dart';
import '../providers/auth_provider.dart';

class CadetDetailScreen extends StatelessWidget {
  final UserData cadet;

  const CadetDetailScreen({super.key, required this.cadet});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final age = _calculateAge(cadet.dob);
    
    // Calculate live attendance
    final attendanceData = auth.attendance;
    int totalNights = attendanceData.length;
    int presentNights = 0;
    
    attendanceData.forEach((date, statuses) {
      final status = statuses[cadet.id];
      if (status == 'Present' || status == 'Late') {
        presentNights++;
      }
    });
    
    final attendancePercent = totalNights > 0 
      ? (presentNights / totalNights * 100).toInt() 
      : 100;

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cadet.rank ?? 'Cadet', style: TextStyle(fontSize: 18, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                      Text(cadet.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1.0)),
                      Text('PHASE ${cadet.phase ?? 'N/A'} • CIN: ${cadet.cin ?? '---'}', style: const TextStyle(fontSize: 12, color: Colors.white30, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Quick Stats
            Row(
              children: [
                Expanded(child: StatCard(title: 'Age', value: age > 0 ? '$age' : '--', icon: LucideIcons.user, iconColor: Colors.blueAccent)),
                const SizedBox(width: 16),
                Expanded(child: StatCard(title: 'Attendance', value: '$attendancePercent%', icon: LucideIcons.checkCircle, iconColor: Colors.greenAccent)),
              ],
            ),
            const SizedBox(height: 32),

            // Personal Information
            _buildSection(theme, 'Personal Information', [
              _buildDetailRow('Rank', cadet.rank ?? 'Cadet'),
              _buildDetailRow('Date of Birth', cadet.dob != null ? DateFormat('MMM d, yyyy').format(cadet.dob!) : 'Unknown'),
              _buildDetailRow('Personal Phone', cadet.phone ?? 'N/A'),
              _buildDetailRow('Personal Email', cadet.personalEmail ?? 'N/A'),
              _buildDetailRow('Cadet Email', cadet.cadetEmail ?? 'N/A'),
            ]),
            
            const SizedBox(height: 32),

            // Address
            _buildSection(theme, 'Address', [
              _buildDetailRow('Street', cadet.address?['street'] ?? 'N/A'),
              _buildDetailRow('City', cadet.address?['city'] ?? 'N/A'),
              _buildDetailRow('Province', cadet.address?['province'] ?? 'N/A'),
              _buildDetailRow('Postal Code', cadet.address?['postalCode'] ?? 'N/A'),
            ]),

            const SizedBox(height: 32),

            // Guardians
            if (cadet.parents != null && cadet.parents!.isNotEmpty)
              _buildSection(theme, 'Guardians', cadet.parents!.map((p) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['name'] ?? 'Unknown Parent', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${p['relationship'] ?? 'Guardian'} • ${p['phone'] ?? 'No Phone'}', style: const TextStyle(fontSize: 12, color: Colors.white30)),
                  const SizedBox(height: 12),
                ],
              )).toList()),

            const SizedBox(height: 32),

            // Medical
            _buildSection(theme, 'Medical Information', [
              _buildDetailRow('Health #', cadet.provincialHealthNumber ?? 'N/A'),
              _buildDetailRow('Insurance', cadet.privateInsuranceProvider ?? 'N/A'),
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
          Expanded(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
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

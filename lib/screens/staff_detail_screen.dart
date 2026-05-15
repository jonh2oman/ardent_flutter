import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/user_data.dart';

class StaffDetailScreen extends StatelessWidget {
  final UserData staff;

  const StaffDetailScreen({super.key, required this.staff});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${staff.rank ?? "OFFICER"} ${staff.lastName ?? "DETAIL"}'.toUpperCase()),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.edit3),
            onPressed: () {},
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blueAccent.withOpacity(0.1),
                      child: const Icon(LucideIcons.shield, size: 40, color: Colors.blueAccent),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${staff.firstName} ${staff.lastName}".toUpperCase(),
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.0),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${staff.rank ?? 'Officer'} • ${staff.email}",
                            style: TextStyle(fontSize: 16, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Info Grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Details
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildSectionCard(
                        title: 'APPOINTMENT & ROLE',
                        icon: LucideIcons.briefcase,
                        children: [
                          _buildDetailRow('Primary Role', 'Unit Staff'),
                          _buildDetailRow('Security Level', staff.isSupportAdmin ? 'Admin' : 'Standard'),
                          _buildDetailRow('Commission Date', 'N/A'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSectionCard(
                        title: 'CONTACT INFORMATION',
                        icon: LucideIcons.phone,
                        children: [
                          _buildDetailRow('Work Email', staff.email),
                          _buildDetailRow('Phone', 'N/A'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right Column: Permissions
                Expanded(
                  child: _buildSectionCard(
                    title: 'MODULE PERMISSIONS',
                    icon: LucideIcons.lock,
                    children: [
                      _buildPermissionToggle('Supply Hub', true),
                      _buildPermissionToggle('Training Records', true),
                      _buildPermissionToggle('Finance/Exchange', staff.isSupportAdmin),
                      _buildPermissionToggle('Personnel Management', staff.isSupportAdmin),
                      _buildPermissionToggle('Routine Orders', true),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Colors.blueAccent),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              ],
            ),
            const Divider(height: 32),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPermissionToggle(String label, bool isEnabled) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            isEnabled ? LucideIcons.checkCircle2 : LucideIcons.circle,
            size: 16,
            color: isEnabled ? Colors.greenAccent : Colors.white24,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isEnabled ? Colors.white : Colors.white38,
              decoration: isEnabled ? null : TextDecoration.lineThrough,
            ),
          ),
        ],
      ),
    );
  }
}

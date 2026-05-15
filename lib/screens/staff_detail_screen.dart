import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_data.dart';

class StaffDetailScreen extends StatefulWidget {
  final UserData staff;

  const StaffDetailScreen({super.key, required this.staff});

  @override
  State<StaffDetailScreen> createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends State<StaffDetailScreen> {
  late Map<String, dynamic> _localPermissions;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    // Initialize local state from the passed staff data
    _localPermissions = Map<String, dynamic>.from(widget.staff.permissions);
    
    // Ensure modules map exists
    if (_localPermissions['modules'] == null) {
      _localPermissions['modules'] = {
        'supply': true,
        'training': true,
        'finance': false,
        'personnel': false,
        'orders': true,
      };
    }
  }

  Future<void> _togglePermission(String moduleKey) async {
    setState(() => _isUpdating = true);

    try {
      final currentModules = Map<String, dynamic>.from(_localPermissions['modules'] ?? {});
      final newValue = !(currentModules[moduleKey] ?? false);
      currentModules[moduleKey] = newValue;

      await FirebaseFirestore.instance.collection('users').doc(widget.staff.id).update({
        'permissions.modules.$moduleKey': newValue,
        // If they have access to sensitive modules, they should probably be marked as admin in some systems
        'isAdmin': currentModules['personnel'] == true || currentModules['finance'] == true,
      });

      setState(() {
        _localPermissions['modules'] = currentModules;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permissions updated for ${widget.staff.lastName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating permissions: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modules = _localPermissions['modules'] as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.staff.rank ?? "OFFICER"} ${widget.staff.lastName ?? "DETAIL"}'.toUpperCase()),
        actions: [
          if (_isUpdating)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
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
                            "${widget.staff.firstName} ${widget.staff.lastName}".toUpperCase(),
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.0),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${widget.staff.rank ?? 'Officer'} • ${widget.staff.email}",
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
                          _buildDetailRow('Security Level', widget.staff.isSupportAdmin ? 'Admin' : 'Standard'),
                          _buildDetailRow('Commission Date', 'N/A'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSectionCard(
                        title: 'CONTACT INFORMATION',
                        icon: LucideIcons.phone,
                        children: [
                          _buildDetailRow('Work Email', widget.staff.email),
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
                      _buildPermissionToggle('Supply Hub', 'supply', modules['supply'] ?? false),
                      _buildPermissionToggle('Training Records', 'training', modules['training'] ?? false),
                      _buildPermissionToggle('Finance/Exchange', 'finance', modules['finance'] ?? false),
                      _buildPermissionToggle('Personnel Management', 'personnel', modules['personnel'] ?? false),
                      _buildPermissionToggle('Routine Orders', 'orders', modules['orders'] ?? false),
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

  Widget _buildPermissionToggle(String label, String key, bool isEnabled) {
    return InkWell(
      onTap: _isUpdating ? null : () => _togglePermission(key),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(
              isEnabled ? LucideIcons.checkCircle2 : LucideIcons.circle,
              size: 16,
              color: isEnabled ? Colors.greenAccent : Colors.white24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isEnabled ? Colors.white : Colors.white38,
                  decoration: isEnabled ? null : TextDecoration.lineThrough,
                ),
              ),
            ),
            if (isEnabled)
              const Icon(LucideIcons.shieldCheck, size: 14, color: Colors.blueAccent),
          ],
        ),
      ),
    );
  }
}

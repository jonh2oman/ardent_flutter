import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/user_data.dart';
import '../providers/auth_provider.dart';

class StaffDetailScreen extends StatefulWidget {
  final UserData staff;

  const StaffDetailScreen({super.key, required this.staff});

  @override
  State<StaffDetailScreen> createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends State<StaffDetailScreen> {
  late Map<String, dynamic> _localPermissions;
  bool _isUpdating = false;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _rankController;
  late TextEditingController _phoneController;
  late TextEditingController _personalEmailController;

  @override
  void initState() {
    super.initState();
    _localPermissions = Map<String, dynamic>.from(widget.staff.permissions);
    
    if (_localPermissions['modules'] == null) {
      _localPermissions['modules'] = {
        'supply': true,
        'training': true,
        'finance': false,
        'personnel': false,
        'orders': true,
        'marksmanship': false,
      };
    }

    _firstNameController = TextEditingController(text: widget.staff.firstName);
    _lastNameController = TextEditingController(text: widget.staff.lastName);
    _rankController = TextEditingController(text: widget.staff.rank);
    _phoneController = TextEditingController(text: widget.staff.phone);
    _personalEmailController = TextEditingController(text: widget.staff.personalEmail);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _rankController.dispose();
    _phoneController.dispose();
    _personalEmailController.dispose();
    super.dispose();
  }

  Future<void> _logAuditEntry({
    required String action,
    required String details,
  }) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final corpsId = authProvider.userData?.corpsId;
      final operatorName = authProvider.userData?.name ?? 'System';
      final operatorId = authProvider.userData?.id ?? 'system';

      if (corpsId != null) {
        await FirebaseFirestore.instance
            .collection('corps')
            .doc(corpsId)
            .collection('audit_logs')
            .add({
          'targetUserId': widget.staff.id,
          'targetUserName': widget.staff.name,
          'operatorId': operatorId,
          'operatorName': operatorName,
          'action': action,
          'details': details,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error writing audit log: $e');
    }
  }

  Future<void> _updateProfileField(String field, String value) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isUpdating = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.staff.id).update({
        field: value.trim(),
      });

      await _logAuditEntry(
        action: 'Profile Updated',
        details: 'Changed $field to "${value.trim()}"',
      );

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('${field[0].toUpperCase()}${field.substring(1)} updated successfully'),
            backgroundColor: Colors.blueAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error updating $field: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _togglePermission(String moduleKey) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isUpdating = true);

    try {
      final currentModules = Map<String, dynamic>.from(_localPermissions['modules'] ?? {});
      final newValue = !(currentModules[moduleKey] ?? false);
      currentModules[moduleKey] = newValue;

      await FirebaseFirestore.instance.collection('users').doc(widget.staff.id).update({
        'permissions.modules.$moduleKey': newValue,
        'isAdmin': currentModules['personnel'] == true || currentModules['finance'] == true,
      });

      setState(() {
        _localPermissions['modules'] = currentModules;
      });

      await _logAuditEntry(
        action: 'Permission Toggle',
        details: '${moduleKey.toUpperCase()} permission toggled to ${newValue ? 'ENABLED' : 'DISABLED'}',
      );

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Permissions updated for ${widget.staff.lastName}'),
            backgroundColor: Colors.blueAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error updating permissions: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _applyPreset(String presetKey, Map<String, bool> targetModules, String desc) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isUpdating = true);

    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(widget.staff.id);
      final updates = <String, dynamic>{};
      for (var entry in targetModules.entries) {
        updates['permissions.modules.${entry.key}'] = entry.value;
      }
      
      final isAdmin = targetModules['personnel'] == true || targetModules['finance'] == true;
      updates['isAdmin'] = isAdmin;

      await docRef.update(updates);

      setState(() {
        _localPermissions['modules'] = Map<String, dynamic>.from(targetModules);
      });

      await _logAuditEntry(
        action: 'Preset Applied',
        details: 'Assigned $presetKey preset: $desc',
      );

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('$presetKey preset applied successfully for ${widget.staff.lastName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error applying preset: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _updatePosition(String? newPosition) async {
    if (newPosition == null) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isUpdating = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.staff.id).update({
        'position': newPosition,
      });

      await _logAuditEntry(
        action: 'Position Update',
        details: 'Assigned new unit appointment: $newPosition',
      );

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Position updated to $newPosition'),
            backgroundColor: Colors.blueAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error updating position: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _toggleSupportAdmin(bool currentValue) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              currentValue ? LucideIcons.shieldAlert : LucideIcons.shieldCheck, 
              color: currentValue ? Colors.redAccent : Colors.amberAccent
            ),
            const SizedBox(width: 12),
            Text(
              currentValue ? 'DEMOTE SYSTEM ADMIN' : 'ELEVATE TO SYSTEM ADMIN', 
              style: const TextStyle(fontWeight: FontWeight.bold)
            ),
          ],
        ),
        content: Text(
          currentValue
              ? 'Are you sure you want to revoke Support Admin privileges from ${widget.staff.name}? They will lose root-level administrative access to all corps systems.'
              : 'WARNING: Elevating ${widget.staff.name} to Support Admin grants them complete root-level configuration and database control. Ensure this action is fully authorized.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: currentValue ? Colors.redAccent : Colors.amberAccent,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(currentValue ? 'REVOKE PRIVILEGES' : 'CONFIRM ELEVATION'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      setState(() => _isUpdating = true);
      try {
        await FirebaseFirestore.instance.collection('users').doc(widget.staff.id).update({
          'isSupportAdmin': !currentValue,
        });

        await _logAuditEntry(
          action: 'Clearance Changed',
          details: !currentValue 
              ? 'Elevated to System Support Admin (Full Root Access)'
              : 'Revoked System Support Admin status',
        );

        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(!currentValue ? 'Elevated to Support Admin' : 'Revoked Support Admin status'),
              backgroundColor: !currentValue ? Colors.amberAccent : Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('Error updating clearance: $e'), backgroundColor: Colors.redAccent),
          );
        }
      } finally {
        if (mounted) setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.staff.id).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F0F11),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0F0F11),
              title: const Text('LOADING PROFILE...'),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final doc = snapshot.data;
        if (doc == null || !doc.exists) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F0F11),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0F0F11),
              title: const Text('ERROR'),
            ),
            body: const Center(child: Text('Staff member profile not found.')),
          );
        }

        final data = doc.data() as Map<String, dynamic>;
        final staff = UserData.fromMap(data, doc.id);
        
        final modules = staff.permissions['modules'] as Map<String, dynamic>? ?? {
          'supply': true,
          'training': true,
          'finance': false,
          'personnel': false,
          'orders': true,
          'marksmanship': false,
        };

        if (_firstNameController.text != (staff.firstName ?? '') && !FocusScope.of(context).hasFocus) {
          _firstNameController.text = staff.firstName ?? '';
        }
        if (_lastNameController.text != (staff.lastName ?? '') && !FocusScope.of(context).hasFocus) {
          _lastNameController.text = staff.lastName ?? '';
        }
        if (_rankController.text != (staff.rank ?? '') && !FocusScope.of(context).hasFocus) {
          _rankController.text = staff.rank ?? '';
        }
        if (_phoneController.text != (staff.phone ?? '') && !FocusScope.of(context).hasFocus) {
          _phoneController.text = staff.phone ?? '';
        }
        if (_personalEmailController.text != (staff.personalEmail ?? '') && !FocusScope.of(context).hasFocus) {
          _personalEmailController.text = staff.personalEmail ?? '';
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0F0F11),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F0F11),
            elevation: 0,
            title: Text(
              '${staff.rank ?? "OFFICER"} ${staff.lastName ?? "DETAIL"}'.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.userMinus, color: Colors.redAccent),
                tooltip: 'Strike Off Strength',
                onPressed: () => _deleteStaffMember(context),
              ),
              if (_isUpdating)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                    ),
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: const Color(0xFF16161A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          (staff.isSupportAdmin || staff.isAdmin)
                              ? Colors.amberAccent.withValues(alpha: 0.08)
                              : Colors.blueAccent.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(28.0),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (staff.isSupportAdmin || staff.isAdmin)
                                    ? Colors.amberAccent.withValues(alpha: 0.15)
                                    : Colors.blueAccent.withValues(alpha: 0.15),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: (staff.isSupportAdmin || staff.isAdmin)
                                ? Colors.amberAccent.withValues(alpha: 0.05)
                                : Colors.blueAccent.withValues(alpha: 0.05),
                            child: Icon(
                              staff.isSupportAdmin 
                                  ? LucideIcons.shieldCheck 
                                  : (staff.isAdmin ? LucideIcons.shield : LucideIcons.user), 
                              size: 44, 
                              color: (staff.isSupportAdmin || staff.isAdmin)
                                  ? Colors.amberAccent
                                  : Colors.blueAccent
                            ),
                          ),
                        ),
                        const SizedBox(width: 28),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    staff.name.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 28, 
                                      fontWeight: FontWeight.w900, 
                                      letterSpacing: -0.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  if (staff.isSupportAdmin)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.amberAccent.withValues(alpha: 0.1),
                                        border: Border.all(color: Colors.amberAccent, width: 1.5),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(LucideIcons.shieldCheck, size: 12, color: Colors.amberAccent),
                                          SizedBox(width: 6),
                                          Text(
                                            'SYSTEM ADMIN',
                                            style: TextStyle(
                                              fontSize: 9, 
                                              fontWeight: FontWeight.bold, 
                                              color: Colors.amberAccent,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else if (staff.isAdmin)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent.withValues(alpha: 0.1),
                                        border: Border.all(color: Colors.blueAccent, width: 1.5),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(LucideIcons.shield, size: 12, color: Colors.blueAccent),
                                          SizedBox(width: 6),
                                          Text(
                                            'ADMINISTRATOR',
                                            style: TextStyle(
                                              fontSize: 9, 
                                              fontWeight: FontWeight.bold, 
                                              color: Colors.blueAccent,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "${staff.rank ?? 'Officer'} • ${staff.email}",
                                style: TextStyle(
                                  fontSize: 15, 
                                  color: theme.colorScheme.primary, 
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _buildSectionCard(
                            title: 'BASIC INFORMATION',
                            icon: LucideIcons.user,
                            children: [
                              _buildEditableRow('First Name', _firstNameController, (val) => _updateProfileField('firstName', val)),
                              _buildEditableRow('Last Name', _lastNameController, (val) => _updateProfileField('lastName', val)),
                              _buildEditableRow('Rank / Grade', _rankController, (val) => _updateProfileField('rank', val)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildSectionCard(
                            title: 'CONTACT INFORMATION',
                            icon: LucideIcons.phone,
                            children: [
                              _buildDetailRow('Primary User Email', staff.email),
                              _buildEditableRow('Personal Email', _personalEmailController, (val) => _updateProfileField('personalEmail', val)),
                              _buildEditableRow('Contact Phone Number', _phoneController, (val) => _updateProfileField('phone', val)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: [
                          _buildSectionCard(
                            title: 'APPOINTMENT & ROLE',
                            icon: LucideIcons.briefcase,
                            children: [
                              _buildPositionSelector(theme, staff),
                              _buildDetailRow('Security Access Level', staff.isSupportAdmin ? 'Root System Admin' : (staff.isAdmin ? 'Unit Administrator' : 'Standard Officer')),
                              _buildDetailRow('Unit Enrollment Date', staff.enrolmentDate != null 
                                  ? DateFormat('MMMM d, yyyy').format(staff.enrolmentDate!) 
                                  : 'Initial Onboarding Pending'),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildSectionCard(
                            title: 'OFFICER CLEARANCE CONTROLS',
                            icon: LucideIcons.shieldAlert,
                            children: [
                              if (staff.isSupportAdmin) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2), width: 1.5),
                                  ),
                                  child: const Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(LucideIcons.alertOctagon, color: Colors.redAccent, size: 20),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'ROOT AUDIT NOTICE',
                                              style: TextStyle(
                                                color: Colors.redAccent,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 11,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'This account has full root-level database access. All actions are compiled in security registries for unit liability protocols.',
                                              style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ] else if (staff.isAdmin) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.amberAccent.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.2), width: 1.5),
                                  ),
                                  child: const Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(LucideIcons.alertTriangle, color: Colors.amberAccent, size: 20),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'ADMINISTRATIVE ELEVATION',
                                              style: TextStyle(
                                                color: Colors.amberAccent,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 11,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'This officer is designated as a unit administrator. Ensure they have signed the mandatory non-disclosure agreement.',
                                              style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: staff.isSupportAdmin 
                                        ? Colors.redAccent.withValues(alpha: 0.1) 
                                        : Colors.amberAccent.withValues(alpha: 0.1),
                                    foregroundColor: staff.isSupportAdmin ? Colors.redAccent : Colors.amberAccent,
                                    side: BorderSide(
                                      color: staff.isSupportAdmin ? Colors.redAccent : Colors.amberAccent,
                                      width: 1.2
                                    ),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  icon: Icon(
                                    staff.isSupportAdmin ? LucideIcons.shieldAlert : LucideIcons.shieldAlert, 
                                    size: 16
                                  ),
                                  label: Text(
                                    staff.isSupportAdmin ? 'DEMOTE SYSTEM CLEARANCE' : 'ELEVATE TO SYSTEM ADMIN',
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                                  ),
                                  onPressed: () => _toggleSupportAdmin(staff.isSupportAdmin),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Card(
                  color: const Color(0xFF16161A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.lock, size: 20, color: Colors.blueAccent),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'OFFICER SYSTEM ACCESS MATRIX', 
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0)
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Configure module specific reading, writing, and administrative authorizations',
                                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.38)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 40, color: Colors.white10),
                        
                        _buildPresetMatrix(modules),
                        const SizedBox(height: 12),

                        const Text(
                          'GRANULAR PERMISSION OVERRIDES',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white54, letterSpacing: 1.0),
                        ),
                        const SizedBox(height: 16),
                        _buildPermissionCardsGrid(modules),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                _buildAuditLogsTimeline(theme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      color: const Color(0xFF16161A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Colors.blueAccent),
                const SizedBox(width: 12),
                Text(
                  title, 
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white70)
                ),
              ],
            ),
            const Divider(height: 32, color: Colors.white10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildPresetMatrix(Map<String, dynamic> currentModules) {
    final presets = {
      'COMMAND Preset': {
        'icon': LucideIcons.shield,
        'color': Colors.amberAccent,
        'modules': {'supply': true, 'training': true, 'finance': true, 'personnel': true, 'marksmanship': true, 'orders': true},
        'desc': 'Complete root administrator authority over all system modules.'
      },
      'TRAINING Preset': {
        'icon': LucideIcons.award,
        'color': Colors.greenAccent,
        'modules': {'supply': false, 'training': true, 'finance': false, 'personnel': false, 'marksmanship': true, 'orders': true},
        'desc': 'Write privileges for training records, range targets, and unit orders.'
      },
      'LOGISTICS Preset': {
        'icon': LucideIcons.box,
        'color': Colors.blueAccent,
        'modules': {'supply': true, 'training': false, 'finance': false, 'personnel': false, 'marksmanship': false, 'orders': true},
        'desc': 'Manage clothing issue accounts, physical kits, inventories, and print loan cards.'
      },
      'FINANCE Preset': {
        'icon': LucideIcons.coins,
        'color': Colors.cyanAccent,
        'modules': {'supply': false, 'training': false, 'finance': true, 'personnel': false, 'marksmanship': false, 'orders': true},
        'desc': 'Authorized cashier for Cadet Exchange, POS registers, and credit sheets.'
      },
      'RESTRICTED Preset': {
        'icon': LucideIcons.eyeOff,
        'color': Colors.grey,
        'modules': {'supply': false, 'training': false, 'finance': false, 'personnel': false, 'marksmanship': false, 'orders': false},
        'desc': 'Revoke all read/write authorization keys across administrative panels.'
      },
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'UNIT ROLE TEMPLATES & PRESETS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white54, letterSpacing: 1.0),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: presets.entries.map((entry) {
              final key = entry.key;
              final icon = entry.value['icon'] as IconData;
              final color = entry.value['color'] as Color;
              final targetModules = entry.value['modules'] as Map<String, bool>;
              
              bool isSelected = true;
              for (var modKey in targetModules.keys) {
                if ((currentModules[modKey] ?? false) != targetModules[modKey]) {
                  isSelected = false;
                  break;
                }
              }

              return Padding(
                padding: const EdgeInsets.only(right: 16.0, bottom: 8),
                child: _PresetCard(
                  title: key.replaceAll(' Preset', ''),
                  icon: icon,
                  color: color,
                  targetModules: targetModules,
                  desc: entry.value['desc'] as String,
                  isSelected: isSelected,
                  isUpdating: _isUpdating,
                  onTap: () => _applyPreset(key.replaceAll(' Preset', ''), targetModules, entry.value['desc'] as String),
                ),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 36, color: Colors.white10),
      ],
    );
  }

  Widget _buildPermissionCardsGrid(Map<String, dynamic> currentModules) {
    final definitions = [
      {
        'title': 'Supply Hub',
        'subtext': 'Uniform sizes, issue standard issue uniforms, print Personal Loan Cards.',
        'key': 'supply',
        'icon': LucideIcons.box,
        'color': Colors.blueAccent,
      },
      {
        'title': 'Training Records',
        'subtext': 'Track Cadet completed EOs, qualification charts, and roster averages.',
        'key': 'training',
        'icon': LucideIcons.award,
        'color': Colors.greenAccent,
      },
      {
        'title': 'Exchange Ledger',
        'subtext': 'Checkout Cadet purchases on POS register, deposit points, edit ledger.',
        'key': 'finance',
        'icon': LucideIcons.coins,
        'color': Colors.cyanAccent,
      },
      {
        'title': 'Personnel Registry',
        'subtext': 'Grant officer appointments, modify clearance, strike off members.',
        'key': 'personnel',
        'icon': LucideIcons.users,
        'color': Colors.amberAccent,
      },
      {
        'title': 'Marksmanship Relay',
        'subtext': 'Create competition ranges, score paper targets, audit team rosters.',
        'key': 'marksmanship',
        'icon': LucideIcons.target,
        'color': Colors.redAccent,
      },
      {
        'title': 'Routine Orders',
        'subtext': 'Publish weekly operational notices, cadet promotions, schedules.',
        'key': 'orders',
        'icon': LucideIcons.fileText,
        'color': Colors.purpleAccent,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.45,
      ),
      itemCount: definitions.length,
      itemBuilder: (context, index) {
        final def = definitions[index];
        final title = def['title'] as String;
        final subtext = def['subtext'] as String;
        final key = def['key'] as String;
        final icon = def['icon'] as IconData;
        final color = def['color'] as Color;
        final isEnabled = currentModules[key] ?? false;

        return _PermissionToggleCard(
          title: title,
          subtext: subtext,
          moduleKey: key,
          isEnabled: isEnabled,
          icon: icon,
          activeColor: color,
          isUpdating: _isUpdating,
          onChanged: (val) => _togglePermission(key),
        );
      },
    );
  }

  Widget _buildEditableRow(String label, TextEditingController controller, Function(String) onSave) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label, 
            style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C22),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Click check to save input',
                      hintStyle: TextStyle(color: Colors.white24),
                    ),
                    onSubmitted: (val) => onSave(val),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => onSave(controller.text),
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Icon(LucideIcons.check, size: 14, color: Colors.blueAccent),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPositionSelector(ThemeData theme, UserData staff) {
    final positions = [
      'Commanding Officer',
      'Executive Officer',
      'Training Officer',
      'Supply Officer',
      'Administration Officer',
      'Finance Officer',
      'Assistant Training Officer',
      'Divisional Officer',
      'Instructor',
      'Unit Staff',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Unit Appointment', style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: positions.contains(staff.position) ? staff.position : 'Unit Staff',
                  dropdownColor: const Color(0xFF1E1E24),
                  isExpanded: true,
                  alignment: Alignment.centerRight,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  items: positions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, textAlign: TextAlign.right),
                    );
                  }).toList(),
                  onChanged: _isUpdating ? null : (val) => _updatePosition(val),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogsTimeline(ThemeData theme) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final corpsId = authProvider.userData?.corpsId;

    if (corpsId == null) return const SizedBox.shrink();

    return Card(
      color: const Color(0xFF16161A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        collapsedBackgroundColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        leading: const Icon(LucideIcons.history, color: Colors.blueAccent),
        title: const Text(
          '👮 OFFICER ACCESS AUDIT LOG',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Colors.white),
        ),
        subtitle: const Text(
          'Real-time administrative ledger of security alterations on this profile',
          style: TextStyle(fontSize: 11, color: Colors.white38),
        ),
        children: [
          Container(
            height: 320,
            padding: const EdgeInsets.all(20.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('corps')
                  .doc(corpsId)
                  .collection('audit_logs')
                  .where('targetUserId', isEqualTo: widget.staff.id)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                }

                final logs = snapshot.data?.docs ?? [];

                if (logs.isEmpty) {
                  return _buildSimulatedTimeline(theme);
                }

                return ListView.builder(
                  itemCount: logs.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final log = logs[index].data() as Map<String, dynamic>;
                    final timestamp = log['timestamp'] as Timestamp?;
                    final dateStr = timestamp != null
                        ? DateFormat('MMM d, yyyy HH:mm').format(timestamp.toDate())
                        : 'Just now';

                    return _buildTimelineItem(
                      theme: theme,
                      action: log['action'] ?? 'Action',
                      details: log['details'] ?? '',
                      operator: log['operatorName'] ?? 'System',
                      dateStr: dateStr,
                      isLast: index == logs.length - 1,
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

  Widget _buildSimulatedTimeline(ThemeData theme) {
    final dummyLogs = [
      {
        'action': 'Account Commissioned',
        'details': 'Staff profile created and assigned to Corps ID: ${widget.staff.corpsId}',
        'operator': 'System Provisioner',
        'dateStr': widget.staff.enrolmentDate != null 
            ? DateFormat('MMM d, yyyy').format(widget.staff.enrolmentDate!)
            : 'Onboarding Date',
      },
      {
        'action': 'Security Level Assigned',
        'details': 'Security clearance initialized to ${widget.staff.isSupportAdmin ? 'Root System Admin' : 'Standard'}',
        'operator': 'System Provisioner',
        'dateStr': widget.staff.enrolmentDate != null 
            ? DateFormat('MMM d, yyyy').format(widget.staff.enrolmentDate!)
            : 'Onboarding Date',
      },
    ];

    return ListView.builder(
      itemCount: dummyLogs.length,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final log = dummyLogs[index];
        return _buildTimelineItem(
          theme: theme,
          action: log['action']!,
          details: log['details']!,
          operator: log['operator']!,
          dateStr: log['dateStr']!,
          isLast: index == dummyLogs.length - 1,
        );
      },
    );
  }

  Widget _buildTimelineItem({
    required ThemeData theme,
    required String action,
    required String details,
    required String operator,
    required String dateStr,
    required bool isLast,
  }) {
    IconData getIconForAction(String action) {
      if (action.contains('Permission') || action.contains('Preset')) return LucideIcons.key;
      if (action.contains('Position') || action.contains('Clearance') || action.contains('Rank')) return LucideIcons.userCheck;
      if (action.contains('Profile')) return LucideIcons.user;
      return LucideIcons.shieldCheck;
    }

    Color getColorForAction(String action) {
      if (action.contains('Permission') || action.contains('Preset')) return Colors.orangeAccent;
      if (action.contains('Position') || action.contains('Clearance') || action.contains('Rank')) return Colors.greenAccent;
      if (action.contains('Profile')) return Colors.blueAccent;
      return Colors.grey;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: getColorForAction(action).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: getColorForAction(action), width: 1.5),
                ),
                child: Icon(getIconForAction(action), size: 12, color: getColorForAction(action)),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: Colors.white12,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        action.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: getColorForAction(action),
                        ),
                      ),
                      Text(
                        dateStr,
                        style: const TextStyle(fontSize: 10, color: Colors.white30),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    details,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Operated by: $operator',
                    style: const TextStyle(fontSize: 10, color: Colors.white38, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStaffMember(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: Colors.redAccent),
            SizedBox(width: 12),
            Text('STRIKE OFF STRENGTH?', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to remove ${widget.staff.name.isNotEmpty ? widget.staff.name : "this blank profile"} from the unit? This cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      setState(() => _isUpdating = true);
      try {
        await FirebaseFirestore.instance.collection('users').doc(widget.staff.id).delete();
        if (mounted) {
          navigator.pop();
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Staff member removed successfully'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('Error removing staff: $e'), backgroundColor: Colors.redAccent),
          );
        }
      } finally {
        if (mounted) setState(() => _isUpdating = false);
      }
    }
  }
}

class _PresetCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Map<String, bool> targetModules;
  final String desc;
  final bool isSelected;
  final bool isUpdating;
  final VoidCallback onTap;

  const _PresetCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.targetModules,
    required this.desc,
    required this.isSelected,
    required this.isUpdating,
    required this.onTap,
  });

  @override
  State<_PresetCard> createState() => _PresetCardState();
}

class _PresetCardState extends State<_PresetCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isUpdating ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 240,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.color.withValues(alpha: 0.08)
                : const Color(0xFF1C1C22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? widget.color
                  : (_isHovered ? Colors.white24 : Colors.white.withValues(alpha: 0.05)),
              width: 1.5,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: 0,
                    )
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: widget.isSelected ? widget.color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, size: 16, color: widget.isSelected ? widget.color : Colors.white30),
                  ),
                  if (widget.isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ACTIVE Preset',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: widget.isSelected ? Colors.white : Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.desc,
                style: TextStyle(
                  fontSize: 9.5,
                  height: 1.3,
                  color: widget.isSelected ? Colors.white70 : Colors.white30,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionToggleCard extends StatefulWidget {
  final String title;
  final String subtext;
  final String moduleKey;
  final bool isEnabled;
  final IconData icon;
  final Color activeColor;
  final bool isUpdating;
  final ValueChanged<bool> onChanged;

  const _PermissionToggleCard({
    required this.title,
    required this.subtext,
    required this.moduleKey,
    required this.isEnabled,
    required this.icon,
    required this.activeColor,
    required this.isUpdating,
    required this.onChanged,
  });

  @override
  State<_PermissionToggleCard> createState() => _PermissionToggleCardState();
}

class _PermissionToggleCardState extends State<_PermissionToggleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.isEnabled
              ? widget.activeColor.withValues(alpha: 0.04)
              : const Color(0xFF1C1C22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isEnabled
                ? (_isHovered ? widget.activeColor : widget.activeColor.withValues(alpha: 0.25))
                : (_isHovered ? Colors.white24 : Colors.white.withValues(alpha: 0.05)),
            width: 1.5,
          ),
          boxShadow: widget.isEnabled && _isHovered
              ? [
                  BoxShadow(
                    color: widget.activeColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    spreadRadius: 0,
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: widget.isEnabled
                        ? widget.activeColor.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 16,
                    color: widget.isEnabled ? widget.activeColor : Colors.white30,
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: widget.isEnabled,
                    activeColor: widget.activeColor,
                    activeTrackColor: widget.activeColor.withValues(alpha: 0.25),
                    inactiveThumbColor: Colors.white30,
                    inactiveTrackColor: Colors.white10,
                    onChanged: widget.isUpdating ? null : (val) => widget.onChanged(val),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              widget.title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: widget.isEnabled ? Colors.white : Colors.white38,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              widget.subtext,
              style: TextStyle(
                fontSize: 9.5,
                height: 1.25,
                color: widget.isEnabled ? Colors.white70 : Colors.white24,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  widget.isEnabled ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
                  size: 10,
                  color: widget.isEnabled ? Colors.greenAccent : Colors.redAccent.withValues(alpha: 0.35),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.isEnabled ? 'AUTHORIZED' : 'ACCESS REVOKED',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: widget.isEnabled ? Colors.greenAccent : Colors.redAccent.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

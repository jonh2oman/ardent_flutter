import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/user_data.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final corpsId = auth.userData?.corpsId;

    if (corpsId == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: ListView(
          children: [
            Row(
              children: [
                Icon(LucideIcons.shieldCheck, color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 16),
                const Text(
                  'ADMIN & PERMISSIONS',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.0),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Manage staff access and module permissions for your unit',
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 16),
            ),
            const SizedBox(height: 40),
            _UnitConfigCard(auth: auth),
            const SizedBox(height: 40),
            const Text(
              'STAFF PERMISSIONS',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white24, letterSpacing: 1.2),
            ),
            const SizedBox(height: 16),

            StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('corpsId', isEqualTo: corpsId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final users = snapshot.data!.docs
                      .map((doc) => UserData.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                      .toList();

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _buildUserCard(context, theme, user);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, ThemeData theme, UserData user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Text(user.firstName?[0] ?? '?', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
        ),
        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(user.position ?? 'No Position Assigned', style: const TextStyle(fontSize: 12, color: Colors.white30)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: user.isSupportAdmin 
              ? Colors.purpleAccent.withOpacity(0.1) 
              : (user.isAdmin ? Colors.blueAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            user.isSupportAdmin ? 'SYS ADMIN' : (user.isAdmin ? 'UNIT ADMIN' : 'STAFF'),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: user.isSupportAdmin 
                ? Colors.purpleAccent 
                : (user.isAdmin ? Colors.blueAccent : Colors.white30),
            ),
          ),
        ),
        children: [
          const Divider(color: Colors.white10, height: 32),
          _buildPermissionToggle(context, user, 'System Admin Access', 'isSupportAdmin', user.isSupportAdmin, isField: true),
          _buildPermissionToggle(context, user, 'Unit Admin Access', 'isAdmin', user.isAdmin, isField: true),
          const SizedBox(height: 12),
          const Text('MODULE PERMISSIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white24)),
          const SizedBox(height: 12),
          _buildModuleToggles(context, user),
        ],
      ),
    );
  }

  Widget _buildModuleToggles(BuildContext context, UserData user) {
    final modules = ['personnel', 'marksmanship', 'finance', 'orders', 'supply'];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: modules.map((m) {
        final hasAccess = user.permissions['modules']?[m] ?? false;
        return FilterChip(
          label: Text(m.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          selected: hasAccess,
          onSelected: (val) => _togglePermission(context, user, 'modules.$m', val),
          selectedColor: Colors.blueAccent.withOpacity(0.2),
          checkmarkColor: Colors.blueAccent,
        );
      }).toList(),
    );
  }

  Widget _buildPermissionToggle(BuildContext context, UserData user, String label, String key, bool value, {bool isField = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Switch(
          value: value,
          onChanged: (val) => _togglePermission(context, user, key, val, isField: isField),
          activeColor: Colors.greenAccent,
        ),
      ],
    );
  }

  void _togglePermission(BuildContext context, UserData user, String key, bool value, {bool isField = false}) async {
    final Map<String, dynamic> update = {};
    
    if (isField) {
      update[key] = value;
    } else if (key.startsWith('modules.')) {
      final moduleName = key.split('.')[1];
      final currentModules = Map<String, dynamic>.from(user.permissions['modules'] ?? {});
      currentModules[moduleName] = value;
      update['permissions.modules'] = currentModules;
    }

    await FirebaseFirestore.instance.collection('users').doc(user.id).update(update);
  }
}

class _UnitConfigCard extends StatefulWidget {
  final AuthProvider auth;
  const _UnitConfigCard({required this.auth});

  @override
  State<_UnitConfigCard> createState() => _UnitConfigCardState();
}

class _UnitConfigCardState extends State<_UnitConfigCard> {
  late TextEditingController _nameController;
  late TextEditingController _designationController;
  late TextEditingController _rankController;
  late TextEditingController _coNameController;
  late TextEditingController _websiteController;
  late TextEditingController _addressController;
  late TextEditingController _ordersHeaderEnController;
  late TextEditingController _ordersHeaderFrController;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final corps = widget.auth.corpsData;
    _nameController = TextEditingController(text: corps?.name);
    _designationController = TextEditingController(text: corps?.unitDesignation);
    _rankController = TextEditingController(text: corps?.coRank);
    _coNameController = TextEditingController(text: corps?.coName);
    _websiteController = TextEditingController(text: corps?.websiteUrl);
    _addressController = TextEditingController(text: corps?.address);
    _ordersHeaderEnController = TextEditingController(text: corps?.ordersHeaderEn);
    _ordersHeaderFrController = TextEditingController(text: corps?.ordersHeaderFr);
  }

  @override
  void didUpdateWidget(_UnitConfigCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update controllers if the corpsData itself changed significantly (e.g., loaded for the first time)
    if (oldWidget.auth.corpsData?.id != widget.auth.corpsData?.id) {
      _initControllers();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _designationController.dispose();
    _rankController.dispose();
    _coNameController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _ordersHeaderEnController.dispose();
    _ordersHeaderFrController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final corpsId = widget.auth.userData?.corpsId;
    if (corpsId == null) return;

    final settings = Map<String, dynamic>.from(widget.auth.corpsData?.settings ?? {});
    final unitInfo = Map<String, dynamic>.from(settings['unitInfo'] ?? {});
    
    unitInfo['unitDesignation'] = _designationController.text.trim();
    unitInfo['coRank'] = _rankController.text.trim();
    unitInfo['coName'] = _coNameController.text.trim();
    unitInfo['websiteUrl'] = _websiteController.text.trim();
    unitInfo['address'] = _addressController.text.trim();
    unitInfo['ordersHeaderEn'] = _ordersHeaderEnController.text.trim();
    unitInfo['ordersHeaderFr'] = _ordersHeaderFrController.text.trim();
    
    final List<String> divisions = List<String>.from(settings['divisions'] ?? []);
    
    settings['unitInfo'] = unitInfo;
    settings['divisions'] = divisions;

    await FirebaseFirestore.instance.collection('corps').doc(corpsId).update({
      'name': _nameController.text.trim(),
      'settings': settings,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unit Configuration Saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final corps = widget.auth.corpsData;
    final settings = corps?.settings ?? {};
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.building, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  const Text('UNIT CONFIGURATION', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ],
              ),
              TextButton.icon(
                onPressed: _save,
                icon: const Icon(LucideIcons.save, size: 16),
                label: const Text('SAVE CHANGES'),
                style: TextButton.styleFrom(foregroundColor: theme.colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo Preview & Upload
              Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: corps?.logoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(corps!.logoUrl!, fit: BoxFit.contain),
                          )
                        : const Icon(LucideIcons.image, color: Colors.white10, size: 32),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      try {
                        await widget.auth.uploadCorpsLogo();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Logo updated successfully')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Upload failed: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('UPDATE LOGO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  if (corps?.logoUrl != null)
                    TextButton(
                      onPressed: () async {
                        try {
                          await widget.auth.deleteCorpsLogo();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Logo removed')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                      child: const Text('REMOVE LOGO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(width: 24),
              // Config Fields
              Expanded(
                child: Column(
                  children: [
                    _buildField('Official Unit Name (e.g. 288 RCSCC ARDENT)', _nameController),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildField('Unit Designation', _designationController),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: _buildField('CO Rank', _rankController),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: _buildField('CO Name', _coNameController),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildField('Unit Website / Social Link', _websiteController),
                    const SizedBox(height: 16),
                    _buildField('Parade Location / Address', _addressController),
                    const SizedBox(height: 16),
                    _buildField('Orders Header Block (English)', _ordersHeaderEnController, maxLines: 3),
                    const SizedBox(height: 16),
                    _buildField('Orders Header Block (French)', _ordersHeaderFrController, maxLines: 3),
                    const SizedBox(height: 24),
                    _buildDivisionsSection(theme, settings),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: Colors.white30),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.black26,
      ),
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _buildDivisionsSection(ThemeData theme, Map<String, dynamic> settings) {
    final List<String> divisions = List<String>.from(settings['divisions'] ?? ['Main Deck', 'Quarterdeck', 'Forecastle', 'Aft Deck', 'Training Office']);
    final controller = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.users, size: 14, color: Colors.white30),
            const SizedBox(width: 8),
            Text('UNIT DIVISIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.primary, letterSpacing: 1.2)),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...divisions.map((d) => Chip(
              label: Text(d, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              deleteIcon: const Icon(LucideIcons.x, size: 12),
              onDeleted: () {
                final newDivs = List<String>.from(divisions)..remove(d);
                _updateDivisions(newDivs);
              },
            )).toList(),
            ActionChip(
              label: const Text('ADD DIVISION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              onPressed: () => _showAddDivisionDialog(divisions),
              backgroundColor: Colors.white.withOpacity(0.05),
              avatar: const Icon(LucideIcons.plus, size: 12),
            ),
          ],
        ),
      ],
    );
  }

  void _showAddDivisionDialog(List<String> currentDivisions) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Division'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g. Victory Division'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final newDivs = List<String>.from(currentDivisions)..add(controller.text.trim());
                _updateDivisions(newDivs);
                Navigator.pop(context);
              }
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateDivisions(List<String> divisions) async {
    final corpsId = widget.auth.userData?.corpsId;
    if (corpsId == null) return;

    final settings = Map<String, dynamic>.from(widget.auth.corpsData?.settings ?? {});
    settings['divisions'] = divisions;

    await FirebaseFirestore.instance.collection('corps').doc(corpsId).update({
      'settings': settings,
    });
  }
}

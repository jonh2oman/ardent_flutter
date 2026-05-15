import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';
import '../models/user_data.dart';
import 'cadet_detail_screen.dart';

class PersonnelScreen extends StatefulWidget {
  const PersonnelScreen({super.key});

  @override
  State<PersonnelScreen> createState() => _PersonnelScreenState();
}

class _PersonnelScreenState extends State<PersonnelScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    
    final List<dynamic> cadets = authProvider.corpsData?.settings['cadets'] ?? [];
    final List<dynamic> staff = authProvider.corpsData?.settings['staff'] ?? [];
    
    final filteredCadets = cadets.where((c) {
      final name = "${c['firstName']} ${c['lastName']}".toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PERSONNEL MANAGEMENT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Unit Roster',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.0),
              ),
              const SizedBox(height: 24),
              TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search by name or rank...',
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  filled: true,
                  fillColor: theme.colorScheme.surface.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            itemCount: filteredCadets.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.white.withOpacity(0.05)),
            itemBuilder: (context, index) {
              final cadet = filteredCadets[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    cadet['rank']?.substring(0, 1) ?? 'C',
                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  "${cadet['firstName']} ${cadet['lastName']}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "${cadet['rank'] ?? 'Cadet'} • Phase ${cadet['phase'] ?? 'N/A'}",
                  style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                ),
                trailing: Icon(LucideIcons.chevronRight, size: 16, color: theme.iconTheme.color?.withOpacity(0.3)),
                onTap: () {
                  final userData = UserData(
                    id: cadet['uid'] ?? '',
                    email: cadet['email'] ?? '',
                    firstName: cadet['firstName'],
                    lastName: cadet['lastName'],
                    rank: cadet['rank'] ?? 'Cadet',
                    corpsId: authProvider.userData?.corpsId ?? '',
                    element: authProvider.corpsData?.element ?? 'Sea',
                    dob: cadet['dob'] != null ? DateTime.tryParse(cadet['dob'].toString()) : null,
                    phase: cadet['phase']?.toString(),
                  );
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => CadetDetailScreen(cadet: userData))
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/user_data.dart';
import '../data/promotion_requirements.dart';

class PromotionScreen extends StatefulWidget {
  const PromotionScreen({super.key});

  @override
  State<PromotionScreen> createState() => _PromotionScreenState();
}

class _PromotionScreenState extends State<PromotionScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    
    final List<dynamic> rawCadets = auth.corpsData?.settings['cadets'] ?? [];
    final List<UserData> cadets = rawCadets.map((c) => UserData.fromMap(Map<String, dynamic>.from(c), c['uid'] ?? '')).toList();

    // Calculate eligibility for everyone
    final List<Map<String, dynamic>> results = cadets.map((c) {
      return {
        'cadet': c,
        'status': PromotionLogic.checkEligibility(c),
      };
    }).toList();

    final eligibleCount = results.where((r) => r['status']['eligible']).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROMOTION TRACKER',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Eligibility Status',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.0),
                    ),
                  ],
                ),
                _buildSummaryBadge(eligibleCount),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Eligible'),
                const SizedBox(width: 8),
                _buildFilterChip('Ineligible'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final result = results[index];
                final UserData cadet = result['cadet'];
                final Map<String, dynamic> status = result['status'];
                
                if (_filter == 'Eligible' && !status['eligible']) return const SizedBox.shrink();
                if (_filter == 'Ineligible' && status['eligible']) return const SizedBox.shrink();

                return _buildCadetRow(context, theme, cadet, status);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: count > 0 ? Colors.greenAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: count > 0 ? Colors.greenAccent : Colors.white10),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.award, size: 18, color: count > 0 ? Colors.greenAccent : Colors.white30),
          const SizedBox(width: 8),
          Text(
            '$count ELIGIBLE',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: count > 0 ? Colors.greenAccent : Colors.white30,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isActive = _filter == label;
    return InkWell(
      onTap: () => setState(() => _filter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).colorScheme.primary : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.black : Colors.white38,
          ),
        ),
      ),
    );
  }

  Widget _buildCadetRow(BuildContext context, ThemeData theme, UserData cadet, Map<String, dynamic> status) {
    final bool eligible = status['eligible'];
    final List<dynamic> reasons = status['reasons'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: (eligible ? Colors.greenAccent : Colors.orangeAccent).withOpacity(0.1),
            child: Icon(
              eligible ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle,
              color: eligible ? Colors.greenAccent : Colors.orangeAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cadet.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  '${cadet.rank ?? "Ordinary Cadet"} • Current Phase: ${cadet.phase ?? "N/A"}',
                  style: const TextStyle(color: Colors.white30, fontSize: 12),
                ),
              ],
            ),
          ),
          if (eligible)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('READY FOR', style: TextStyle(fontSize: 9, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                Text(
                  status['nextRank'].toString().toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: reasons.map((r) => Text(
                r.toString(),
                style: const TextStyle(fontSize: 10, color: Colors.orangeAccent, fontWeight: FontWeight.bold),
              )).toList(),
            ),
          const SizedBox(width: 20),
          if (eligible)
            ElevatedButton(
              onPressed: () => _promoteCadet(context, cadet, status['nextRank']),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('PROMOTE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  void _promoteCadet(BuildContext context, UserData cadet, String nextRank) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final corpsId = auth.userData?.corpsId;
    if (corpsId == null) return;

    final List<dynamic> cadets = List.from(auth.corpsData?.settings['cadets'] ?? []);
    final index = cadets.indexWhere((c) => c['uid'] == cadet.id);

    if (index != -1) {
      cadets[index]['rank'] = nextRank;
      cadets[index]['lastPromotionDate'] = DateTime.now().toIso8601String();
      
      await FirebaseFirestore.instance.collection('corps').doc(corpsId).update({
        'settings.cadets': cadets,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${cadet.name} promoted to $nextRank!')),
        );
      }
    }
  }
}

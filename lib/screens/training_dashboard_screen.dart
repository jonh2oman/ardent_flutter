import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../models/user_data.dart';
import '../data/curriculum.dart';

class TrainingDashboardScreen extends StatelessWidget {
  const TrainingDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    
    final List<dynamic> rawCadets = auth.corpsData?.settings['cadets'] ?? [];
    final List<UserData> cadets = rawCadets.map((c) => UserData.fromMap(Map<String, dynamic>.from(c), c['uid'] ?? '')).toList();

    // 1. Calculate live unit-wide Average Attendance (Present + Late / Present + Late + Absent)
    int totalPossible = 0;
    int totalPresent = 0;
    auth.attendance.forEach((dateId, statuses) {
      statuses.forEach((uid, status) {
        // Only calculate for active cadets currently in the roster
        bool isActiveCadet = cadets.any((c) => c.id == uid);
        if (isActiveCadet) {
          if (status == 'Present' || status == 'Late') {
            totalPresent++;
            totalPossible++;
          } else if (status == 'Absent') {
            totalPossible++;
          }
        }
      });
    });
    final String avgAttendanceStr = totalPossible > 0
        ? '${(totalPresent / totalPossible * 100).toInt()}%'
        : '100%';

    // 2. Calculate live Qualified Percentage (Average progress across respective phases)
    double totalProgressSum = 0;
    int cadetCount = 0;
    for (var c in cadets) {
      final phase = c.phase;
      if (phase != null && phase.isNotEmpty) {
        final totalEOs = Curriculum.getPhaseEOs(phase).length;
        if (totalEOs > 0) {
          final completed = c.trainingRecords[phase]?.length ?? 0;
          final progress = (completed / totalEOs).clamp(0.0, 1.0);
          totalProgressSum += progress;
          cadetCount++;
        }
      }
    }
    final String qualifiedPercent = cadetCount > 0
        ? '${(totalProgressSum / cadetCount * 100).toInt()}%'
        : '100%';

    // 3. Calculate last 4 parade nights attendance trends
    final sortedDates = auth.attendance.keys.toList()..sort((a, b) => b.compareTo(a));
    final latestNights = sortedDates.take(4).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.barChart2, color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 16),
                const Text(
                  'COMMAND DASHBOARD',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1.0),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Real-time training analytics across all phases',
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
            ),
            const SizedBox(height: 32),

            // Top Stats Row
            Row(
              children: [
                Expanded(child: _buildStatCard(theme, 'Total Cadets', cadets.length.toString(), LucideIcons.users, Colors.blueAccent)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(theme, 'Avg Attendance', avgAttendanceStr, LucideIcons.calendarCheck, Colors.greenAccent)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(theme, 'Avg Qualified', qualifiedPercent, LucideIcons.checkCircle, Colors.orangeAccent)),
              ],
            ),

            if (latestNights.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Text('RECENT ATTENDANCE TRENDS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white24, letterSpacing: 0.5)),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: latestNights.map((dateId) {
                    final statuses = auth.attendance[dateId] ?? {};
                    int nightPresent = 0;
                    int nightEligible = 0;
                    
                    statuses.forEach((uid, status) {
                      bool isActiveCadet = cadets.any((c) => c.id == uid);
                      if (isActiveCadet) {
                        if (status == 'Present' || status == 'Late') {
                          nightPresent++;
                          nightEligible++;
                        } else if (status == 'Absent') {
                          nightEligible++;
                        }
                      }
                    });
                    
                    final percent = nightEligible > 0 
                      ? (nightPresent / nightEligible * 100).toInt() 
                      : 100;
                      
                    String formattedDate = dateId;
                    try {
                      final parsed = DateTime.parse(dateId);
                      formattedDate = DateFormat('d MMM').format(parsed);
                    } catch (_) {}

                    return Container(
                      width: 130,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formattedDate.toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white30, letterSpacing: 0.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$percent%',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: percent >= 85
                                  ? Colors.greenAccent
                                  : percent >= 75
                                      ? Colors.amberAccent
                                      : Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$nightPresent / $nightEligible PRESENT',
                            style: const TextStyle(fontSize: 9, color: Colors.white24, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 32),
            const Text('PHASE PROGRESSION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white24, letterSpacing: 0.5)),
            const SizedBox(height: 16),

            // Phase Breakdown
            ...['Phase 1', 'Phase 2', 'Phase 3', 'Phase 4', 'Phase 5'].map((phase) {
              final phaseCadets = cadets.where((c) => c.phase == phase).toList();
              if (phaseCadets.isEmpty) return const SizedBox.shrink();
              
              return _buildPhaseProgressCard(theme, phase, phaseCadets);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(ThemeData theme, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.3), fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseProgressCard(ThemeData theme, String phase, List<UserData> cadets) {
    // Calculate aggregate progress for this phase
    double avgLessons = 0;
    if (cadets.isNotEmpty) {
      final int totalLessons = cadets.fold<int>(0, (sum, c) => sum + (c.trainingRecords[phase]?.length as int? ?? 0));
      avgLessons = totalLessons / cadets.length;
    }

    // Get actual curriculum size for this phase dynamically
    final int totalEOs = Curriculum.getPhaseEOs(phase).length;
    final double percent = totalEOs > 0 ? (avgLessons / totalEOs).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  phase.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${cadets.length} Cadets',
                style: const TextStyle(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.05),
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(percent * 100).toInt()}% QUALIFIED',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AVG ${avgLessons.toStringAsFixed(1)} / $totalEOs EOs COMPLETED',
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 10, color: Colors.white24, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

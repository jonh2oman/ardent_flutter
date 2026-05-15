import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../models/calendar.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    
    // Get calendar data from Firestore
    final Map<String, dynamic> trainingYear = authProvider.corpsData?.trainingYears['current'] ?? {};
    final Map<String, dynamic> calendarMap = trainingYear['calendar'] ?? {};
    
    // Sort dates
    final sortedDates = calendarMap.keys.toList()..sort();
    final upcomingDates = sortedDates.where((d) {
      final date = DateTime.parse(d);
      return date.isAfter(DateTime.now().subtract(const Duration(days: 1)));
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
                'TRAINING CALENDAR',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Upcoming Schedule',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.0),
              ),
            ],
          ),
        ),
        Expanded(
          child: upcomingDates.isEmpty 
            ? _buildEmptyState(theme)
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                itemCount: upcomingDates.length,
                itemBuilder: (context, index) {
                  final dateStr = upcomingDates[index];
                  final dayData = ParadeDay.fromMap(dateStr, calendarMap[dateStr]);
                  return _buildCalendarCard(context, theme, dayData);
                },
              ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.calendarX, size: 48, color: Colors.white10),
          const SizedBox(height: 16),
          const Text('No upcoming events scheduled', style: TextStyle(color: Colors.white30)),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(BuildContext context, ThemeData theme, ParadeDay day) {
    final date = DateTime.parse(day.date);
    final isLHQ = day.type == 'lhq';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isLHQ ? theme.colorScheme.primary.withOpacity(0.1) : Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isLHQ ? 'LHQ NIGHT' : day.type.toUpperCase(),
                    style: TextStyle(
                      color: isLHQ ? theme.colorScheme.primary : Colors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  DateFormat('EEEE, MMM d').format(date),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withOpacity(0.05)),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (day.title.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(day.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                  ),
                _buildPeriodRow(theme, 'Period 1', day.periods['1']),
                const SizedBox(height: 12),
                _buildPeriodRow(theme, 'Period 2', day.periods['2']),
                const SizedBox(height: 12),
                _buildPeriodRow(theme, 'Period 3', day.periods['3']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodRow(ThemeData theme, String title, dynamic periodData) {
    if (periodData == null) return const SizedBox.shrink();
    
    // In your web app, period data is a map of levels (Phase 1, 2, etc.)
    final Map<String, dynamic> levels = Map<String, dynamic>.from(periodData);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(title, style: const TextStyle(fontSize: 12, color: Colors.white30, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: levels.entries.map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${e.key}: ${e.value['lessonId'] ?? 'N/A'}",
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/marksmanship_provider.dart';
import '../models/marksmanship.dart';

enum MarksmanshipView { hub, teamEditor, relayDetail, scoring, practiceScoring }

class MarksmanshipScreen extends StatefulWidget {
  const MarksmanshipScreen({super.key});

  @override
  State<MarksmanshipScreen> createState() => _MarksmanshipScreenState();
}

class _MarksmanshipScreenState extends State<MarksmanshipScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MarksmanshipView _currentView = MarksmanshipView.hub;
  
  // Navigation State
  Team? _activeTeam;
  Relay? _activeRelay;
  FiringPoint? _activePoint;
  
  // Practice State
  Map<String, dynamic>? _practiceCadet;
  TargetType _practiceTargetType = TargetType.competition;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _navigateToHub() => setState(() => _currentView = MarksmanshipView.hub);
  void _navigateToTeamEditor(Team team) => setState(() {
    _activeTeam = team;
    _currentView = MarksmanshipView.teamEditor;
  });
  void _navigateToRelayDetail(Relay relay) => setState(() {
    _activeRelay = relay;
    _currentView = MarksmanshipView.relayDetail;
  });
  void _navigateToScoring(FiringPoint point) => setState(() {
    _activePoint = point;
    _currentView = MarksmanshipView.scoring;
  });

  void _navigateToPracticeScoring(Map<String, dynamic> cadet, TargetType type) => setState(() {
    _practiceCadet = cadet;
    _practiceTargetType = type;
    _currentView = MarksmanshipView.practiceScoring;
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MarksmanshipProvider>(context);

    switch (_currentView) {
      case MarksmanshipView.teamEditor:
        // Always get fresh team from provider to ensure state updates reflect
        final freshTeam = provider.getTeamById(_activeTeam?.id ?? '');
        return Scaffold(
          body: _TeamEditor(team: freshTeam ?? _activeTeam!, onBack: _navigateToHub),
        );
      case MarksmanshipView.relayDetail:
        final freshRelay = provider.getRelayById(_activeRelay?.id ?? '');
        return Scaffold(
          body: _RelayDetail(relay: freshRelay ?? _activeRelay!, onBack: _navigateToHub, onScore: _navigateToScoring),
        );
      case MarksmanshipView.scoring:
        final freshRelay = provider.getRelayById(_activeRelay?.id ?? '');
        return Scaffold(
          body: _ScoringScreen(
            relay: freshRelay ?? _activeRelay!, 
            point: _activePoint!, 
            onBack: () => _navigateToRelayDetail(_activeRelay!)
          ),
        );
      case MarksmanshipView.practiceScoring:
        final name = "${_practiceCadet?['firstName']} ${_practiceCadet?['lastName']}";
        return Scaffold(
          body: _ScoringScreen.practice(
            cadetId: _practiceCadet?['uid'] ?? 'unknown',
            cadetName: name,
            targetType: _practiceTargetType,
            onBack: _navigateToHub,
          ),
        );
      case MarksmanshipView.hub:
      default:
        return _buildHub(context);
    }
  }

  Widget _buildHub(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTeamsTab(context),
                _buildRelaysTab(context),
                _buildResultsTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MARKSMANSHIP SUITE',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2.0, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 8),
              const Text('Command Center', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.0)),
            ],
          ),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: theme.colorScheme.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            tabs: const [
              Tab(text: 'TEAMS', icon: Icon(LucideIcons.users, size: 18)),
              Tab(text: 'RELAYS', icon: Icon(LucideIcons.layers, size: 18)),
              Tab(text: 'RESULTS', icon: Icon(LucideIcons.trophy, size: 18)),
            ],
          ),
        ],
      ),
    );
  }

  // --- TAB: TEAMS ---
  Widget _buildTeamsTab(BuildContext context) {
    final provider = Provider.of<MarksmanshipProvider>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _showAddTeamDialog(context, provider),
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('REGISTER NEW TEAM'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: provider.teams.isEmpty
                ? const Center(child: Text('No teams registered', style: TextStyle(color: Colors.white24)))
                : ListView.separated(
                    itemCount: provider.teams.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) => _TeamCard(
                      team: provider.teams[index],
                      onTap: () => _navigateToTeamEditor(provider.teams[index]),
                      onDelete: () => provider.removeTeam(provider.teams[index].id),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- TAB: RELAYS ---
  Widget _buildRelaysTab(BuildContext context) {
    final provider = Provider.of<MarksmanshipProvider>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => provider.addRelay(10),
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('NEW RELAY'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: provider.relays.isEmpty
                ? const Center(child: Text('No relays created', style: TextStyle(color: Colors.white24)))
                : ListView.separated(
                    itemCount: provider.relays.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) => _RelayCard(
                      relay: provider.relays[index],
                      onTap: () => _navigateToRelayDetail(provider.relays[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsTab(BuildContext context) {
    final provider = Provider.of<MarksmanshipProvider>(context);
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('INDIVIDUAL PRACTICE LOG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 1.5)),
              ElevatedButton.icon(
                onPressed: () => _showQuickScoreDialog(context),
                icon: const Icon(LucideIcons.zap, size: 16),
                label: const Text('QUICK SCORE'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: provider.practiceScores.isEmpty
                ? const Center(child: Text('No practice scores recorded', style: TextStyle(color: Colors.white24)))
                : ListView.builder(
                    itemCount: provider.practiceScores.length,
                    itemBuilder: (context, index) {
                      final s = provider.practiceScores[index];
                      final isGrouping = s.targetType == TargetType.grouping;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                            child: Icon(isGrouping ? LucideIcons.target : LucideIcons.award, size: 16, color: theme.colorScheme.primary),
                          ),
                          title: Text(s.cadetName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${isGrouping ? "Grouping" : "Competition"} • ${DateFormat('MMM d, HH:mm').format(s.timestamp)}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (isGrouping)
                                Text('${s.groupingMm?.toStringAsFixed(2)}cm', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.greenAccent))
                              else
                                Text('${s.score} pts', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                              if (!isGrouping && (s.innerTens ?? 0) > 0)
                                Text('${s.innerTens} IT', style: const TextStyle(fontSize: 10, color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showQuickScoreDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final List<dynamic> cadets = authProvider.corpsData?.settings?['cadets'] ?? [];
    Map<String, dynamic>? selectedCadet;
    TargetType selectedType = TargetType.competition;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {

          return AlertDialog(
            title: const Text('Quick Score'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCadet?['uid'],
                  decoration: const InputDecoration(labelText: 'Select Cadet'),
                  items: cadets.map((c) => DropdownMenuItem<String>(
                    value: c['uid'], 
                    child: Text("${c['firstName']} ${c['lastName']}")
                  )).toList(),
                  onChanged: (v) {
                    final cadet = cadets.firstWhere((c) => c['uid'] == v);
                    setDialogState(() => selectedCadet = Map<String, dynamic>.from(cadet));
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TargetType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Target Type'),
                  items: const [
                    DropdownMenuItem(value: TargetType.competition, child: Text('Competition (Score)')),
                    DropdownMenuItem(value: TargetType.grouping, child: Text('Grouping (cm)')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedType = v!),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
              ElevatedButton(
                onPressed: selectedCadet == null ? null : () {
                  final cadet = selectedCadet!;
                  final type = selectedType;
                  // Clear local static state for next time
                  selectedCadet = null;
                  selectedType = TargetType.competition;
                  Navigator.pop(ctx);
                  _navigateToPracticeScoring(cadet, type);
                },
                child: const Text('START SCORING'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddTeamDialog(BuildContext context, MarksmanshipProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Register New Team'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Team Name / Unit'),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.addTeam(controller.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }
}

// --- SUB-WIDGETS ---

class _TeamCard extends StatelessWidget {
  final Team team;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TeamCard({required this.team, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: team.isValid ? const Color(0xFF10B981).withOpacity(0.3) : Colors.white10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                _StatusBadge(isValid: team.isValid),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(team.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        '${team.members.length}/5 Members • ${team.juniorCount} Juniors',
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.white10),
                  onPressed: onDelete,
                ),
                const Icon(LucideIcons.chevronRight, color: Colors.white10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RelayCard extends StatelessWidget {
  final Relay relay;
  final VoidCallback onTap;

  const _RelayCard({required this.relay, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filledLanes = relay.firingPoints.where((p) => p.competitorName != null).length;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: relay.isActive ? const Color(0xFF10B981).withOpacity(0.3) : Colors.white10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: relay.isActive ? const Color(0xFF10B981).withOpacity(0.1) : Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text('${relay.number}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: relay.isActive ? const Color(0xFF10B981) : Colors.white70)),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RELAY ${relay.number}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('$filledLanes / ${relay.firingPoints.length} Lanes Filled', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, color: Colors.white10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isValid;
  const _StatusBadge({required this.isValid});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isValid ? const Color(0xFF10B981).withOpacity(0.1) : Colors.red.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isValid ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
        color: isValid ? const Color(0xFF10B981) : Colors.redAccent,
        size: 24,
      ),
    );
  }
}

// --- VIEW: TEAM EDITOR ---
class _TeamEditor extends StatelessWidget {
  final Team team;
  final VoidCallback onBack;

  const _TeamEditor({required this.team, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MarksmanshipProvider>(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: Row(
            children: [
              IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: onBack),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TEAM EDITOR', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.w900)),
                  Text(team.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                ],
              ),
              const Spacer(),
              _ValidationHeader(team: team),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            itemCount: team.members.length,
            itemBuilder: (context, index) => _MemberCard(
              member: team.members[index],
              onDelete: () {
                final members = List<Competitor>.from(team.members)..removeAt(index);
                provider.updateTeam(team.copyWith(members: members));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Member removed from team')),
                );
              },
            ),
          ),
        ),
        if (team.members.length < 5)
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: FloatingActionButton.extended(
              onPressed: () => _showAddMemberDialog(context, provider),
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.black,
              icon: const Icon(LucideIcons.userPlus),
              label: const Text('ADD MEMBER'),
            ),
          ),
      ],
    );
  }

  void _showAddMemberDialog(BuildContext context, MarksmanshipProvider provider) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final List<dynamic> cadets = authProvider.corpsData?.settings?['cadets'] ?? [];
    
    // Filter out cadets already in the team
    final availableCadets = cadets.where((c) {
      final name = "${c['firstName']} ${c['lastName']}";
      return !team.members.any((m) => m.name == name);
    }).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Team Member'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Cadet from Roster', style: TextStyle(fontSize: 12, color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 12),
              if (availableCadets.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No more cadets available in roster.', style: TextStyle(color: Colors.white24, fontSize: 13)),
                )
              else
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableCadets.length,
                    itemBuilder: (context, index) {
                      final c = availableCadets[index];
                      final name = "${c['firstName'] ?? 'Unknown'} ${c['lastName'] ?? 'Cadet'}";
                      final rank = c['rank'] ?? 'Cadet';
                      
                      // Handle both String (ISO8601) and Firestore Timestamp
                      DateTime? dob;
                      final rawDob = c['dob'];
                      if (rawDob is String) {
                        dob = DateTime.tryParse(rawDob);
                      } else if (rawDob is Timestamp) {
                        dob = rawDob.toDate();
                      }
                      
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          child: Text(rank.isNotEmpty ? rank[0] : 'C', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.primary)),
                        ),
                        title: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: Text('$rank • ${dob != null ? DateFormat('MMM d, yyyy').format(dob) : "No DOB Record"}', style: const TextStyle(fontSize: 11)),
                        onTap: () {
                          final member = Competitor(
                            id: c['uid'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                            name: name,
                            rank: rank,
                            dob: dob ?? DateTime.now().subtract(const Duration(days: 365 * 12)), // Fallback for age calc
                          );
                          provider.updateTeam(team.copyWith(members: [...team.members, member]));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$name added to ${team.name}')),
                          );
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
        ],
      ),
    );
  }
}

// --- VIEW: RELAY DETAIL ---
class _RelayDetail extends StatelessWidget {
  final Relay relay;
  final VoidCallback onBack;
  final Function(FiringPoint) onScore;

  const _RelayDetail({required this.relay, required this.onBack, required this.onScore});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MarksmanshipProvider>(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: Row(
            children: [
              IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: onBack),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RELAY MANAGEMENT', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.w900)),
                  Text('RELAY ${relay.number}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: Icon(LucideIcons.power, color: relay.isActive ? const Color(0xFF10B981) : Colors.white38),
                onPressed: () => provider.toggleRelayActive(relay.id),
              ),
              IconButton(
                icon: const Icon(LucideIcons.trash2, color: Colors.redAccent),
                onPressed: () {
                  provider.removeRelay(relay.id);
                  onBack();
                },
              ),
            ],
          ),
        ),
        _TeamAssignmentHeader(relay: relay),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            itemCount: relay.firingPoints.length,
            itemBuilder: (context, index) => _LaneCard(
              point: relay.firingPoints[index],
              relay: relay,
              onScore: () => onScore(relay.firingPoints[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _TeamAssignmentHeader extends StatelessWidget {
  final Relay relay;
  const _TeamAssignmentHeader({required this.relay});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MarksmanshipProvider>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: DropdownButtonFormField<String>(
        value: relay.teamId,
        decoration: const InputDecoration(labelText: 'Assign Team to Relay', border: OutlineInputBorder()),
        items: provider.teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
        onChanged: (id) {
          if (id != null) provider.updateRelay(relay.copyWith(teamId: id));
        },
      ),
    );
  }
}

class _LaneCard extends StatelessWidget {
  final FiringPoint point;
  final Relay relay;
  final VoidCallback onScore;

  const _LaneCard({required this.point, required this.relay, required this.onScore});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MarksmanshipProvider>(context);
    final theme = Theme.of(context);
    final isAssigned = point.competitorName != null;

    String? subtitle;
    Color? subtitleColor;
    
    if (point.targetType == TargetType.competition && point.score != null) {
      subtitle = 'Score: ${point.score}/100 (${point.innerTens} IT)';
      subtitleColor = const Color(0xFF10B981);
    } else if (point.targetType == TargetType.grouping && point.groupingMm != null) {
      final classification = _getGroupingClassification(point.groupingMm!);
      subtitle = 'Grouping: ${point.groupingMm}cm ($classification)';
      subtitleColor = _getGroupingColor(classification);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAssigned ? theme.colorScheme.primary : Colors.white10,
          child: Text('${point.laneNumber}', style: TextStyle(color: isAssigned ? Colors.white : Colors.white24)),
        ),
        title: Text(point.competitorName ?? 'EMPTY LANE', style: TextStyle(color: isAssigned ? Colors.white : Colors.white24)),
        subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: subtitleColor, fontWeight: FontWeight.bold)) : null,
        trailing: isAssigned 
            ? ElevatedButton(onPressed: onScore, child: const Text('SCORE'))
            : const Icon(LucideIcons.edit3, size: 18, color: Colors.white10),
        onTap: () => _showEditLaneDialog(context, provider),
      ),
    );
  }

  String _getGroupingClassification(double cm) {
    if (cm <= 1.5) return 'DISTINGUISHED';
    if (cm <= 2.0) return 'EXPERT';
    if (cm <= 2.5) return 'FIRST CLASS';
    if (cm <= 3.0) return 'MARKSMAN';
    return 'BELOW CLASSIFICATION';
  }

  Color _getGroupingColor(String classification) {
    switch (classification) {
      case 'DISTINGUISHED': return const Color(0xFFFACC15);
      case 'EXPERT':        return const Color(0xFFE2E8F0);
      case 'FIRST CLASS':   return const Color(0xFFFB923C);
      case 'MARKSMAN':      return const Color(0xFF38BDF8);
      default:              return Colors.white24;
    }
  }

  void _showEditLaneDialog(BuildContext context, MarksmanshipProvider provider) {
    final nameController = TextEditingController(text: point.competitorName);
    final team = relay.teamId != null ? provider.getTeamById(relay.teamId!) : null;
    TargetType selectedTargetType = point.targetType;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Lane ${point.laneNumber} Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (team != null) ...[
                const Text('Select Team Member', style: TextStyle(fontSize: 12, color: Colors.white38)),
                const SizedBox(height: 8),
                DropdownButtonFormField<Competitor>(
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  value: team.members.any((m) => m.name == point.competitorName) 
                      ? team.members.firstWhere((m) => m.name == point.competitorName) 
                      : null,
                  items: team.members.map((m) => DropdownMenuItem(value: m, child: Text('${m.rank} ${m.name}'))).toList(),
                  onChanged: (m) {
                    if (m != null) nameController.text = m.name;
                  },
                ),
              ] else
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Competitor Name')),
              const SizedBox(height: 24),
              const Text('Target Type', style: TextStyle(fontSize: 12, color: Colors.white38)),
              const SizedBox(height: 8),
              SegmentedButton<TargetType>(
                segments: const [
                  ButtonSegment(value: TargetType.grouping, label: Text('GROUPING'), icon: Icon(LucideIcons.target)),
                  ButtonSegment(value: TargetType.competition, label: Text('COMP'), icon: Icon(LucideIcons.trophy)),
                ],
                selected: {selectedTargetType},
                onSelectionChanged: (set) => setDialogState(() => selectedTargetType = set.first),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () {
                provider.updateFiringPoint(
                  relay.id, 
                  point.laneNumber, 
                  point.copyWith(
                    competitorName: nameController.text.isEmpty ? null : nameController.text,
                    targetType: selectedTargetType,
                  )
                );
                Navigator.pop(ctx);
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- VIEW: SCORING SCREEN ---
class _ScoringScreen extends StatefulWidget {
  final Relay? relay;
  final FiringPoint? point;
  
  // Practice Mode fields
  final String? cadetId;
  final String? cadetName;
  final TargetType? practiceTargetType;

  final VoidCallback onBack;

  const _ScoringScreen({super.key, required Relay this.relay, required FiringPoint this.point, required this.onBack}) 
    : cadetId = null, cadetName = null, practiceTargetType = null;

  const _ScoringScreen.practice({super.key, required String this.cadetId, required String this.cadetName, required TargetType targetType, required this.onBack})
    : relay = null, point = null, practiceTargetType = targetType;

  @override
  State<_ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends State<_ScoringScreen> {
  // Competition Controllers
  final List<TextEditingController> _controllers = List.generate(10, (_) => TextEditingController());
  final List<bool> _innerTens = List.generate(10, (_) => false);

  // Grouping Controllers
  final _diag1Controller = TextEditingController();
  final _diag2Controller = TextEditingController();
  double? _diag1;
  double? _diag2;

  int get _totalScore => _controllers.fold(0, (sum, ctrl) {
    final val = int.tryParse(ctrl.text) ?? 0;
    return sum + (val > 10 ? 10 : val);
  });
  int get _totalInnerTens => _innerTens.where((it) => it).length;

  double? get _effectiveGrouping => (_diag1 != null && _diag2 != null) 
      ? (_diag1! > _diag2! ? _diag1! : _diag2!) 
      : null;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MarksmanshipProvider>(context);
    final isGrouping = widget.point != null 
        ? widget.point!.targetType == TargetType.grouping
        : widget.practiceTargetType == TargetType.grouping;

    return Column(
      children: [
        _buildScoringHeader(context),
        Expanded(
          child: isGrouping ? _buildGroupingInterface() : _buildCompetitionInterface(),
        ),
        _buildSaveButton(provider, isGrouping),
      ],
    );
  }

  Widget _buildScoringHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        children: [
          IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: widget.onBack),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (widget.point?.targetType == TargetType.grouping || widget.practiceTargetType == TargetType.grouping) ? 'GROUPING CALCULATOR' : 'SCORING SHEET',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              Text(widget.point?.competitorName ?? widget.cadetName ?? 'Competitor', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
            ],
          ),
          const Spacer(),
          if (widget.point?.targetType == TargetType.competition || widget.practiceTargetType == TargetType.competition)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  const Text('TOTAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  Text('$_totalScore', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompetitionInterface() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      itemCount: 10,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: CircleAvatar(radius: 14, child: Text('${index + 1}', style: const TextStyle(fontSize: 10))),
          title: TextField(
            controller: _controllers[index],
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(hintText: '-', border: InputBorder.none),
            onChanged: (_) => setState(() {}),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('IT?', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38)),
              Switch(
                value: _innerTens[index],
                activeColor: const Color(0xFFFACC15),
                onChanged: (v) => setState(() => _innerTens[index] = v),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupingInterface() {
    final cm = _effectiveGrouping;
    final classification = cm != null ? _getClassification(cm) : null;
    final statusColor = classification != null ? _getStatusColor(classification) : Colors.white10;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildGroupInput('DIAGRAM 1', _diag1Controller, (v) => setState(() => _diag1 = double.tryParse(v)))),
              const SizedBox(width: 16),
              Expanded(child: _buildGroupInput('DIAGRAM 2', _diag2Controller, (v) => setState(() => _diag2 = double.tryParse(v)))),
            ],
          ),
          const SizedBox(height: 40),
          if (classification != null)
            Container(
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: statusColor.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Text('CLASSIFICATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor.withOpacity(0.5), letterSpacing: 2)),
                  const SizedBox(height: 12),
                  Text(classification, textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: statusColor)),
                  const SizedBox(height: 8),
                  Text('${cm!.toStringAsFixed(2)} cm', style: const TextStyle(color: Colors.white38, fontSize: 14)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupInput(String label, TextEditingController controller, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: '0.00',
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSaveButton(MarksmanshipProvider provider, bool isGrouping) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            if (isGrouping) {
              if (_effectiveGrouping != null) {
                if (widget.relay != null && widget.point != null) {
                  // Relay Mode
                  final updatedPoint = widget.point!.copyWith(groupingMm: _effectiveGrouping);
                  final points = List<FiringPoint>.from(widget.relay!.firingPoints);
                  final idx = points.indexWhere((p) => p.laneNumber == widget.point!.laneNumber);
                  points[idx] = updatedPoint;
                  provider.updateRelay(widget.relay!.copyWith(firingPoints: points));
                } else {
                  // Practice Mode
                  provider.addPracticeScore(PracticeScore(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    cadetId: widget.cadetId!,
                    cadetName: widget.cadetName!,
                    targetType: TargetType.grouping,
                    groupingMm: _effectiveGrouping,
                    timestamp: DateTime.now(),
                  ));
                }
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Grouping score saved')));
                widget.onBack();
              }
            } else {
              if (widget.relay != null && widget.point != null) {
                // Relay Mode
                final updatedPoint = widget.point!.copyWith(score: _totalScore, innerTens: _totalInnerTens);
                final points = List<FiringPoint>.from(widget.relay!.firingPoints);
                final idx = points.indexWhere((p) => p.laneNumber == widget.point!.laneNumber);
                points[idx] = updatedPoint;
                provider.updateRelay(widget.relay!.copyWith(firingPoints: points));
              } else {
                // Practice Mode
                provider.addPracticeScore(PracticeScore(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  cadetId: widget.cadetId!,
                  cadetName: widget.cadetName!,
                  targetType: TargetType.competition,
                  score: _totalScore,
                  innerTens: _totalInnerTens,
                  timestamp: DateTime.now(),
                ));
              }
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Competition score saved')));
              widget.onBack();
            }
          },
          icon: const Icon(LucideIcons.save),
          label: const Text('SAVE RESULTS'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.all(24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }

  String _getClassification(double cm) {
    if (cm <= 1.5) return 'DISTINGUISHED';
    if (cm <= 2.0) return 'EXPERT';
    if (cm <= 2.5) return 'FIRST CLASS';
    if (cm <= 3.0) return 'MARKSMAN';
    return 'BELOW CLASSIFICATION';
  }

  Color _getStatusColor(String classification) {
    switch (classification) {
      case 'DISTINGUISHED': return const Color(0xFFFACC15);
      case 'EXPERT':        return const Color(0xFFE2E8F0);
      case 'FIRST CLASS':   return const Color(0xFFFB923C);
      case 'MARKSMAN':      return const Color(0xFF38BDF8);
      default:              return Colors.white24;
    }
  }
}

class _MemberCard extends StatelessWidget {
  final Competitor member;
  final VoidCallback onDelete;

  const _MemberCard({required this.member, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isJunior = member.level == CompetitorLevel.junior;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(child: Text(member.rank.isNotEmpty ? member.rank[0] : 'C')),
        title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Level: ${isJunior ? 'JUNIOR' : 'SENIOR'} • Age: ${member.age}'),
        trailing: IconButton(icon: const Icon(LucideIcons.trash2, size: 18), onPressed: onDelete),
      ),
    );
  }
}

class _ValidationHeader extends StatelessWidget {
  final Team team;
  const _ValidationHeader({required this.team});

  @override
  Widget build(BuildContext context) {
    final isValid = team.isValid;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isValid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isValid ? Colors.green : Colors.redAccent),
      ),
      child: Column(
        children: [
          Text(isValid ? 'TEAM VALID' : 'TEAM INVALID', style: TextStyle(fontWeight: FontWeight.bold, color: isValid ? Colors.green : Colors.redAccent)),
          Text('${team.members.length}/5 Members • ${team.juniorCount}/2 Juniors', style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/marksmanship.dart';

class MarksmanshipProvider with ChangeNotifier {
  static const _teamStorageKey = 'marksmanship_teams_v1';
  static const _relayStorageKey = 'marksmanship_relays_v1';
  static const _practiceStorageKey = 'marksmanship_practice_v1';
  final _uuid = const Uuid();
  
  List<Team> _teams = [];
  List<Relay> _relays = [];
  List<PracticeScore> _practiceScores = [];

  String? _corpsId;
  StreamSubscription? _teamsSubscription;
  StreamSubscription? _relaysSubscription;
  StreamSubscription? _practiceSubscription;

  List<Team> get teams => _teams;
  List<Relay> get relays => _relays;
  List<PracticeScore> get practiceScores => _practiceScores;

  MarksmanshipProvider() {
    _loadState();
  }

  void init(String corpsId) {
    if (_corpsId == corpsId) return;
    _corpsId = corpsId;
    
    // Cancel any existing active subscriptions
    _teamsSubscription?.cancel();
    _relaysSubscription?.cancel();
    _practiceSubscription?.cancel();
    
    final db = FirebaseFirestore.instance;
    final corpsRef = db.collection('corps').doc(corpsId);
    
    // Subscribe to Teams
    _teamsSubscription = corpsRef.collection('marksmanship_teams').snapshots().listen((snapshot) {
      _teams = snapshot.docs.map((doc) => Team.fromJson(doc.data())).toList();
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error listening to marksmanship teams: $e');
    });

    // Subscribe to Relays
    _relaysSubscription = corpsRef.collection('marksmanship_relays').snapshots().listen((snapshot) {
      _relays = snapshot.docs.map((doc) => Relay.fromJson(doc.data())).toList();
      _relays.sort((a, b) => a.number.compareTo(b.number));
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error listening to marksmanship relays: $e');
    });

    // Subscribe to Practice Scores
    _practiceSubscription = corpsRef.collection('marksmanship_practice').snapshots().listen((snapshot) {
      _practiceScores = snapshot.docs.map((doc) => PracticeScore.fromJson(doc.data())).toList();
      _practiceScores.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error listening to marksmanship practice scores: $e');
    });
  }

  void logout() {
    _corpsId = null;
    _teamsSubscription?.cancel();
    _relaysSubscription?.cancel();
    _practiceSubscription?.cancel();
    _teams = [];
    _relays = [];
    _practiceScores = [];
    notifyListeners();
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load Teams
      final teamData = prefs.getString(_teamStorageKey);
      if (teamData != null) {
        final decoded = jsonDecode(teamData) as List;
        _teams = decoded.map((t) => Team.fromJson(t)).toList();
      }

      // Load Relays
      final relayData = prefs.getString(_relayStorageKey);
      if (relayData != null) {
        final decoded = jsonDecode(relayData) as List;
        _relays = decoded.map((r) => Relay.fromJson(r)).toList();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading local marksmanship state: $e');
    }
  }

  Future<void> _saveState() async {
    // Only save locally if not synced with Firestore (no corps ID)
    if (_corpsId != null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final teamData = jsonEncode(_teams.map((t) => t.toJson()).toList());
      await prefs.setString(_teamStorageKey, teamData);

      final relayData = jsonEncode(_relays.map((r) => r.toJson()).toList());
      await prefs.setString(_relayStorageKey, relayData);

      final practiceData = jsonEncode(_practiceScores.map((p) => p.toJson()).toList());
      await prefs.setString(_practiceStorageKey, practiceData);
    } catch (e) {
      debugPrint('Error saving local marksmanship state: $e');
    }
  }

  // Team Management
  void addTeam(String name) {
    final team = Team(id: _uuid.v4(), name: name, members: []);
    if (_corpsId != null) {
      FirebaseFirestore.instance
          .collection('corps')
          .doc(_corpsId!)
          .collection('marksmanship_teams')
          .doc(team.id)
          .set(team.toJson());
    } else {
      _teams.add(team);
      notifyListeners();
      _saveState();
    }
  }

  void removeTeam(String id) {
    if (_corpsId != null) {
      FirebaseFirestore.instance
          .collection('corps')
          .doc(_corpsId!)
          .collection('marksmanship_teams')
          .doc(id)
          .delete();
    } else {
      _teams.removeWhere((t) => t.id == id);
      notifyListeners();
      _saveState();
    }
  }

  void updateTeam(Team updated) {
    if (_corpsId != null) {
      FirebaseFirestore.instance
          .collection('corps')
          .doc(_corpsId!)
          .collection('marksmanship_teams')
          .doc(updated.id)
          .set(updated.toJson());
    } else {
      final index = _teams.indexWhere((t) => t.id == updated.id);
      if (index != -1) {
        _teams[index] = updated;
        notifyListeners();
        _saveState();
      }
    }
  }

  // Relay Management
  void addRelay(int lanes) {
    final number = _relays.length + 1;
    final points = List.generate(lanes, (i) => FiringPoint(laneNumber: i + 1));
    final relay = Relay(id: _uuid.v4(), number: number, firingPoints: points);
    if (_corpsId != null) {
      FirebaseFirestore.instance
          .collection('corps')
          .doc(_corpsId!)
          .collection('marksmanship_relays')
          .doc(relay.id)
          .set(relay.toJson());
    } else {
      _relays.add(relay);
      notifyListeners();
      _saveState();
    }
  }

  void removeRelay(String id) {
    if (_corpsId != null) {
      final db = FirebaseFirestore.instance;
      final corpsRef = db.collection('corps').doc(_corpsId!);
      
      db.runTransaction((transaction) async {
        // Delete target relay
        transaction.delete(corpsRef.collection('marksmanship_relays').doc(id));
        
        // Fetch all remaining relays to renumber them
        final remainingDocs = await corpsRef.collection('marksmanship_relays').get();
        final remainingRelays = remainingDocs.docs
            .map((doc) => Relay.fromJson(doc.data()))
            .where((r) => r.id != id)
            .toList();
            
        remainingRelays.sort((a, b) => a.number.compareTo(b.number));
        
        for (int i = 0; i < remainingRelays.length; i++) {
          final updatedRelay = remainingRelays[i].copyWith(number: i + 1);
          transaction.set(
            corpsRef.collection('marksmanship_relays').doc(updatedRelay.id),
            updatedRelay.toJson(),
          );
        }
      });
    } else {
      _relays.removeWhere((r) => r.id == id);
      // Renumber remaining relays
      for (int i = 0; i < _relays.length; i++) {
        _relays[i] = Relay(
          id: _relays[i].id,
          number: i + 1,
          firingPoints: _relays[i].firingPoints,
          isActive: _relays[i].isActive,
          teamId: _relays[i].teamId,
        );
      }
      notifyListeners();
      _saveState();
    }
  }

  void updateRelay(Relay updated) {
    if (_corpsId != null) {
      FirebaseFirestore.instance
          .collection('corps')
          .doc(_corpsId!)
          .collection('marksmanship_relays')
          .doc(updated.id)
          .set(updated.toJson());
    } else {
      final index = _relays.indexWhere((r) => r.id == updated.id);
      if (index != -1) {
        _relays[index] = updated;
        notifyListeners();
        _saveState();
      }
    }
  }

  void updateFiringPoint(String relayId, int lane, FiringPoint updatedPoint) {
    final relayIndex = _relays.indexWhere((r) => r.id == relayId);
    if (relayIndex != -1) {
      final points = List<FiringPoint>.from(_relays[relayIndex].firingPoints);
      final pointIndex = points.indexWhere((p) => p.laneNumber == lane);
      if (pointIndex != -1) {
        points[pointIndex] = updatedPoint;
        final updatedRelay = _relays[relayIndex].copyWith(firingPoints: points);
        if (_corpsId != null) {
          FirebaseFirestore.instance
              .collection('corps')
              .doc(_corpsId!)
              .collection('marksmanship_relays')
              .doc(relayId)
              .set(updatedRelay.toJson());
        } else {
          _relays[relayIndex] = updatedRelay;
          notifyListeners();
          _saveState();
        }
      }
    }
  }

  void toggleRelayActive(String id) {
    final index = _relays.indexWhere((r) => r.id == id);
    if (index != -1) {
      final updatedRelay = _relays[index].copyWith(isActive: !_relays[index].isActive);
      if (_corpsId != null) {
        FirebaseFirestore.instance
            .collection('corps')
            .doc(_corpsId!)
            .collection('marksmanship_relays')
            .doc(id)
            .set(updatedRelay.toJson());
      } else {
        _relays[index] = updatedRelay;
        notifyListeners();
        _saveState();
      }
    }
  }

  void saveCompetitionScore(String relayId, int lane, int score, int innerTens) {
    final relay = _relays.firstWhere((r) => r.id == relayId);
    final point = relay.firingPoints.firstWhere((p) => p.laneNumber == lane);
    updateFiringPoint(relayId, lane, point.copyWith(score: score, innerTens: innerTens));
  }

  void saveGroupingScore(String relayId, int lane, double mm) {
    final relay = _relays.firstWhere((r) => r.id == relayId);
    final point = relay.firingPoints.firstWhere((p) => p.laneNumber == lane);
    updateFiringPoint(relayId, lane, point.copyWith(groupingMm: mm));
  }

  Team? getTeamById(String id) {
    try {
      return _teams.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Relay? getRelayById(String id) {
    try {
      return _relays.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  // Practice Management
  void addPracticeScore(PracticeScore score) {
    if (_corpsId != null) {
      FirebaseFirestore.instance
          .collection('corps')
          .doc(_corpsId!)
          .collection('marksmanship_practice')
          .doc(score.id)
          .set(score.toJson());
    } else {
      _practiceScores.insert(0, score); // Newest first
      notifyListeners();
      _saveState();
    }
  }

  void removePracticeScore(String id) {
    if (_corpsId != null) {
      FirebaseFirestore.instance
          .collection('corps')
          .doc(_corpsId!)
          .collection('marksmanship_practice')
          .doc(id)
          .delete();
    } else {
      _practiceScores.removeWhere((s) => s.id == id);
      notifyListeners();
      _saveState();
    }
  }

  @override
  void dispose() {
    _teamsSubscription?.cancel();
    _relaysSubscription?.cancel();
    _practiceSubscription?.cancel();
    super.dispose();
  }
}

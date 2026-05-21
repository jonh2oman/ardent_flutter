import 'package:uuid/uuid.dart';

enum CompetitorLevel { junior, senior }
enum TargetType { grouping, competition }

class Competitor {
  final String id;
  final String name;
  final String rank;
  final DateTime dob;

  Competitor({
    required this.id,
    required this.name,
    required this.rank,
    required this.dob,
  });

  int get age {
    final now = DateTime.now();
    // Rule: Age as of Jan 1st of the current year
    final jan1 = DateTime(now.year, 1, 1);
    int age = jan1.year - dob.year;
    if (jan1.month < dob.month || (jan1.month == dob.month && jan1.day < dob.day)) {
      age--;
    }
    return age;
  }

  CompetitorLevel get level => age < 15 ? CompetitorLevel.junior : CompetitorLevel.senior;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'rank': rank,
    'dob': dob.toIso8601String(),
  };

  factory Competitor.fromJson(Map<String, dynamic> json) => Competitor(
    id: json['id'],
    name: json['name'],
    rank: json['rank'],
    dob: DateTime.parse(json['dob']),
  );
}

class Team {
  final String id;
  final String name;
  final List<Competitor> members;

  Team({
    required this.id,
    required this.name,
    required this.members,
  });

  int get juniorCount => members.where((m) => m.level == CompetitorLevel.junior).length;
  bool get isValid => members.length == 5 && juniorCount >= 2;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'members': members.map((m) => m.toJson()).toList(),
  };

  factory Team.fromJson(Map<String, dynamic> json) => Team(
    id: json['id'],
    name: json['name'],
    members: (json['members'] as List).map((m) => Competitor.fromJson(m)).toList(),
  );

  Team copyWith({String? name, List<Competitor>? members}) {
    return Team(
      id: id,
      name: name ?? this.name,
      members: members ?? this.members,
    );
  }
}

class FiringPoint {
  final int laneNumber;
  final String? competitorName;
  final String? teamName;
  final TargetType targetType;
  final int? score;
  final int? innerTens;
  final double? groupingMm;

  FiringPoint({
    required this.laneNumber,
    this.competitorName,
    this.teamName,
    this.targetType = TargetType.competition,
    this.score,
    this.innerTens,
    this.groupingMm,
  });

  Map<String, dynamic> toJson() => {
    'laneNumber': laneNumber,
    'competitorName': competitorName,
    'teamName': teamName,
    'targetType': targetType.index,
    'score': score,
    'innerTens': innerTens,
    'groupingMm': groupingMm,
  };

  factory FiringPoint.fromJson(Map<String, dynamic> json) => FiringPoint(
    laneNumber: json['laneNumber'],
    competitorName: json['competitorName'],
    teamName: json['teamName'],
    targetType: TargetType.values[json['targetType'] ?? 1],
    score: json['score'],
    innerTens: json['innerTens'],
    groupingMm: json['groupingMm'],
  );

  FiringPoint copyWith({
    String? competitorName,
    String? teamName,
    TargetType? targetType,
    int? score,
    int? innerTens,
    double? groupingMm,
  }) {
    return FiringPoint(
      laneNumber: laneNumber,
      competitorName: competitorName ?? this.competitorName,
      teamName: teamName ?? this.teamName,
      targetType: targetType ?? this.targetType,
      score: score ?? this.score,
      innerTens: innerTens ?? this.innerTens,
      groupingMm: groupingMm ?? this.groupingMm,
    );
  }
}

class Relay {
  final String id;
  final int number;
  final List<FiringPoint> firingPoints;
  final bool isActive;
  final String? teamId;

  Relay({
    required this.id,
    required this.number,
    required this.firingPoints,
    this.isActive = false,
    this.teamId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'firingPoints': firingPoints.map((p) => p.toJson()).toList(),
    'isActive': isActive,
    'teamId': teamId,
  };

  factory Relay.fromJson(Map<String, dynamic> json) => Relay(
    id: json['id'],
    number: json['number'],
    firingPoints: (json['firingPoints'] as List).map((p) => FiringPoint.fromJson(p)).toList(),
    isActive: json['isActive'] ?? false,
    teamId: json['teamId'],
  );

  Relay copyWith({int? number, List<FiringPoint>? firingPoints, bool? isActive, String? teamId}) {
    return Relay(
      id: id,
      number: number ?? this.number,
      firingPoints: firingPoints ?? this.firingPoints,
      isActive: isActive ?? this.isActive,
      teamId: teamId ?? this.teamId,
    );
  }
}

class PracticeScore {
  final String id;
  final String cadetId;
  final String cadetName;
  final TargetType targetType;
  final int? score;
  final int? innerTens;
  final double? groupingMm;
  final DateTime timestamp;

  PracticeScore({
    required this.id,
    required this.cadetId,
    required this.cadetName,
    required this.targetType,
    this.score,
    this.innerTens,
    this.groupingMm,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'cadetId': cadetId,
    'cadetName': cadetName,
    'targetType': targetType.index,
    'score': score,
    'innerTens': innerTens,
    'groupingMm': groupingMm,
    'timestamp': timestamp.toIso8601String(),
  };

  factory PracticeScore.fromJson(Map<String, dynamic> json) => PracticeScore(
    id: json['id'],
    cadetId: json['cadetId'],
    cadetName: json['cadetName'],
    targetType: TargetType.values[json['targetType'] ?? 1],
    score: json['score'],
    innerTens: json['innerTens'],
    groupingMm: json['groupingMm'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

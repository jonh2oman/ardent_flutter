class WarningOrder {
  final String id;
  final String fileNumber;
  final String subject;
  final String date;
  final List<String> references;
  final String situation;
  final String mission;
  
  // Execution
  final String adminOrders;
  final String adminJIs;
  final String participantEligibility;
  final String registrationOfParticipants;
  final String supportCadetOpportunities;
  final String adultStaffingOpportunities;
  final String requestForAccommodation;
  final String contingencyPlans;
  final String lessonsLearned;
  final String gbaPlus;

  // Service Support
  final String pay;
  final String travel;
  final String rations;
  final String lodgings;
  final String transportation;
  final String equipment;
  final String publicAffairs;
  final String financialAuthorization;

  // Command & Signals
  final List<Map<String, String>> contacts;

  // Distribution & Serials
  final List<String> distributionAction;
  final List<String> distributionInfo;
  final List<Map<String, String>> serials;

  WarningOrder({
    required this.id,
    this.fileNumber = '1085-3-5 (Area Trg O)',
    required this.subject,
    required this.date,
    required this.references,
    required this.situation,
    required this.mission,
    this.adminOrders = '',
    this.adminJIs = '',
    this.participantEligibility = '',
    this.registrationOfParticipants = '',
    this.supportCadetOpportunities = '',
    this.adultStaffingOpportunities = '',
    this.requestForAccommodation = '',
    this.contingencyPlans = '',
    this.lessonsLearned = '',
    this.gbaPlus = '',
    this.pay = '',
    this.travel = '',
    this.rations = '',
    this.lodgings = '',
    this.transportation = '',
    this.equipment = '',
    this.publicAffairs = '',
    this.financialAuthorization = '',
    required this.contacts,
    required this.distributionAction,
    required this.distributionInfo,
    required this.serials,
  });

  factory WarningOrder.fromMap(Map<String, dynamic> map, String id) {
    return WarningOrder(
      id: id,
      fileNumber: map['fileNumber'] ?? '1085-3-5 (Area Trg O)',
      subject: map['subject'] ?? '',
      date: map['date'] ?? '',
      references: List<String>.from(map['references'] ?? []),
      situation: map['situation'] ?? '',
      mission: map['mission'] ?? '',
      adminOrders: map['adminOrders'] ?? '',
      adminJIs: map['adminJIs'] ?? '',
      participantEligibility: map['participantEligibility'] ?? '',
      registrationOfParticipants: map['registrationOfParticipants'] ?? '',
      supportCadetOpportunities: map['supportCadetOpportunities'] ?? '',
      adultStaffingOpportunities: map['adultStaffingOpportunities'] ?? '',
      requestForAccommodation: map['requestForAccommodation'] ?? '',
      contingencyPlans: map['contingencyPlans'] ?? '',
      lessonsLearned: map['lessonsLearned'] ?? '',
      gbaPlus: map['gbaPlus'] ?? '',
      pay: map['pay'] ?? '',
      travel: map['travel'] ?? '',
      rations: map['rations'] ?? '',
      lodgings: map['lodgings'] ?? '',
      transportation: map['transportation'] ?? '',
      equipment: map['equipment'] ?? '',
      publicAffairs: map['publicAffairs'] ?? '',
      financialAuthorization: map['financialAuthorization'] ?? '',
      contacts: (map['contacts'] as List? ?? [])
          .map((c) => Map<String, String>.from(c as Map))
          .toList(),
      distributionAction: List<String>.from(map['distributionAction'] ?? []),
      distributionInfo: List<String>.from(map['distributionInfo'] ?? []),
      serials: (map['serials'] as List? ?? [])
          .map((s) => Map<String, String>.from(s as Map))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fileNumber': fileNumber,
      'subject': subject,
      'date': date,
      'references': references,
      'situation': situation,
      'mission': mission,
      'adminOrders': adminOrders,
      'adminJIs': adminJIs,
      'participantEligibility': participantEligibility,
      'registrationOfParticipants': registrationOfParticipants,
      'supportCadetOpportunities': supportCadetOpportunities,
      'adultStaffingOpportunities': adultStaffingOpportunities,
      'requestForAccommodation': requestForAccommodation,
      'contingencyPlans': contingencyPlans,
      'lessonsLearned': lessonsLearned,
      'gbaPlus': gbaPlus,
      'pay': pay,
      'travel': travel,
      'rations': rations,
      'lodgings': lodgings,
      'transportation': transportation,
      'equipment': equipment,
      'publicAffairs': publicAffairs,
      'financialAuthorization': financialAuthorization,
      'contacts': contacts,
      'distributionAction': distributionAction,
      'distributionInfo': distributionInfo,
      'serials': serials,
    };
  }
}

class OperationOrder {
  final String id;
  final String? parentWarningOrderId;
  final String fileNumber;
  final String subject;
  final String date;
  final List<String> references;
  final String situation;
  final String mission;

  // Execution - Concept of Operations
  final String conceptCommandIntent;
  final String conceptSchemeOfManeuver;
  final String conceptGeneralOutline;
  final String conceptEndState;

  // Execution - Coordination
  final String contingencyPlan;
  final String groupings;
  final String taskings;
  final String adminOrders;
  final String participantEligibility;
  final String registrationOfParticipants;
  final String supportCadetEligibility;
  final String adultStaffingOpportunities;
  final String lessonsLearned;
  final String dress;
  final String medicalEmergency;
  final String conductDiscipline;
  final String gbaPlus;

  // Service Support
  final String pay;
  final String lodgings;
  final String transportation;
  final String rations;
  final String requestForAccommodation;
  final String equipment;
  final String informationTechnology;
  final String travelClaims;
  final String publicAffairs;

  // Command & Signals
  final List<Map<String, String>> contacts;
  final String emergencyCommunications;

  // Annexes & Distribution
  final List<String> annexes;
  final List<String> distributionAction;
  final List<String> distributionInfo;
  final List<Map<String, String>> serials;

  OperationOrder({
    required this.id,
    this.parentWarningOrderId,
    this.fileNumber = '1085-3-5 (ADA OIC)',
    required this.subject,
    required this.date,
    required this.references,
    required this.situation,
    required this.mission,
    this.conceptCommandIntent = '',
    this.conceptSchemeOfManeuver = '',
    this.conceptGeneralOutline = '',
    this.conceptEndState = '',
    this.contingencyPlan = '',
    this.groupings = '',
    this.taskings = '',
    this.adminOrders = '',
    this.participantEligibility = '',
    this.registrationOfParticipants = '',
    this.supportCadetEligibility = '',
    this.adultStaffingOpportunities = '',
    this.lessonsLearned = '',
    this.dress = '',
    this.medicalEmergency = '',
    this.conductDiscipline = '',
    this.gbaPlus = '',
    this.pay = '',
    this.lodgings = '',
    this.transportation = '',
    this.rations = '',
    this.requestForAccommodation = '',
    this.equipment = '',
    this.informationTechnology = '',
    this.travelClaims = '',
    this.publicAffairs = '',
    required this.contacts,
    this.emergencyCommunications = '',
    required this.annexes,
    required this.distributionAction,
    required this.distributionInfo,
    required this.serials,
  });

  factory OperationOrder.fromWarningOrder(WarningOrder wng) {
    // Generate Operation Order from Warning Order data
    final opordSubject = wng.subject.startsWith('WARNING ORDER')
        ? wng.subject.replaceFirst('WARNING ORDER', 'OPERATION ORDER')
        : 'OPERATION ORDER – ${wng.subject}';
        
    return OperationOrder(
      id: '',
      parentWarningOrderId: wng.id,
      fileNumber: '1085-3-5 (ADA OIC)',
      subject: opordSubject,
      date: wng.date,
      references: [
        ...wng.references,
        'G. Warning Order – ${wng.subject}',
      ],
      situation: wng.situation,
      mission: wng.mission,
      contingencyPlan: wng.contingencyPlans,
      adminOrders: wng.adminOrders,
      participantEligibility: wng.participantEligibility,
      registrationOfParticipants: wng.registrationOfParticipants,
      supportCadetEligibility: wng.supportCadetOpportunities,
      adultStaffingOpportunities: wng.adultStaffingOpportunities,
      lessonsLearned: wng.lessonsLearned,
      gbaPlus: wng.gbaPlus,
      pay: wng.pay,
      lodgings: wng.lodgings,
      transportation: wng.transportation,
      rations: wng.rations,
      requestForAccommodation: wng.requestForAccommodation,
      equipment: wng.equipment,
      publicAffairs: wng.publicAffairs,
      contacts: List<Map<String, String>>.from(wng.contacts),
      distributionAction: List<String>.from(wng.distributionAction),
      distributionInfo: List<String>.from(wng.distributionInfo),
      serials: List<Map<String, String>>.from(wng.serials),
      annexes: [
        'Annex A Activity Schedule',
        'Annex B Contingency Plan',
        'Annex C Serials and Corps / Squadron Assignments',
        'Annex D Staffing and Supervision Plan',
        'Annex E Organizational Chart',
        'Annex F Tasking Assignments',
        'Annex G Medication Management and Illness Prevention and Response Plan',
        'Annex H Lodgings Plan',
        'Annex I Transportation Plan',
        'Annex J Rations Plan',
        'Annex K Equipment and Facilities Support Plan',
        'Annex L Information Technology Plan',
        'Annex M Public Affairs Communications Plan',
        'Annex N Emergency Response Plan',
        'Annex O Risk Mitigation Matrix'
      ],
    );
  }

  factory OperationOrder.fromMap(Map<String, dynamic> map, String id) {
    return OperationOrder(
      id: id,
      parentWarningOrderId: map['parentWarningOrderId'],
      fileNumber: map['fileNumber'] ?? '1085-3-5 (ADA OIC)',
      subject: map['subject'] ?? '',
      date: map['date'] ?? '',
      references: List<String>.from(map['references'] ?? []),
      situation: map['situation'] ?? '',
      mission: map['mission'] ?? '',
      conceptCommandIntent: map['conceptCommandIntent'] ?? '',
      conceptSchemeOfManeuver: map['conceptSchemeOfManeuver'] ?? '',
      conceptGeneralOutline: map['conceptGeneralOutline'] ?? '',
      conceptEndState: map['conceptEndState'] ?? '',
      contingencyPlan: map['contingencyPlan'] ?? '',
      groupings: map['groupings'] ?? '',
      taskings: map['taskings'] ?? '',
      adminOrders: map['adminOrders'] ?? '',
      participantEligibility: map['participantEligibility'] ?? '',
      registrationOfParticipants: map['registrationOfParticipants'] ?? '',
      supportCadetEligibility: map['supportCadetEligibility'] ?? '',
      adultStaffingOpportunities: map['adultStaffingOpportunities'] ?? '',
      lessonsLearned: map['lessonsLearned'] ?? '',
      dress: map['dress'] ?? '',
      medicalEmergency: map['medicalEmergency'] ?? '',
      conductDiscipline: map['conductDiscipline'] ?? '',
      gbaPlus: map['gbaPlus'] ?? '',
      pay: map['pay'] ?? '',
      lodgings: map['lodgings'] ?? '',
      transportation: map['transportation'] ?? '',
      rations: map['rations'] ?? '',
      requestForAccommodation: map['requestForAccommodation'] ?? '',
      equipment: map['equipment'] ?? '',
      informationTechnology: map['informationTechnology'] ?? '',
      travelClaims: map['travelClaims'] ?? '',
      publicAffairs: map['publicAffairs'] ?? '',
      contacts: (map['contacts'] as List? ?? [])
          .map((c) => Map<String, String>.from(c as Map))
          .toList(),
      emergencyCommunications: map['emergencyCommunications'] ?? '',
      annexes: List<String>.from(map['annexes'] ?? []),
      distributionAction: List<String>.from(map['distributionAction'] ?? []),
      distributionInfo: List<String>.from(map['distributionInfo'] ?? []),
      serials: (map['serials'] as List? ?? [])
          .map((s) => Map<String, String>.from(s as Map))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'parentWarningOrderId': parentWarningOrderId,
      'fileNumber': fileNumber,
      'subject': subject,
      'date': date,
      'references': references,
      'situation': situation,
      'mission': mission,
      'conceptCommandIntent': conceptCommandIntent,
      'conceptSchemeOfManeuver': conceptSchemeOfManeuver,
      'conceptGeneralOutline': conceptGeneralOutline,
      'conceptEndState': conceptEndState,
      'contingencyPlan': contingencyPlan,
      'groupings': groupings,
      'taskings': taskings,
      'adminOrders': adminOrders,
      'participantEligibility': participantEligibility,
      'registrationOfParticipants': registrationOfParticipants,
      'supportCadetEligibility': supportCadetEligibility,
      'adultStaffingOpportunities': adultStaffingOpportunities,
      'lessonsLearned': lessonsLearned,
      'dress': dress,
      'medicalEmergency': medicalEmergency,
      'conductDiscipline': conductDiscipline,
      'gbaPlus': gbaPlus,
      'pay': pay,
      'lodgings': lodgings,
      'transportation': transportation,
      'rations': rations,
      'requestForAccommodation': requestForAccommodation,
      'equipment': equipment,
      'informationTechnology': informationTechnology,
      'travelClaims': travelClaims,
      'publicAffairs': publicAffairs,
      'contacts': contacts,
      'emergencyCommunications': emergencyCommunications,
      'annexes': annexes,
      'distributionAction': distributionAction,
      'distributionInfo': distributionInfo,
      'serials': serials,
    };
  }
}

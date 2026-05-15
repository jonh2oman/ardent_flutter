class Curriculum {
  static const Map<String, Map<String, Map<String, List<List<dynamic>>>>> data = {
    "Phase 1": {
      "PO 107 - Serve in a Sea Cadet Corps": {
        "M": [["M107.01", "Discuss Year One Training", 1], ["M107.02", "Identify Sea Cadet and Naval Officer Ranks", 1], ["M107.03", "Observe Rules and Procedures for the Paying of Compliments", 1], ["M107.04", "State the Army and Motto of the Sea Cadet Program", 1], ["M107.05", "Wear the Sea Cadet Uniform", 1]],
        "C": [["M107.06", "Discuss Summer Training Opportunities", 1], ["C107.01", "Maintain the Sea Cadet Uniform", 2], ["C107.02", "Participate in a Tour of the Corps", 1], ["C107.03", "Participate in an Activity about the History of the Corps", 1]]
      },
      "PO 108 - Perform Drill Movements": {
        "M": [["M108.01", "Adopt the Positions of Attention, Stand at Ease, and Stand Easy", 1], ["M108.02", "Execute a Salute at the Halt Without Arms", 1], ["M108.03", "Execute Turns at the Halt", 1], ["M108.04", "Close to the Right and Left", 1], ["M108.05", "Execute Paces Forward and to the Rear", 1], ["M108.06", "Execute the Movements Required for a Right Dress", 1], ["M108.07", "Execute an Open Order and Close Order March", 1], ["M108.08", "March and Halt in Quick Time", 1], ["M108.09", "Execute Marking Time, Forward, and Halting in Quick Time", 1], ["M108.11", "Pay Compliments with a Squad on the March", 1], ["M108.12", "Perform Drill Movements During an Annual Ceremonial Review", 3]],
        "C": [["M108.10", "Execute a Salute on the March", 1], ["C108.01", "Execute Supplementary Drill Movements", 6], ["C108.02", "Participate in a Drill Competition", 3]]
      },
      "PO 121 - Perform Basic Ropework": {
        "M": [["M121.01", "Tie Knots, Bends and Hitches", 6], ["M121.02", "Whip the End of a Line Using a Common Whipping", 3], ["M121.03", "Coil and Heave a Line", 3]],
        "C": [["C121.01", "Whip the End of a Line Using a West Country Whipping", 1], ["C121.02", "Whip the End of a Line Using a Sailmaker's Whipping", 2], ["C121.03", "Complete a Rolling Hitch", 1], ["C121.04", "Complete a Marlin Hitch", 1]]
      },
      "PO 123 - Respond to Basic Forms of Naval Communications": {
        "M": [["M123.01", "Define Basic Naval Terminology", 2], ["M123.02", "Identify Pipes and the Correct Responses", 2], ["M123.03", "Participate in a Review of Ship's Operations", 1]],
        "C": [["C123.01", "Read the 24-hour Clock", 1], ["C123.02", "Recite the Phonetic Alphabet", 2], ["C123.03", "Participate in a Semaphore Exercise", 5], ["C123.04", "Ring the Ship's Bell", 1]]
      },
      "PO X20 - CAF Familiarization": {
        "M": [["MX20.01", "Participate in a CAF Engagement Activity", 9]],
        "C": [["CX20.01", "Participate in CAF Familiarization Activities", 18]]
      }
    },
    "Phase 2": {
      "PO 203 - Demonstrate Leadership Attributes within a Peer Setting": {
        "M": [["M203.01", "Discuss Leadership Within a Peer Setting", 1], ["M203.02", "Discuss the Principles of Leadership", 1], ["M203.03", "Discuss Effective Communication in a Peer Setting", 1], ["M203.04", "Demonstrate Positive Group Dynamics", 2], ["M203.05", "Discuss Influence Behaviours", 1], ["M203.06", "Employ Problem Solving", 2], ["M203.07", "Discuss Personal Integrity as a Quality of Leadership", 1], ["M203.08", "Participate in Team-Building Activities", 1]],
        "C": [["C203.01", "Record Entries in a Reflective Journal", 3], ["C203.02", "Employ Problem Solving", 2]]
      },
      "PO 208 - Execute Drill as a Member of a Squad": {
        "M": [["M208.01", "Execute Left and Right Turns on the March", 2], ["M208.02", "Form Single File From the Halt", 1]],
        "C": [["C208.01", "Practice Ceremonial Drill as a Review", 2], ["C208.02", "Execute Drill with Arms", 8]]
      },
      "PO 221 - Rig Tackle": {
        "M": [["M221.01", "Use a Shackle", 1], ["M221.02", "Use a Moussing", 1], ["M221.03", "Use a Reel", 1], ["M221.04", "Identify Components of a Tackle", 1], ["M221.05", "Rig a Tackle", 2]],
        "C": [["C221.01", "Make a Back Splice", 2], ["C221.02", "Make an Eye Splice", 2], ["C221.03", "Make a Short Splice", 2]]
      }
    },
    "Phase 3": {
      "PO 303 - Perform the Role of a Team Leader": {
        "M": [["M303.01", "Define the Role of a Team Leader", 1], ["M303.02", "Deliver a Short Talk", 2]],
        "C": [["C303.01", "Lead a Team-Building Activity", 3]]
      },
      "PO 309 - Instruct a Lesson": {
        "M": [["M309.01", "Explain the Principles of Instruction", 1], ["M309.02", "Identify Methods of Instruction", 1], ["M309.03", "Plan a Lesson", 2], ["M309.04", "Instruct a 15-Minute Lesson", 3]],
        "C": [["C309.01", "Deliver a One-Minute Lesson", 1]]
      }
    },
    "Phase 4": {
      "PO 403 - Act as a Team Leader": {
        "M": [["M403.01", "Describe Needs and Expectations of Team Members", 1], ["M403.02", "Select a Leadership Approach", 2]],
        "C": [["C403.01", "Participate in a Leadership Seminar", 12]]
      }
    }
  };

  static Map<String, dynamic>? findEO(String phase, String eoId) {
    // Try current phase first
    final result = _searchInPhase(phase, eoId);
    if (result != null) return result;

    // Search all phases if not found in current (for cross-training)
    for (var p in data.keys) {
      if (p == phase) continue;
      final crossResult = _searchInPhase(p, eoId);
      if (crossResult != null) return crossResult;
    }
    return null;
  }

  static Map<String, dynamic>? _searchInPhase(String phase, String eoId) {
    final phaseData = data[phase];
    if (phaseData == null) return null;

    for (var po in phaseData.values) {
      for (var type in ['M', 'C']) {
        final list = po[type];
        if (list == null) continue;
        for (var item in list) {
          if (item[0].toString().toLowerCase() == eoId.toLowerCase()) {
            return {
              'id': item[0],
              'title': item[1],
              'periods': item[2],
              'type': type,
            };
          }
        }
      }
    }
    return null;
  }

  static List<Map<String, dynamic>> getPhaseEOs(String phase) {
    final List<Map<String, dynamic>> results = [];
    
    // Add current phase EOs
    final phaseData = data[phase];
    if (phaseData != null) {
      for (var po in phaseData.values) {
        for (var type in ['M', 'C']) {
          final list = po[type];
          if (list == null) continue;
          for (var item in list) {
            results.add({
              'id': item[0],
              'title': item[1],
              'periods': item[2],
              'type': type,
              'source': phase,
            });
          }
        }
      }
    }

    // Also add mandatory EOs from other phases for searching convenience
    for (var p in data.keys) {
      if (p == phase) continue;
      final otherPhaseData = data[p];
      if (otherPhaseData == null) continue;
      for (var po in otherPhaseData.values) {
        final mandatory = po['M'];
        if (mandatory == null) continue;
        for (var item in mandatory) {
          results.add({
            'id': item[0],
            'title': item[1],
            'periods': item[2],
            'type': 'M',
            'source': p,
          });
        }
      }
    }
    
    return results;
  }
}

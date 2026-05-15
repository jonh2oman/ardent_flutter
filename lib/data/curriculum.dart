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
        "C": [["C121.01", "Whip the End of a Line Using a West Country Whipping", 1], ["C121.02", "Whip the End of a Line Using a Sailmaker's Whipping", 2]]
      }
    },
    "Phase 2": {
      "PO 203 - Demonstrate Leadership Attributes within a Peer Setting": {
        "M": [["M203.01", "Discuss Leadership Within a Peer Setting", 1], ["M203.02", "Discuss the Principles of Leadership", 1], ["M203.03", "Discuss Effective Communication in a Peer Setting", 1], ["M203.04", "Demonstrate Positive Group Dynamics", 2]],
        "C": [["C203.01", "Record Entries in a Reflective Journal", 3]]
      }
    }
    // ... we can expand this with more POs as needed
  };

  static Map<String, dynamic>? findEO(String phase, String eoId) {
    final phaseData = data[phase];
    if (phaseData == null) return null;

    for (var po in phaseData.values) {
      for (var type in ['M', 'C']) {
        final list = po[type];
        if (list == null) continue;
        for (var item in list) {
          if (item[0] == eoId) {
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
    final phaseData = data[phase];
    if (phaseData == null) return results;

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
          });
        }
      }
    }
    return results;
  }
}

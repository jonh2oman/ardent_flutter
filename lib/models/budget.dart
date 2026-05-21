import 'package:uuid/uuid.dart';

class PeriodValue {
  double proposed;
  double actual;

  PeriodValue({this.proposed = 0.0, this.actual = 0.0});

  factory PeriodValue.fromMap(Map<String, dynamic> map) {
    return PeriodValue(
      proposed: (map['proposed'] ?? 0.0).toDouble(),
      actual: (map['actual'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'proposed': proposed,
      'actual': actual,
    };
  }
}

class Reimbursement {
  bool isEligible;
  String rationale;

  Reimbursement({this.isEligible = false, this.rationale = ''});

  factory Reimbursement.fromMap(Map<String, dynamic> map) {
    return Reimbursement(
      isEligible: map['isEligible'] ?? false,
      rationale: map['rationale'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isEligible': isEligible,
      'rationale': rationale,
    };
  }
}

class BudgetItem {
  final String id;
  String? category;
  String description;
  String? details;
  Map<String, PeriodValue> periodValues;
  double budget; // total proposed
  double actual; // total actual
  Reimbursement reimbursement;
  String explanation;

  BudgetItem({
    required this.id,
    this.category,
    required this.description,
    this.details,
    required this.periodValues,
    required this.budget,
    required this.actual,
    required this.reimbursement,
    this.explanation = '',
  });

  factory BudgetItem.createEmpty(String description, {String? details, String? category}) {
    const uuid = Uuid();
    final periods = {
      "Jan-Mar": PeriodValue(),
      "Apr-May": PeriodValue(),
      "Jun-Aug": PeriodValue(),
      "Sep-Dec": PeriodValue(),
    };
    return BudgetItem(
      id: uuid.v4(),
      description: description,
      details: details,
      category: category,
      periodValues: periods,
      budget: 0.0,
      actual: 0.0,
      reimbursement: Reimbursement(),
      explanation: '',
    );
  }

  factory BudgetItem.fromMap(Map<String, dynamic> map, String id) {
    final rawPeriods = map['periodValues'] as Map<String, dynamic>? ?? {};
    final periods = <String, PeriodValue>{};
    for (final period in ["Jan-Mar", "Apr-May", "Jun-Aug", "Sep-Dec"]) {
      final pMap = rawPeriods[period] != null 
          ? Map<String, dynamic>.from(rawPeriods[period])
          : null;
      periods[period] = pMap != null ? PeriodValue.fromMap(pMap) : PeriodValue();
    }

    final budgetVal = (map['budget'] ?? 0.0).toDouble();
    final actualVal = (map['actual'] ?? 0.0).toDouble();
    
    final reimbMap = map['reimbursement'] != null 
        ? Map<String, dynamic>.from(map['reimbursement'])
        : null;

    return BudgetItem(
      id: id,
      category: map['category'],
      description: map['description'] ?? '',
      details: map['details'],
      periodValues: periods,
      budget: budgetVal,
      actual: actualVal,
      reimbursement: reimbMap != null ? Reimbursement.fromMap(reimbMap) : Reimbursement(),
      explanation: map['explanation'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    final periodsMap = <String, Map<String, dynamic>>{};
    periodValues.forEach((key, val) {
      periodsMap[key] = val.toMap();
    });

    return {
      'id': id,
      'category': category,
      'description': description,
      'details': details,
      'periodValues': periodsMap,
      'budget': budget,
      'actual': actual,
      'reimbursement': reimbursement.toMap(),
      'explanation': explanation,
    };
  }

  void recalculateTotals() {
    budget = periodValues.values.fold(0.0, (sum, p) => sum + p.proposed);
    actual = periodValues.values.fold(0.0, (sum, p) => sum + p.actual);
  }
}

class ExpenseCategory {
  final String id;
  String name;
  List<BudgetItem> items;

  ExpenseCategory({
    required this.id,
    required this.name,
    required this.items,
  });

  factory ExpenseCategory.fromMap(Map<String, dynamic> map, String id) {
    final rawItems = map['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems.map((itemMap) {
      final m = Map<String, dynamic>.from(itemMap);
      return BudgetItem.fromMap(m, m['id'] ?? const Uuid().v4());
    }).toList();

    return ExpenseCategory(
      id: id,
      name: map['name'] ?? '',
      items: itemsList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'items': items.map((i) => i.toMap()).toList(),
    };
  }
}

class Budget {
  List<BudgetItem> revenueItems;
  List<ExpenseCategory> expenseCategories;

  Budget({
    required this.revenueItems,
    required this.expenseCategories,
  });

  factory Budget.fromMap(Map<String, dynamic> map) {
    final rawRev = map['revenueItems'] as List<dynamic>? ?? [];
    final revList = rawRev.map((itemMap) {
      final m = Map<String, dynamic>.from(itemMap);
      return BudgetItem.fromMap(m, m['id'] ?? const Uuid().v4());
    }).toList();

    final rawExp = map['expenseCategories'] as List<dynamic>? ?? [];
    final expList = rawExp.map((catMap) {
      final m = Map<String, dynamic>.from(catMap);
      return ExpenseCategory.fromMap(m, m['id'] ?? const Uuid().v4());
    }).toList();

    return Budget(
      revenueItems: revList,
      expenseCategories: expList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'revenueItems': revenueItems.map((i) => i.toMap()).toList(),
      'expenseCategories': expenseCategories.map((c) => c.toMap()).toList(),
    };
  }
}

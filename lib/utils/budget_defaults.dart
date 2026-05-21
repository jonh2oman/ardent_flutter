import 'package:uuid/uuid.dart';
import '../models/budget.dart';

class BudgetDefaults {
  static const List<String> reportingPeriods = ["Jan-Mar", "Apr-May", "Jun-Aug", "Sep-Dec"];

  static final List<Map<String, dynamic>> defaultRevenueCategories = [
    {
      "name": "Donations, Grants & Other",
      "items": [
        {"description": "From Official Sponsor"},
        {"description": "From Non-Sponsor Veteran Organization & their Auxiliaries"},
        {"description": "From Other Service Clubs (Charities)"},
        {"description": "Available (Rename)"},
        {"description": "Specific Purpose Non DND Grants", "details": "Special Grant for a project"},
      ]
    },
    {
      "name": "Gaming & Lottery Fundraising",
      "items": [
        {"description": "Available (Rename)"},
        {"description": "Available (Rename)"},
      ]
    },
    {
      "name": "Other Fundraising",
      "items": [
        {"description": "Available (Rename)"},
        {"description": "Available (Rename)"},
      ]
    },
    {
      "name": "Misc. Revenues (Other than Gov't)",
      "items": [
        {"description": "Money Collected for Activities"},
        {"description": "Canteen Proceeds"},
        {"description": "Available (Rename)"},
      ]
    },
    {
      "name": "Funding & Recoveries (Gov't)",
      "items": [
        {"description": "DND Local Support Allocation [LSA]"},
        {"description": "DND Allocation - Mandatory & Complimentary Program [MCP]"},
      ]
    }
  ];

  static final List<Map<String, dynamic>> defaultExpenseCategories = [
    {
      "name": "Administrative & Operating",
      "items": [
        {"description": "Admin. & Office Supplies", "details": "Photocopies, Paper, Toner, Stationary"},
        {"description": "Office Equipment", "details": "Laptops, Printer, Software, Filing Cabinets, Desk, Chairs"},
        {"description": "Corps/Squadron Quarters Rental/Mortgage Costs", "details": "Annual Costs"},
        {"description": "Corps/Sqn. Expenditure - Maintenance, Repairs, Expansion etc.", "details": "Maintenance, Repairs, Expansion"},
        {"description": "Utilities, Telephone, Internet, P.O. Box Rental", "details": "P.O. Box, Internet, Website, Cell"},
        {"description": "Committee Staff AGM & Meeting Attendance", "details": "Chair, Treasurer, CO Cdt Comdr (or representative)"},
        {"description": "Recruiting & Advertising", "details": "Public Relations, Image, Parent Handbook, Advertising, News Paper Ads, Open door, Awards, etc."},
        {"description": "Cadet Assessment", "details": "Based on quota on March 31st of previous TY"},
        {"description": "Group Dues", "details": "Regional Assessment"},
        {"description": "Financial & Bank Charges", "details": "Monthly Banks Fees, Cheque Printing Fees, Investment Charges, Returned Cheque Fees"},
        {"description": "Professional Fees", "details": "Stamps, Reg'd letters, Other Couriers"},
        {"description": "Corps/Sqn Level Insurance", "details": "Insurance for SSC Material (Through the League)"},
        {"description": "Volunteer Rig & Screening Costs"},
      ]
    },
    {
      "name": "Corps/Squadron Activity Expenses",
      "items": [
        {"description": "Training Aids, not provided by CAF"},
        {"description": "Band Equipment, Accessories, Maint. & Programs"},
        {"description": "Sports & Phys. Ed. Related Programs"},
        {"description": "Transportation, not provided by CAF"},
        {"description": "Other Non-DND Supported Trg/Activities Outlays"},
        {"description": "Honors & Awards"},
        {"description": "Annual Ceremonial Review"},
        {"description": "Cadet Banquets & Special Events"},
        {"description": "Cadet & Ceremonial Accoutrements"},
        {"description": "Sundries"},
      ]
    },
    {
      "name": "Expenses - Gaming and Lottery",
      "items": [
        {"description": "Available (Rename)"},
        {"description": "Available (Rename)"},
      ]
    },
    {
      "name": "Other Expenses",
      "items": [
        {"description": "Corps/Sqn Logo & other sale items (purchasing)"},
        {"description": "Available (Rename)"},
        {"description": "Available (Rename)"},
        {"description": "Other Expenses (Must Not Be Excessive)"},
      ]
    }
  ];

  static Budget getSeedBudget() {
    final revenue = <BudgetItem>[];
    for (final cat in defaultRevenueCategories) {
      final items = cat['items'] as List<dynamic>;
      for (final item in items) {
        final itemMap = Map<String, dynamic>.from(item);
        revenue.add(BudgetItem.createEmpty(
          itemMap['description'] as String,
          details: itemMap['details'] as String?,
          category: cat['name'] as String?,
        ));
      }
    }

    final expenses = <ExpenseCategory>[];
    for (final cat in defaultExpenseCategories) {
      final catId = const Uuid().v4();
      final items = cat['items'] as List<dynamic>;
      final catItems = <BudgetItem>[];
      for (final item in items) {
        final itemMap = Map<String, dynamic>.from(item);
        catItems.add(BudgetItem.createEmpty(
          itemMap['description'] as String,
          details: itemMap['details'] as String?,
        ));
      }
      expenses.add(ExpenseCategory(
        id: catId,
        name: cat['name'] as String,
        items: catItems,
      ));
    }

    return Budget(
      revenueItems: revenue,
      expenseCategories: expenses,
    );
  }
}

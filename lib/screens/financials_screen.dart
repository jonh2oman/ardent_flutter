import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../providers/auth_provider.dart';
import '../models/budget.dart';
import '../models/bank_ledger.dart';
import '../utils/budget_defaults.dart';

class FinancialsScreen extends StatefulWidget {
  const FinancialsScreen({super.key});

  @override
  State<FinancialsScreen> createState() => _FinancialsScreenState();
}

class _FinancialsScreenState extends State<FinancialsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  bool _saving = false;
  Budget? _budget;

  BankLedger? _bankLedger;
  bool _ledgerLoading = true;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBudget();
    _loadBankLedger();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBudget() async {
    setState(() => _loading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final doc = await FirebaseFirestore.instance
          .collection('corps')
          .doc(auth.corpsData!.id)
          .collection('financials')
          .doc('budget')
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          _budget = Budget.fromMap(doc.data()!);
          _loading = false;
        });
      } else {
        setState(() {
          _budget = null;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading budget: $e");
      setState(() => _loading = false);
    }
  }

  Future<void> _loadBankLedger() async {
    setState(() => _ledgerLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final doc = await FirebaseFirestore.instance
          .collection('corps')
          .doc(auth.corpsData!.id)
          .collection('financials')
          .doc('bank_ledger')
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          _bankLedger = BankLedger.fromMap(doc.data()!);
          _ledgerLoading = false;
        });
      } else {
        setState(() {
          _bankLedger = BankLedger(history: []);
          _ledgerLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading bank ledger: $e");
      setState(() => _ledgerLoading = false);
    }
  }

  Future<void> _saveBankLedger() async {
    if (_bankLedger == null) return;
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await FirebaseFirestore.instance
          .collection('corps')
          .doc(auth.corpsData!.id)
          .collection('financials')
          .doc('bank_ledger')
          .set(_bankLedger!.toMap());
    } catch (e) {
      debugPrint("Error saving bank ledger: $e");
    }
  }

  Future<void> _confirmResetBudget(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161920),
        title: const Text('Reset Budget to Defaults?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will overwrite all current budget planning and tracking values with default seed categories. This action cannot be undone.',
          style: TextStyle(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('RESET'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _seedBudget();
    }
  }


  Future<void> _seedBudget() async {
    setState(() => _saving = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final defaultBudget = BudgetDefaults.getSeedBudget();

      // Recalculate totals just in case
      for (final item in defaultBudget.revenueItems) {
        item.recalculateTotals();
      }
      for (final cat in defaultBudget.expenseCategories) {
        for (final item in cat.items) {
          item.recalculateTotals();
        }
      }

      await FirebaseFirestore.instance
          .collection('corps')
          .doc(auth.corpsData!.id)
          .collection('financials')
          .doc('budget')
          .set(defaultBudget.toMap());

      setState(() {
        _budget = defaultBudget;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget template seeded successfully!')),
      );
    } catch (e) {
      debugPrint("Error seeding budget: $e");
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error seeding budget: $e')),
      );
    }
  }

  Future<void> _saveBudget() async {
    if (_budget == null) return;
    setState(() => _saving = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      // Recalculate totals first
      for (final item in _budget!.revenueItems) {
        item.recalculateTotals();
      }
      for (final cat in _budget!.expenseCategories) {
        for (final item in cat.items) {
          item.recalculateTotals();
        }
      }

      await FirebaseFirestore.instance
          .collection('corps')
          .doc(auth.corpsData!.id)
          .collection('financials')
          .doc('budget')
          .set(_budget!.toMap());

      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Financials saved successfully!')),
      );
    } catch (e) {
      debugPrint("Error saving budget: $e");
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving financials: $e')),
      );
    }
  }

  void _onCellChanged() {
    setState(() {});
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      _saveBudgetSilent();
    });
  }

  Future<void> _saveBudgetSilent() async {
    if (_budget == null) return;
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      for (final item in _budget!.revenueItems) {
        item.recalculateTotals();
      }
      for (final cat in _budget!.expenseCategories) {
        for (final item in cat.items) {
          item.recalculateTotals();
        }
      }

      await FirebaseFirestore.instance
          .collection('corps')
          .doc(auth.corpsData!.id)
          .collection('financials')
          .doc('budget')
          .set(_budget!.toMap());
    } catch (e) {
      debugPrint("Error auto-saving budget: $e");
    }
  }

  double get _totalProposedRevenue {
    if (_budget == null) return 0.0;
    return _budget!.revenueItems.fold(0.0, (sum, i) => sum + i.budget);
  }

  double get _totalActualRevenue {
    if (_budget == null) return 0.0;
    return _budget!.revenueItems.fold(0.0, (sum, i) => sum + i.actual);
  }

  double get _totalProposedExpenses {
    if (_budget == null) return 0.0;
    double sum = 0.0;
    for (final cat in _budget!.expenseCategories) {
      sum += cat.items.fold(0.0, (s, i) => s + i.budget);
    }
    return sum;
  }

  double get _totalActualExpenses {
    if (_budget == null) return 0.0;
    double sum = 0.0;
    for (final cat in _budget!.expenseCategories) {
      sum += cat.items.fold(0.0, (s, i) => s + i.actual);
    }
    return sum;
  }

  double get _totalProposedBalance => _totalProposedRevenue - _totalProposedExpenses;
  double get _totalActualBalance => _totalActualRevenue - _totalActualExpenses;

  double get _latestBankBalance => _bankLedger?.currentBalance ?? 0.0;
  double get _projectedEndingBalance => _latestBankBalance + _totalProposedRevenue - _totalProposedExpenses;
  double get _ytdNetCashFlow => _latestBankBalance + _totalActualRevenue - _totalActualExpenses;

  int get _missingReimbursementRationalesCount {
    if (_budget == null) return 0;
    int count = 0;
    for (final cat in _budget!.expenseCategories) {
      for (final item in cat.items) {
        if (item.reimbursement.isEligible && item.reimbursement.rationale.trim().isEmpty) {
          count++;
        }
      }
    }
    return count;
  }

  // Edit dialog/bottom-sheet for single budget item
  void _editBudgetItem(BuildContext context, BudgetItem item, {required bool isRevenue}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return _BudgetItemEditor(
          item: item,
          isRevenue: isRevenue,
          onSave: (updatedItem) {
            setState(() {
              // The items are updated in place since they are passed by reference,
              // but we call setState to trigger a repaint and recalculation.
              item.description = updatedItem.description;
              item.details = updatedItem.details;
              item.periodValues = updatedItem.periodValues;
              item.reimbursement = updatedItem.reimbursement;
              item.explanation = updatedItem.explanation;
              item.recalculateTotals();
            });
            _saveBudget();
          },
        );
      },
    );
  }

  // Modern Export PDF function
  Future<void> _exportPdfReport() async {
    if (_budget == null) return;
    
    final pdf = pw.Document();
    
    // Add page to PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("ARDENT FINANCIALS & BUDGET REPORT", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateFormat('yyyy-MM-dd').format(DateTime.now()), style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            // Financial Summary Block
            pw.Text("Executive Financial Summary", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Metric", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Proposed (Budget)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Actual (YTD)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Variance", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Total Revenues")),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("\$${_totalProposedRevenue.toStringAsFixed(2)}")),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("\$${_totalActualRevenue.toStringAsFixed(2)}")),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("\$${(_totalActualRevenue - _totalProposedRevenue).toStringAsFixed(2)}")),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Total Expenditures")),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("\$${_totalProposedExpenses.toStringAsFixed(2)}")),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("\$${_totalActualExpenses.toStringAsFixed(2)}")),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("\$${(_totalProposedExpenses - _totalActualExpenses).toStringAsFixed(2)}")),
                  ],
                ),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey50),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Net Operating Balance", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("\$${_totalProposedBalance.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("\$${_totalActualBalance.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("\$${(_totalActualBalance - _totalProposedBalance).toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),
            
            // Detailed Revenues Section
            pw.Text("Revenue Breakdown", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey200),
              columnWidths: {
                0: const pw.FlexColumnWidth(3.0),
                1: const pw.FlexColumnWidth(1.0),
                2: const pw.FlexColumnWidth(1.0),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Description", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Proposed", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Actual", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                ..._budget!.revenueItems.map((item) => pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.description)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("\$${item.budget.toStringAsFixed(2)}")),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("\$${item.actual.toStringAsFixed(2)}")),
                  ],
                )),
              ],
            ),
            pw.SizedBox(height: 30),

            // Detailed Expenses Section
            pw.Text("Expenditure Breakdown", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            ..._budget!.expenseCategories.map((cat) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 10),
                pw.Text(cat.name, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700)),
                pw.SizedBox(height: 4),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey200),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3.0),
                    1: const pw.FlexColumnWidth(1.0),
                    2: const pw.FlexColumnWidth(1.0),
                    3: const pw.FlexColumnWidth(1.0),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey50),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Description", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Proposed", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Actual", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Reimbursable", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    ...cat.items.map((item) => pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.description, style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("\$${item.budget.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("\$${item.actual.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.reimbursement.isEligible ? "Yes" : "No", style: const pw.TextStyle(fontSize: 9))),
                      ],
                    )),
                  ],
                ),
              ],
            )),
          ];
        },
      ),
    );

    // Share/Print PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_budget == null) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: const Color(0xFF161920),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.dollarSign, size: 40, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 24),
              const Text(
                'NO ACTIVE BUDGET PLAN',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'Let\'s build a custom budget blueprint for your corps. Initialize using the standard DND model containing seed values for gaming, donations, operating expenses, and activities.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.white60, height: 1.5),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _saving ? null : _seedBudget,
                icon: _saving 
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(LucideIcons.sparkles),
                label: Text(_saving ? 'SEEDING...' : 'SEED BUDGET PLAN'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(LucideIcons.wallet, color: Colors.tealAccent, size: 28),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FINANCIALS & BUDGETS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'PARADE BLUEPRINT & AUDITS',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _confirmResetBudget(context),
            icon: const Icon(LucideIcons.refreshCw, size: 14),
            label: const Text('RESET TO DEFAULTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: _exportPdfReport,
            icon: const Icon(LucideIcons.download, size: 18),
            tooltip: 'Export PDF Audit Report',
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _saving ? null : _saveBudget,
            icon: _saving 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(LucideIcons.save, size: 18),
            tooltip: 'Save Budget Details',
          ),
          const SizedBox(width: 24),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          indicatorColor: theme.colorScheme.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'SUMMARY'),
            Tab(text: 'EXPENSES'),
            Tab(text: 'REVENUE'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildExpenseTab(),
          _buildRevenueTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final theme = Theme.of(context);

    // Calculate details for visualization
    final double profitRatio = _totalProposedRevenue > 0 ? (_totalProposedExpenses / _totalProposedRevenue) : 0.0;
    final double actualProfitRatio = _totalActualRevenue > 0 ? (_totalActualExpenses / _totalActualRevenue) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row of Premium Summary Cards
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'ESTIMATED REVENUE',
                  proposed: _totalProposedRevenue,
                  actual: _totalActualRevenue,
                  icon: LucideIcons.trendingUp,
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _SummaryCard(
                  title: 'BUDGET EXPENDITURES',
                  proposed: _totalProposedExpenses,
                  actual: _totalActualExpenses,
                  icon: LucideIcons.trendingDown,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _SummaryCard(
                  title: 'ESTIMATED SURPLUS',
                  proposed: _totalProposedBalance,
                  actual: _totalActualBalance,
                  icon: LucideIcons.scale,
                  color: Colors.tealAccent,
                  showPositiveNegative: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          
          // Progress & Visualizations Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Card(
                  color: const Color(0xFF161920),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BUDGET DISBURSEMENT INTENSITY',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white54, letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'PROPOSED RATIO: ${(profitRatio * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: profitRatio.clamp(0.0, 1.0),
                            minHeight: 16,
                            backgroundColor: Colors.white.withOpacity(0.05),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'ACTUAL DISBURSEMENT: ${(actualProfitRatio * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: actualProfitRatio.clamp(0.0, 1.0),
                            minHeight: 16,
                            backgroundColor: Colors.white.withOpacity(0.05),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.tealAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: _BudgetHealthCheckCard(
                  projectedEndingBalance: _projectedEndingBalance,
                  ytdNetCashFlow: _ytdNetCashFlow,
                  missingReimbursements: _missingReimbursementRationalesCount,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildBankLedgerSection(theme),
        ],
      ),
    );
  }

  Widget _buildBankLedgerSection(ThemeData theme) {
    if (_ledgerLoading) {
      return Card(
        color: const Color(0xFF161920),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        child: const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final currentBal = _bankLedger?.currentBalance ?? 0.0;
    final lastUpd = _bankLedger?.lastUpdated;
    final history = _bankLedger?.history ?? [];

    final formKey = GlobalKey<FormState>();
    final balanceController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final notesController = TextEditingController();

    return StatefulBuilder(
      builder: (context, setSectionState) {
        return Card(
          color: const Color(0xFF161920),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'BANK BALANCE & REPORTING LEDGER',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white54, letterSpacing: 1.5),
                    ),
                    if (lastUpd != null)
                      Text(
                        'LAST UPDATE: ${DateFormat('yyyy-MM-dd HH:mm').format(lastUpd)}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Current Status and Add New Entry
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Row(
                              children: [
                                Icon(LucideIcons.landmark, color: theme.colorScheme.primary, size: 28),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'CURRENT REPORTED BALANCE',
                                      style: TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${currentBal.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'REPORT NEW BALANCE',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          Form(
                            key: formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: balanceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Balance Amount (\$)',
                                    labelStyle: const TextStyle(color: Colors.white30),
                                    prefixText: '\$ ',
                                    prefixStyle: const TextStyle(color: Colors.white70),
                                    isDense: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.isEmpty) return 'Required';
                                    if (double.tryParse(val) == null) return 'Invalid number';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                // Date selector
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: selectedDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now().add(const Duration(days: 1)),
                                    );
                                    if (picked != null) {
                                      setSectionState(() {
                                        selectedDate = picked;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Report Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                                          style: const TextStyle(color: Colors.white, fontSize: 13),
                                        ),
                                        const Icon(LucideIcons.calendar, size: 16, color: Colors.white54),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: notesController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Notes / Source (e.g. Statement)',
                                    labelStyle: const TextStyle(color: Colors.white30),
                                    isDense: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    if (!formKey.currentState!.validate()) return;
                                    final amt = double.parse(balanceController.text);
                                    final auth = Provider.of<AuthProvider>(context, listen: false);
                                    final entry = BankLedgerEntry.create(
                                      balance: amt,
                                      date: selectedDate,
                                      notes: notesController.text,
                                      reportedBy: auth.userData?.name ?? 'Staff',
                                    );

                                    setState(() {
                                      final currentList = _bankLedger?.history ?? [];
                                      final newList = List<BankLedgerEntry>.from(currentList)..insert(0, entry); // Insert at beginning to keep sorted descending
                                      _bankLedger = BankLedger(history: newList);
                                    });

                                    // clear form
                                    balanceController.clear();
                                    notesController.clear();

                                    await _saveBankLedger();
                                    
                                    // Trigger rebuild of StatefulBuilder inside section
                                    setSectionState(() {
                                      selectedDate = DateTime.now();
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Bank balance updated successfully!')),
                                    );
                                  },
                                  icon: const Icon(LucideIcons.plus, size: 16),
                                  label: const Text('SUBMIT REPORT'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 40),
                    // Right Column: Ledger History Table
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'REPORTING HISTORY',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          if (history.isEmpty)
                            Container(
                              height: 280,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.01),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: const Text(
                                'No reported balances yet.',
                                style: TextStyle(color: Colors.white30, fontSize: 13),
                              ),
                            )
                          else ...[
                            // Table Header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.02),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(flex: 2, child: Text('DATE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white54, letterSpacing: 0.5))),
                                  Expanded(flex: 2, child: Text('BALANCE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white54, letterSpacing: 0.5))),
                                  Expanded(flex: 2, child: Text('REPORTED BY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white54, letterSpacing: 0.5))),
                                  Expanded(flex: 3, child: Text('NOTES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white54, letterSpacing: 0.5))),
                                ],
                              ),
                            ),
                            // Table Body Container
                            Container(
                              constraints: const BoxConstraints(maxHeight: 240),
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(color: Colors.white.withOpacity(0.05)),
                                  right: BorderSide(color: Colors.white.withOpacity(0.05)),
                                  bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                                ),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: history.length,
                                  itemBuilder: (ctx, index) {
                                    final entry = history[index];
                                    final isLast = index == history.length - 1;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: index % 2 == 0 ? Colors.transparent : Colors.white.withOpacity(0.01),
                                        border: Border(
                                          bottom: isLast ? BorderSide.none : BorderSide(color: Colors.white.withOpacity(0.03)),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(flex: 2, child: Text(DateFormat('yyyy-MM-dd').format(entry.date), style: const TextStyle(color: Colors.white70, fontSize: 12))),
                                          Expanded(flex: 2, child: Text('\$${entry.balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                          Expanded(flex: 2, child: Text(entry.reportedBy, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                          Expanded(flex: 3, child: Text(entry.notes.isNotEmpty ? entry.notes : '-', style: const TextStyle(color: Colors.white30, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRevenueTab() {
    if (_budget == null) return const SizedBox();

    // Group revenues by their configured category if any
    final Map<String, List<BudgetItem>> grouped = {};
    for (final item in _budget!.revenueItems) {
      final cat = item.category ?? 'Uncategorized';
      grouped.putIfAbsent(cat, () => []).add(item);
    }

    return ListView(
      padding: const EdgeInsets.all(32),
      children: grouped.entries.map((entry) {
        return _BudgetCategoryTable(
          categoryName: entry.key,
          items: entry.value,
          isRevenue: true,
          onChanged: _onCellChanged,
          onAddItem: () {
            setState(() {
              _budget!.revenueItems.add(BudgetItem.createEmpty(
                'New Revenue Line',
                category: entry.key,
              ));
            });
            _onCellChanged();
          },
          onDelete: (item) async {
            final confirmed = await _confirmDeleteRow(item.description);
            if (confirmed) {
              setState(() {
                _budget!.revenueItems.removeWhere((i) => i.id == item.id);
              });
              _onCellChanged();
            }
          },
          onEditDetails: (item) => _editBudgetItem(context, item, isRevenue: true),
        );
      }).toList(),
    );
  }

  Widget _buildExpenseTab() {
    if (_budget == null) return const SizedBox();

    return ListView(
      padding: const EdgeInsets.all(32),
      children: _budget!.expenseCategories.map((cat) {
        return _BudgetCategoryTable(
          categoryName: cat.name,
          items: cat.items,
          isRevenue: false,
          onChanged: _onCellChanged,
          onAddItem: () {
            setState(() {
              cat.items.add(BudgetItem.createEmpty('New Expense Line'));
            });
            _onCellChanged();
          },
          onDelete: (item) async {
            final confirmed = await _confirmDeleteRow(item.description);
            if (confirmed) {
              setState(() {
                cat.items.removeWhere((i) => i.id == item.id);
              });
              _onCellChanged();
            }
          },
          onEditDetails: (item) => _editBudgetItem(context, item, isRevenue: false),
        );
      }).toList(),
    );
  }

  Future<bool> _confirmDeleteRow(String description) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161920),
        title: const Text('Delete Line Item?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "$description"? This action cannot be undone.',
          style: const TextStyle(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    ) ?? false;
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double proposed;
  final double actual;
  final IconData icon;
  final Color color;
  final bool showPositiveNegative;

  const _SummaryCard({
    required this.title,
    required this.proposed,
    required this.actual,
    required this.icon,
    required this.color,
    this.showPositiveNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(decimalDigits: 2);
    final variance = actual - proposed;

    return Card(
      color: const Color(0xFF161920),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 1.5),
                ),
                Icon(icon, size: 18, color: color),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              currency.format(proposed),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'YTD Actual: ${currency.format(actual)}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                ),
                Text(
                  (variance >= 0 ? '+' : '') + currency.format(variance),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: variance >= 0 
                        ? (showPositiveNegative ? Colors.greenAccent : Colors.white38)
                        : Colors.redAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Dialog editor for items
class _BudgetItemEditor extends StatefulWidget {
  final BudgetItem item;
  final bool isRevenue;
  final Function(BudgetItem) onSave;

  const _BudgetItemEditor({
    required this.item,
    required this.isRevenue,
    required this.onSave,
  });

  @override
  State<_BudgetItemEditor> createState() => _BudgetItemEditorState();
}

class _BudgetItemEditorState extends State<_BudgetItemEditor> {
  late TextEditingController _descController;
  late TextEditingController _detailsController;
  late TextEditingController _explanationController;
  late TextEditingController _reimburseRationaleController;
  
  final Map<String, TextEditingController> _proposedControllers = {};
  final Map<String, TextEditingController> _actualControllers = {};

  bool _isReimbursementEligible = false;

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(text: widget.item.description);
    _detailsController = TextEditingController(text: widget.item.details ?? '');
    _explanationController = TextEditingController(text: widget.item.explanation);
    _reimburseRationaleController = TextEditingController(text: widget.item.reimbursement.rationale);
    
    _isReimbursementEligible = widget.item.reimbursement.isEligible;

    for (final period in BudgetDefaults.reportingPeriods) {
      final pVal = widget.item.periodValues[period] ?? PeriodValue();
      _proposedControllers[period] = TextEditingController(text: pVal.proposed.toStringAsFixed(2));
      _actualControllers[period] = TextEditingController(text: pVal.actual.toStringAsFixed(2));
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _detailsController.dispose();
    _explanationController.dispose();
    _reimburseRationaleController.dispose();
    for (final c in _proposedControllers.values) {
      c.dispose();
    }
    for (final c in _actualControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: const Color(0xFF161920),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      child: Container(
        width: 700,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (widget.isRevenue ? 'REVENUE BUDGET ITEM' : 'EXPENSE AUDIT LINE').toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.item.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x, color: Colors.white38),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'LINE ITEM DESCRIPTION',
                        hintText: 'Edit description...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _detailsController,
                      decoration: const InputDecoration(
                        labelText: 'ADDITIONAL DETAILS',
                        hintText: 'Add details/context...',
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'PERIODIC DISTRIBUTION',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white54, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 12),
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1.2),
                        1: FlexColumnWidth(1.0),
                        2: FlexColumnWidth(1.0),
                      },
                      children: [
                        TableRow(
                          children: [
                            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Period', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white38))),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Proposed (\$)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white38))),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Actual (\$)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white38))),
                          ],
                        ),
                        ...BudgetDefaults.reportingPeriods.map((period) {
                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(period, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 12, bottom: 8),
                                child: TextField(
                                  controller: _proposedControllers[period],
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: TextField(
                                  controller: _actualControllers[period],
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                    if (!widget.isRevenue) ...[
                      const SizedBox(height: 24),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: _isReimbursementEligible,
                            onChanged: (val) {
                              setState(() {
                                _isReimbursementEligible = val ?? false;
                              });
                            },
                          ),
                          const Text(
                            'ELIGIBLE FOR REIMBURSEMENT',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      if (_isReimbursementEligible) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _reimburseRationaleController,
                          decoration: const InputDecoration(
                            labelText: 'REIMBURSEMENT RATIONALE',
                            hintText: 'Enter justification for reimbursement...',
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: _explanationController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'INTERNAL COMMENTS / EXPLANATION',
                        hintText: 'Write audit notes...',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('CANCEL'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    final Map<String, PeriodValue> newPeriods = {};
                    for (final p in BudgetDefaults.reportingPeriods) {
                      final prop = double.tryParse(_proposedControllers[p]?.text ?? '') ?? 0.0;
                      final act = double.tryParse(_actualControllers[p]?.text ?? '') ?? 0.0;
                      newPeriods[p] = PeriodValue(proposed: prop, actual: act);
                    }

                    final updated = BudgetItem(
                      id: widget.item.id,
                      description: _descController.text,
                      details: _detailsController.text.isNotEmpty ? _detailsController.text : null,
                      periodValues: newPeriods,
                      budget: 0.0,
                      actual: 0.0,
                      reimbursement: Reimbursement(
                        isEligible: _isReimbursementEligible,
                        rationale: _reimburseRationaleController.text,
                      ),
                      explanation: _explanationController.text,
                    );

                    widget.onSave(updated);
                    Navigator.of(context).pop();
                  },
                  child: const Text('SAVE BLUEPRINT'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CellInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool isBold;
  final Color? textColor;

  const _CellInput({
    required this.controller,
    required this.onChanged,
    this.isBold = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.right,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: 12,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
      ),
    );
  }
}

class _BudgetCategoryTable extends StatefulWidget {
  final String categoryName;
  final List<BudgetItem> items;
  final bool isRevenue;
  final VoidCallback onChanged;
  final Function(BudgetItem) onDelete;
  final Function(BudgetItem) onEditDetails;
  final VoidCallback onAddItem;

  const _BudgetCategoryTable({
    required this.categoryName,
    required this.items,
    required this.isRevenue,
    required this.onChanged,
    required this.onDelete,
    required this.onEditDetails,
    required this.onAddItem,
  });

  @override
  State<_BudgetCategoryTable> createState() => _BudgetCategoryTableState();
}

class _RowControllers {
  final TextEditingController descController;
  final Map<String, TextEditingController> proposedControllers;
  final Map<String, TextEditingController> actualControllers;

  _RowControllers({
    required this.descController,
    required this.proposedControllers,
    required this.actualControllers,
  });

  void dispose() {
    descController.dispose();
    for (final c in proposedControllers.values) {
      c.dispose();
    }
    for (final c in actualControllers.values) {
      c.dispose();
    }
  }
}

class _BudgetCategoryTableState extends State<_BudgetCategoryTable> {
  final Map<String, _RowControllers> _controllersMap = {};

  @override
  void didUpdateWidget(covariant _BudgetCategoryTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    final itemIds = widget.items.map((i) => i.id).toSet();
    _controllersMap.keys.toList().forEach((id) {
      if (!itemIds.contains(id)) {
        _controllersMap.remove(id)?.dispose();
      }
    });
  }

  @override
  void dispose() {
    for (final rc in _controllersMap.values) {
      rc.dispose();
    }
    super.dispose();
  }

  _RowControllers _getOrCreateControllers(BudgetItem item) {
    if (_controllersMap.containsKey(item.id)) {
      return _controllersMap[item.id]!;
    }

    final descC = TextEditingController(text: item.description);
    final propC = <String, TextEditingController>{};
    final actC = <String, TextEditingController>{};

    for (final period in BudgetDefaults.reportingPeriods) {
      final pVal = item.periodValues[period] ?? PeriodValue();
      propC[period] = TextEditingController(text: pVal.proposed == 0.0 ? '' : pVal.proposed.toStringAsFixed(0));
      actC[period] = TextEditingController(text: pVal.actual == 0.0 ? '' : pVal.actual.toStringAsFixed(0));
    }

    final rc = _RowControllers(
      descController: descC,
      proposedControllers: propC,
      actualControllers: actC,
    );
    _controllersMap[item.id] = rc;
    return rc;
  }

  @override
  Widget build(BuildContext context) {
    const double descWidth = 240;
    const double cellWidth = 72;
    const double totalWidth = 85;
    const double actionsWidth = 120;
    const double totalTableWidth = descWidth + (cellWidth * 8) + (totalWidth * 2) + actionsWidth;

    return Card(
      color: const Color(0xFF161920),
      margin: const EdgeInsets.only(bottom: 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Title Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.categoryName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: widget.isRevenue ? Colors.greenAccent : Colors.redAccent,
                    letterSpacing: 1.2,
                  ),
                ),
                TextButton.icon(
                  onPressed: widget.onAddItem,
                  icon: const Icon(LucideIcons.plus, size: 14),
                  label: const Text('ADD ROW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    foregroundColor: widget.isRevenue ? Colors.greenAccent : Colors.redAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Horizontal scroll container for the spreadsheet grid
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: totalTableWidth + 2,
                child: Column(
                  children: [
                    // TOP HEADER ROW
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: descWidth,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Text('LINE ITEM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white38)),
                            ),
                          ),
                          ...BudgetDefaults.reportingPeriods.map((period) {
                            return SizedBox(
                              width: cellWidth * 2,
                              child: Center(
                                child: Text(
                                  period.toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white70, letterSpacing: 0.5),
                                ),
                              ),
                            );
                          }).toList(),
                          const SizedBox(
                            width: totalWidth * 2,
                            child: Center(
                              child: Text(
                                'YTD TOTALS',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.tealAccent, letterSpacing: 0.5),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: actionsWidth,
                            child: Center(
                              child: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white38)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // SUB HEADER ROW (Est / Act)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.01),
                        border: Border(
                          left: BorderSide(color: Colors.white.withOpacity(0.05)),
                          right: BorderSide(color: Colors.white.withOpacity(0.05)),
                          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: descWidth),
                          ...BudgetDefaults.reportingPeriods.map((_) {
                            return SizedBox(
                              width: cellWidth * 2,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: cellWidth,
                                    child: const Center(child: Text('EST', style: TextStyle(fontSize: 9, color: Colors.white30, fontWeight: FontWeight.bold))),
                                  ),
                                  SizedBox(
                                    width: cellWidth,
                                    child: const Center(child: Text('ACT', style: TextStyle(fontSize: 9, color: Colors.white30, fontWeight: FontWeight.bold))),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          SizedBox(
                            width: totalWidth * 2,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: totalWidth,
                                  child: const Center(child: Text('EST', style: TextStyle(fontSize: 9, color: Colors.tealAccent, fontWeight: FontWeight.bold))),
                                ),
                                SizedBox(
                                  width: totalWidth,
                                  child: const Center(child: Text('ACT', style: TextStyle(fontSize: 9, color: Colors.tealAccent, fontWeight: FontWeight.bold))),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: actionsWidth),
                        ],
                      ),
                    ),
                    // DATA ROWS
                    if (widget.items.isEmpty)
                      Container(
                        width: totalTableWidth,
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: Colors.white.withOpacity(0.05)),
                            right: BorderSide(color: Colors.white.withOpacity(0.05)),
                            bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                          ),
                        ),
                        child: const Center(
                          child: Text('No items in this category. Add a row to get started.', style: TextStyle(color: Colors.white24, fontSize: 12)),
                        ),
                      )
                    else
                      ...widget.items.map((item) {
                        final rc = _getOrCreateControllers(item);
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(color: Colors.white.withOpacity(0.05)),
                              right: BorderSide(color: Colors.white.withOpacity(0.05)),
                              bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Line Item Description (Editable)
                              SizedBox(
                                width: descWidth,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      TextField(
                                        controller: rc.descController,
                                        onChanged: (val) {
                                          item.description = val;
                                          widget.onChanged();
                                        },
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                          border: InputBorder.none,
                                          hintText: 'Description...',
                                          hintStyle: TextStyle(color: Colors.white24),
                                        ),
                                      ),
                                      if (item.details != null && item.details!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4, bottom: 4),
                                          child: Text(
                                            item.details!,
                                            style: const TextStyle(fontSize: 11, color: Colors.white38),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              // Periods inputs
                              ...BudgetDefaults.reportingPeriods.map((period) {
                                return SizedBox(
                                  width: cellWidth * 2,
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: cellWidth,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                          child: _CellInput(
                                            controller: rc.proposedControllers[period]!,
                                            onChanged: (val) {
                                              final parsed = double.tryParse(val) ?? 0.0;
                                              item.periodValues[period]!.proposed = parsed;
                                              item.recalculateTotals();
                                              widget.onChanged();
                                            },
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: cellWidth,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                          child: _CellInput(
                                            controller: rc.actualControllers[period]!,
                                            textColor: widget.isRevenue ? Colors.greenAccent : Colors.redAccent,
                                            onChanged: (val) {
                                              final parsed = double.tryParse(val) ?? 0.0;
                                              item.periodValues[period]!.actual = parsed;
                                              item.recalculateTotals();
                                              widget.onChanged();
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              // YTD totals (Display only)
                              SizedBox(
                                width: totalWidth * 2,
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: totalWidth,
                                      child: Center(
                                        child: Text(
                                          '\$${item.budget.toStringAsFixed(0)}',
                                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: totalWidth,
                                      child: Center(
                                        child: Text(
                                          '\$${item.actual.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            color: widget.isRevenue ? Colors.greenAccent : Colors.redAccent,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Row Actions
                              SizedBox(
                                width: actionsWidth,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (!widget.isRevenue) ...[
                                      // Reimbursement eligibility toggle
                                      IconButton(
                                        padding: const EdgeInsets.all(6),
                                        constraints: const BoxConstraints(),
                                        icon: Icon(
                                          item.reimbursement.isEligible ? LucideIcons.coins : LucideIcons.ban,
                                          size: 14,
                                          color: item.reimbursement.isEligible ? Colors.tealAccent : Colors.white24,
                                        ),
                                        tooltip: item.reimbursement.isEligible ? 'Reimbursement: Eligible' : 'Reimbursement: Ineligible',
                                        onPressed: () {
                                          item.reimbursement.isEligible = !item.reimbursement.isEligible;
                                          widget.onChanged();
                                        },
                                      ),
                                    ],
                                    IconButton(
                                      padding: const EdgeInsets.all(6),
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(LucideIcons.info, size: 14, color: Colors.white54),
                                      tooltip: 'Full Details',
                                      onPressed: () => widget.onEditDetails(item),
                                    ),
                                    IconButton(
                                      padding: const EdgeInsets.all(6),
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(LucideIcons.trash2, size: 14, color: Colors.redAccent),
                                      tooltip: 'Delete Line',
                                      onPressed: () => widget.onDelete(item),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetHealthCheckCard extends StatelessWidget {
  final double projectedEndingBalance;
  final double ytdNetCashFlow;
  final int missingReimbursements;

  const _BudgetHealthCheckCard({
    required this.projectedEndingBalance,
    required this.ytdNetCashFlow,
    required this.missingReimbursements,
  });

  @override
  Widget build(BuildContext context) {
    // Determine overall status
    final bool isCritical = ytdNetCashFlow < 0;
    final bool isWarning = projectedEndingBalance < 0 || missingReimbursements > 0;
    
    Color statusColor = Colors.tealAccent;
    String statusText = 'HEALTHY';
    IconData statusIcon = LucideIcons.checkCircle2;
    
    if (isCritical) {
      statusColor = Colors.redAccent;
      statusText = 'CRITICAL';
      statusIcon = LucideIcons.alertTriangle;
    } else if (isWarning) {
      statusColor = Colors.amber;
      statusText = 'WARNING';
      statusIcon = LucideIcons.alertCircle;
    }

    return Card(
      color: const Color(0xFF161920),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.2), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'BUDGET & CASH HEALTH CHECK',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white54,
                    letterSpacing: 1.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 12),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Check 1: Projected Ending Balance
            _buildCheckItem(
              icon: projectedEndingBalance >= 0 ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
              iconColor: projectedEndingBalance >= 0 ? Colors.tealAccent : Colors.amber,
              title: 'Projected Solvency Check',
              value: '\$${projectedEndingBalance.toStringAsFixed(0)}',
              desc: projectedEndingBalance >= 0
                  ? 'Projected balance is positive based on planned expenses and revenues.'
                  : 'Proposed expenditures exceed current balance + projected revenue by \$${(projectedEndingBalance.abs()).toStringAsFixed(0)}.',
            ),
            const Divider(color: Colors.white10, height: 24),
            
            // Check 2: YTD Net Cash Flow
            _buildCheckItem(
              icon: ytdNetCashFlow >= 0 ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle,
              iconColor: ytdNetCashFlow >= 0 ? Colors.tealAccent : Colors.redAccent,
              title: 'YTD Cash Flow Check',
              value: '\$${ytdNetCashFlow.toStringAsFixed(0)}',
              desc: ytdNetCashFlow >= 0
                  ? 'Actual expenses to date are fully funded by reported bank cash.'
                  : 'CRITICAL: Actual expenses to date exceed available bank cash + actual revenue by \$${(ytdNetCashFlow.abs()).toStringAsFixed(0)}!',
            ),
            const Divider(color: Colors.white10, height: 24),
            
            // Check 3: Reimbursement Compliance
            _buildCheckItem(
              icon: missingReimbursements == 0 ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
              iconColor: missingReimbursements == 0 ? Colors.tealAccent : Colors.amber,
              title: 'Reimbursement Audit Check',
              value: missingReimbursements == 0 ? 'Compliant' : '$missingReimbursements Missing',
              desc: missingReimbursements == 0
                  ? 'All reimbursement eligible expenses have justification rationales.'
                  : '$missingReimbursements reimbursement eligible line items do not have justifications reported.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    value,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: iconColor),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: const TextStyle(fontSize: 11, color: Colors.white54, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

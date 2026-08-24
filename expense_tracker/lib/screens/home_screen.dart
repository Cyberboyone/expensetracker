import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/budget.dart';
import '../models/expense.dart';
import '../models/expense_filter.dart';
import '../services/export_service.dart';
import '../services/storage_service.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/expense_tile.dart';
import '../widgets/category_style.dart';
import '../widgets/filter_sheet.dart';
import 'add_edit_expense_screen.dart';
import 'budget_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = StorageService();
  final _exportService = ExportService();

  List<Expense> _expenses = [];
  Budget _budget = Budget();
  ExpenseFilter _filter = const ExpenseFilter();
  bool _loading = true;
  bool _searching = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await _storage.loadExpenses();
    final budget = await _storage.loadBudget();
    data.sort((a, b) => b.date.compareTo(a.date));
    setState(() {
      _expenses = data;
      _budget = budget;
      _loading = false;
    });
  }

  Future<void> _persistExpenses() async => _storage.saveExpenses(_expenses);

  double get _total => _expenses.fold(0.0, (sum, e) => sum + e.amount);

  double get _thisMonthSpend {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  List<Expense> get _filteredExpenses => _expenses.where(_filter.matches).toList();

  Map<ExpenseCategory, double> get _byCategory {
    final map = <ExpenseCategory, double>{};
    for (final e in _filteredExpenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  Future<void> _openAddScreen({Expense? existing}) async {
    final result = await Navigator.of(context).push<Expense>(
      MaterialPageRoute(builder: (_) => AddEditExpenseScreen(existing: existing)),
    );
    if (result == null) return;

    setState(() {
      if (existing != null) {
        final idx = _expenses.indexWhere((e) => e.id == existing.id);
        _expenses[idx] = result;
      } else {
        _expenses.add(result);
      }
      _expenses.sort((a, b) => b.date.compareTo(a.date));
    });
    await _persistExpenses();
  }

  Future<void> _delete(Expense e) async {
    setState(() => _expenses.removeWhere((x) => x.id == e.id));
    await _persistExpenses();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${e.title}"'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              setState(() {
                _expenses.add(e);
                _expenses.sort((a, b) => b.date.compareTo(a.date));
              });
              await _persistExpenses();
            },
          ),
        ),
      );
    }
  }

  Future<void> _openBudgetScreen() async {
    final result = await Navigator.of(context).push<Budget>(
      MaterialPageRoute(builder: (_) => BudgetScreen(budget: _budget, expenses: _expenses)),
    );
    if (result == null) return;
    setState(() => _budget = result);
    await _storage.saveBudget(result);
  }

  Future<void> _exportCsv() async {
    final list = _filteredExpenses;
    if (list.isEmpty) {
      _showSnack('Nothing to export');
      return;
    }
    await _exportService.exportCsv(list);
  }

  Future<void> _exportBackup() async {
    await _exportService.exportBackup(_expenses, _budget);
  }

  Future<void> _restoreBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore backup?'),
        content: const Text(
          'This will replace all current expenses and budgets with the contents of the backup file. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restore')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final result = await _exportService.pickAndReadBackup();
      if (result == null) return;
      final (expenses, budget) = result;
      await _storage.restoreAll(expenses: expenses, budget: budget);
      setState(() {
        _expenses = expenses..sort((a, b) => b.date.compareTo(a.date));
        _budget = budget;
      });
      _showSnack('Backup restored');
    } catch (_) {
      _showSnack('Could not read that backup file');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openFilterSheet() async {
    final result = await showFilterSheet(context, _filter);
    if (result != null) setState(() => _filter = result);
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '₦', decimalDigits: 2);
    final filtered = _filteredExpenses;

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search expenses…',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _filter = _filter.copyWith(query: v)),
              )
            : const Text('Expense Tracker'),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _searching = !_searching;
                if (!_searching) {
                  _searchController.clear();
                  _filter = _filter.copyWith(query: '');
                }
              });
            },
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: _filter.categories.isNotEmpty || _filter.rangeType != DateRangeFilter.all,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _openFilterSheet,
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
                case 'budget':
                  _openBudgetScreen();
                  break;
                case 'export_csv':
                  _exportCsv();
                  break;
                case 'backup':
                  _exportBackup();
                  break;
                case 'restore':
                  _restoreBackup();
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'budget', child: Text('Set Budget')),
              PopupMenuItem(value: 'export_csv', child: Text('Export CSV')),
              PopupMenuItem(value: 'backup', child: Text('Backup Data')),
              PopupMenuItem(value: 'restore', child: Text('Restore Backup')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _expenses.isEmpty
              ? _EmptyState(onAdd: () => _openAddScreen())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 90),
                    children: [
                      _TotalCard(total: _total, currency: currency),
                      if (_budget.overallMonthly != null)
                        BudgetProgressCard(
                          spend: _thisMonthSpend,
                          budget: _budget.overallMonthly!,
                          onTap: _openBudgetScreen,
                        ),
                      if (_byCategory.length > 1) _CategoryChart(byCategory: _byCategory),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Expenses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            if (_filter.isActive)
                              Text(
                                '${filtered.length} of ${_expenses.length} • ${currency.format(filtered.fold(0.0, (s, e) => s + e.amount))}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      if (filtered.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('No expenses match your filters')),
                        )
                      else
                        ...filtered.map(
                          (e) => ExpenseTile(
                            expense: e,
                            onTap: () => _openAddScreen(existing: e),
                            onDismissed: () => _delete(e),
                          ),
                        ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddScreen(),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final double total;
  final NumberFormat currency;

  const _TotalCard({required this.total, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Spent', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            currency.format(total),
            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  final Map<ExpenseCategory, double> byCategory;

  const _CategoryChart({required this.byCategory});

  @override
  Widget build(BuildContext context) {
    final entries = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = byCategory.values.fold(0.0, (a, b) => a + b);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 120,
            width: 120,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                sections: entries
                    .map((e) => PieChartSectionData(
                          value: e.value,
                          color: CategoryStyle.color(e.key),
                          showTitle: false,
                          radius: 24,
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries.take(4).map((e) {
                final pct = total == 0 ? 0 : (e.value / total * 100);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, color: CategoryStyle.color(e.key)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(e.key.label, style: const TextStyle(fontSize: 13))),
                      Text('${pct.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long, size: 72, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          const Text('No expenses yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Tap below to add your first expense'),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add Expense')),
        ],
      ),
    );
  }
}

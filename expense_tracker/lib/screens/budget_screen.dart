import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../models/expense.dart';
import '../widgets/category_style.dart';

class BudgetScreen extends StatefulWidget {
  final Budget budget;
  final List<Expense> expenses;

  const BudgetScreen({super.key, required this.budget, required this.expenses});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late TextEditingController _overallController;
  late Map<ExpenseCategory, TextEditingController> _categoryControllers;

  @override
  void initState() {
    super.initState();
    _overallController = TextEditingController(
      text: widget.budget.overallMonthly?.toStringAsFixed(0) ?? '',
    );
    _categoryControllers = {
      for (final c in ExpenseCategory.values)
        c: TextEditingController(
          text: widget.budget.categoryMonthly[c]?.toStringAsFixed(0) ?? '',
        ),
    };
  }

  @override
  void dispose() {
    _overallController.dispose();
    for (final c in _categoryControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double _thisMonthSpend([ExpenseCategory? category]) {
    final now = DateTime.now();
    return widget.expenses
        .where((e) =>
            e.date.year == now.year &&
            e.date.month == now.month &&
            (category == null || e.category == category))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  void _save() {
    final overall = double.tryParse(_overallController.text.trim());
    final catMap = <ExpenseCategory, double>{};
    _categoryControllers.forEach((cat, controller) {
      final v = double.tryParse(controller.text.trim());
      if (v != null && v > 0) catMap[cat] = v;
    });

    final budget = Budget(
      overallMonthly: (overall != null && overall > 0) ? overall : null,
      categoryMonthly: catMap,
    );
    Navigator.of(context).pop(budget);
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
    final overallSpend = _thisMonthSpend();

    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'This month you\'ve spent ${currency.format(overallSpend)}. '
            'Set limits below to get warned when you\'re close.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _overallController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Overall monthly budget',
              prefixText: '₦ ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Per-category budgets (optional)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          ...ExpenseCategory.values.map((c) {
            final spend = _thisMonthSpend(c);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(CategoryStyle.icon(c), color: CategoryStyle.color(c), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Text(c.label),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      currency.format(spend),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _categoryControllers[c],
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        isDense: true,
                        prefixText: '₦ ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('Save Budgets'),
          ),
        ],
      ),
    );
  }
}

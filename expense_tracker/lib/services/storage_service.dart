import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import '../models/budget.dart';

/// Handles all local persistence for expenses and budgets. No backend, no
/// login — everything lives on-device via SharedPreferences as JSON blobs.
class StorageService {
  static const _expensesKey = 'expenses_v1';
  static const _budgetKey = 'budget_v1';

  Future<List<Expense>> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_expensesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return Expense.decodeList(raw);
    } catch (_) {
      // Corrupt data shouldn't crash the app — start fresh.
      return [];
    }
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_expensesKey, Expense.encodeList(expenses));
  }

  Future<Budget> loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_budgetKey);
    if (raw == null || raw.isEmpty) return Budget();
    try {
      return Budget.decode(raw);
    } catch (_) {
      return Budget();
    }
  }

  Future<void> saveBudget(Budget budget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_budgetKey, Budget.encode(budget));
  }

  /// Replaces all local data at once — used when restoring a backup file.
  Future<void> restoreAll({required List<Expense> expenses, required Budget budget}) async {
    await saveExpenses(expenses);
    await saveBudget(budget);
  }
}

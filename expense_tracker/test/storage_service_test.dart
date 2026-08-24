import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/models/budget.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('StorageService', () {
    test('loadExpenses returns empty when nothing is stored', () async {
      final service = StorageService();
      expect(await service.loadExpenses(), isEmpty);
    });

    test('saves and loads expenses', () async {
      final service = StorageService();
      await service.saveExpenses([
        Expense(
          id: '1',
          title: 'Groceries',
          amount: 4500.5,
          category: ExpenseCategory.food,
          date: DateTime(2026, 8, 24),
          note: 'weekly shop',
        ),
      ]);

      final loaded = await service.loadExpenses();
      expect(loaded, hasLength(1));
      expect(loaded.first.title, 'Groceries');
      expect(loaded.first.amount, 4500.5);
      expect(loaded.first.note, 'weekly shop');
    });

    test('corrupt expense data does not crash and returns empty', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'expenses_v1': 'this is not json',
      });
      final service = StorageService();

      expect(await service.loadExpenses(), isEmpty);
    });

    test('budget round trip', () async {
      final service = StorageService();
      final budget = Budget(
        overallMonthly: 100000,
        categoryMonthly: {ExpenseCategory.health: 20000},
      );

      await service.saveBudget(budget);
      final loaded = await service.loadBudget();

      expect(loaded.overallMonthly, 100000);
      expect(loaded.categoryMonthly[ExpenseCategory.health], 20000);
    });

    test('loadBudget returns empty budget when nothing stored', () async {
      final service = StorageService();
      final budget = await service.loadBudget();

      expect(budget.isEmpty, isTrue);
    });

    test('restoreAll replaces all data', () async {
      final service = StorageService();
      await service.saveExpenses([
        Expense(
          id: 'old',
          title: 'Old',
          amount: 1,
          category: ExpenseCategory.food,
          date: DateTime(2026, 1, 1),
        ),
      ]);
      await service.saveBudget(Budget(overallMonthly: 999));

      await service.restoreAll(
        expenses: [
          Expense(
            id: 'new',
            title: 'New',
            amount: 50,
            category: ExpenseCategory.transport,
            date: DateTime(2026, 2, 2),
          ),
        ],
        budget: Budget(overallMonthly: 5000),
      );

      final expenses = await service.loadExpenses();
      final budget = await service.loadBudget();

      expect(expenses, hasLength(1));
      expect(expenses.first.id, 'new');
      expect(budget.overallMonthly, 5000);
    });
  });
}

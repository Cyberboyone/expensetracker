import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/budget.dart';
import 'package:expense_tracker/models/expense.dart';

void main() {
  group('Budget model', () {
    test('empty budget has isEmpty true', () {
      expect(Budget().isEmpty, isTrue);
    });

    test('non-empty budget has isEmpty false', () {
      expect(Budget(overallMonthly: 1000).isEmpty, isFalse);
      expect(
        Budget(categoryMonthly: {ExpenseCategory.food: 500}).isEmpty,
        isFalse,
      );
    });

    test('JSON round trip preserves overall and per-category budgets', () {
      final b = Budget(
        overallMonthly: 100000,
        categoryMonthly: {
          ExpenseCategory.food: 30000,
          ExpenseCategory.transport: 20000,
        },
      );

      final restored = Budget.decode(Budget.encode(b));

      expect(restored.overallMonthly, 100000);
      expect(restored.categoryMonthly[ExpenseCategory.food], 30000);
      expect(restored.categoryMonthly[ExpenseCategory.transport], 20000);
    });

    test('unknown category name in JSON falls back to other', () {
      final json = <String, dynamic>{
        'overallMonthly': 5000,
        'categoryMonthly': <String, dynamic>{
          'food': 1000,
          'space_travel': 2000,
        },
      };

      final b = Budget.fromJson(json);

      expect(b.categoryMonthly[ExpenseCategory.food], 1000);
      expect(b.categoryMonthly[ExpenseCategory.other], 2000);
      expect(b.categoryMonthly, hasLength(2));
    });

    test('missing categoryMonthly in JSON yields empty map', () {
      final json = <String, dynamic>{'overallMonthly': 5000};
      final b = Budget.fromJson(json);

      expect(b.overallMonthly, 5000);
      expect(b.categoryMonthly, isEmpty);
    });

    test('copyWith can clear the overall budget', () {
      final b = Budget(overallMonthly: 1000, categoryMonthly: {ExpenseCategory.food: 100});

      final cleared = b.copyWith(clearOverall: true);

      expect(cleared.overallMonthly, isNull);
      expect(cleared.categoryMonthly[ExpenseCategory.food], 100);
    });
  });
}

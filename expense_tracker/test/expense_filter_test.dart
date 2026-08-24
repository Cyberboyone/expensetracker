import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/expense_filter.dart';

Expense makeExpense({
  String title = 'Lunch',
  double amount = 100,
  ExpenseCategory category = ExpenseCategory.food,
  DateTime? date,
  String? note,
}) {
  return Expense(
    id: 'id-$title-$category-${date?.toIso8601String()}',
    title: title,
    amount: amount,
    category: category,
    date: date ?? DateTime(2026, 8, 24),
    note: note,
  );
}

void main() {
  group('ExpenseFilter', () {
    test('default filter matches everything', () {
      const f = ExpenseFilter();
      expect(f.matches(makeExpense()), isTrue);
      expect(f.isActive, isFalse);
    });

    test('isActive reflects any active criteria', () {
      expect(const ExpenseFilter(query: 'x').isActive, isTrue);
      expect(
        const ExpenseFilter(categories: {ExpenseCategory.food}).isActive,
        isTrue,
      );
      expect(
        const ExpenseFilter(rangeType: DateRangeFilter.thisMonth).isActive,
        isTrue,
      );
      expect(const ExpenseFilter(query: '   ').isActive, isFalse);
    });

    group('query', () {
      test('matches title case-insensitively', () {
        const f = ExpenseFilter(query: 'lunch');
        expect(f.matches(makeExpense(title: 'Lunch at the cafe')), isTrue);
        expect(f.matches(makeExpense(title: 'Dinner')), isFalse);
      });

      test('matches note', () {
        const f = ExpenseFilter(query: 'card');
        expect(f.matches(makeExpense(note: 'paid with card')), isTrue);
        expect(f.matches(makeExpense(note: 'cash')), isFalse);
      });
    });

    group('category', () {
      test('filters to selected categories', () {
        const f = ExpenseFilter(categories: {ExpenseCategory.food});
        expect(f.matches(makeExpense(category: ExpenseCategory.food)), isTrue);
        expect(f.matches(makeExpense(category: ExpenseCategory.transport)), isFalse);
      });

      test('empty selection matches all', () {
        const f = ExpenseFilter();
        expect(f.matches(makeExpense(category: ExpenseCategory.health)), isTrue);
      });
    });

    group('date range', () {
      test('thisMonth matches only current month', () {
        final now = DateTime.now();
        const f = ExpenseFilter(rangeType: DateRangeFilter.thisMonth);

        expect(
          f.matches(makeExpense(date: DateTime(now.year, now.month, 15))),
          isTrue,
        );
        expect(
          f.matches(makeExpense(date: DateTime(now.year, now.month - 1, 15))),
          isFalse,
        );
      });

      test('lastMonth matches only previous month', () {
        final now = DateTime.now();
        const f = ExpenseFilter(rangeType: DateRangeFilter.lastMonth);
        final lastMonth = DateTime(now.year, now.month - 1, 15);

        expect(f.matches(makeExpense(date: lastMonth)), isTrue);
        expect(
          f.matches(makeExpense(date: DateTime(now.year, now.month, 15))),
          isFalse,
        );
      });

      test('custom range is inclusive on both ends', () {
        final f = ExpenseFilter(
          rangeType: DateRangeFilter.custom,
          customRange: DateTimeRange(
            start: DateTime(2026, 8, 1),
            end: DateTime(2026, 8, 31),
          ),
        );

        expect(f.matches(makeExpense(date: DateTime(2026, 8, 1))), isTrue);
        expect(f.matches(makeExpense(date: DateTime(2026, 8, 31, 23, 59))), isTrue);
        expect(f.matches(makeExpense(date: DateTime(2026, 7, 31))), isFalse);
        expect(f.matches(makeExpense(date: DateTime(2026, 9, 1))), isFalse);
      });
    });

    test('copyWith preserves unset fields', () {
      const f = ExpenseFilter(query: 'abc');
      final updated = f.copyWith(rangeType: DateRangeFilter.thisMonth);

      expect(updated.query, 'abc');
      expect(updated.rangeType, DateRangeFilter.thisMonth);
      expect(updated.categories, isEmpty);
    });
  });
}

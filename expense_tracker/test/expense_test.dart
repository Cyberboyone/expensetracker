import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/expense.dart';

void main() {
  group('Expense model', () {
    test('serializes to JSON and back', () {
      final e = Expense(
        id: 'abc-123',
        title: 'Lunch',
        amount: 2500.5,
        category: ExpenseCategory.food,
        date: DateTime(2026, 8, 24, 12, 30),
        note: 'chicken rice',
      );

      final restored = Expense.fromJson(e.toJson());

      expect(restored.id, 'abc-123');
      expect(restored.title, 'Lunch');
      expect(restored.amount, 2500.5);
      expect(restored.category, ExpenseCategory.food);
      expect(restored.date, DateTime(2026, 8, 24, 12, 30));
      expect(restored.note, 'chicken rice');
    });

    test('unknown category in JSON falls back to other', () {
      final json = <String, dynamic>{
        'id': 'x1',
        'title': 'Something',
        'amount': 100.0,
        'category': 'space_travel',
        'date': '2026-08-24T00:00:00.000',
      };

      final e = Expense.fromJson(json);

      expect(e.category, ExpenseCategory.other);
    });

    test('missing note serializes as null', () {
      final e = Expense(
        id: 'n1',
        title: 'Bus',
        amount: 500,
        category: ExpenseCategory.transport,
        date: DateTime(2026, 8, 24),
      );

      expect(e.toJson()['note'], isNull);
      expect(Expense.fromJson(e.toJson()).note, isNull);
    });

    test('copyWith overrides only the provided fields', () {
      final e = Expense(
        id: 'fixed-id',
        title: 'Old title',
        amount: 10,
        category: ExpenseCategory.food,
        date: DateTime(2026, 1, 1),
        note: 'note',
      );

      final updated = e.copyWith(title: 'New title', amount: 20);

      expect(updated.id, 'fixed-id');
      expect(updated.title, 'New title');
      expect(updated.amount, 20);
      expect(updated.category, ExpenseCategory.food);
      expect(updated.date, DateTime(2026, 1, 1));
      expect(updated.note, 'note');
    });

    test('encodeList / decodeList round trip', () {
      final list = [
        Expense(
          id: 'a',
          title: 'First',
          amount: 100,
          category: ExpenseCategory.food,
          date: DateTime(2026, 8, 1),
        ),
        Expense(
          id: 'b',
          title: 'Second',
          amount: 200,
          category: ExpenseCategory.bills,
          date: DateTime(2026, 8, 2),
        ),
      ];

      final restored = Expense.decodeList(Expense.encodeList(list));

      expect(restored, hasLength(2));
      expect(restored[0].title, 'First');
      expect(restored[1].category, ExpenseCategory.bills);
      expect(restored[1].amount, 200);
    });
  });
}

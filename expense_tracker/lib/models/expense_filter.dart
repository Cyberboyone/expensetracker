import 'package:flutter/material.dart';
import 'expense.dart';

enum DateRangeFilter { all, thisMonth, lastMonth, custom }

class ExpenseFilter {
  final String query;
  final Set<ExpenseCategory> categories;
  final DateRangeFilter rangeType;
  final DateTimeRange? customRange;

  const ExpenseFilter({
    this.query = '',
    this.categories = const {},
    this.rangeType = DateRangeFilter.all,
    this.customRange,
  });

  bool get isActive =>
      query.trim().isNotEmpty || categories.isNotEmpty || rangeType != DateRangeFilter.all;

  ExpenseFilter copyWith({
    String? query,
    Set<ExpenseCategory>? categories,
    DateRangeFilter? rangeType,
    DateTimeRange? customRange,
  }) {
    return ExpenseFilter(
      query: query ?? this.query,
      categories: categories ?? this.categories,
      rangeType: rangeType ?? this.rangeType,
      customRange: customRange ?? this.customRange,
    );
  }

  bool matches(Expense e) {
    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      final inTitle = e.title.toLowerCase().contains(q);
      final inNote = (e.note ?? '').toLowerCase().contains(q);
      if (!inTitle && !inNote) return false;
    }

    if (categories.isNotEmpty && !categories.contains(e.category)) return false;

    switch (rangeType) {
      case DateRangeFilter.all:
        break;
      case DateRangeFilter.thisMonth:
        final now = DateTime.now();
        if (!(e.date.year == now.year && e.date.month == now.month)) return false;
        break;
      case DateRangeFilter.lastMonth:
        final now = DateTime.now();
        final lastMonth = DateTime(now.year, now.month - 1);
        if (!(e.date.year == lastMonth.year && e.date.month == lastMonth.month)) return false;
        break;
      case DateRangeFilter.custom:
        if (customRange == null) break;
        final d = DateTime(e.date.year, e.date.month, e.date.day);
        final start = customRange!.start;
        final end = customRange!.end;
        final startD = DateTime(start.year, start.month, start.day);
        final endD = DateTime(end.year, end.month, end.day);
        if (d.isBefore(startD) || d.isAfter(endD)) return false;
        break;
    }
    return true;
  }
}

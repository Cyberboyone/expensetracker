import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/expense_filter.dart';
import 'category_style.dart';

/// Shows a modal bottom sheet for editing an [ExpenseFilter].
/// Returns the updated filter, or null if the user dismissed without saving.
Future<ExpenseFilter?> showFilterSheet(BuildContext context, ExpenseFilter current) {
  return showModalBottomSheet<ExpenseFilter>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _FilterSheetContent(initial: current),
  );
}

class _FilterSheetContent extends StatefulWidget {
  final ExpenseFilter initial;

  const _FilterSheetContent({required this.initial});

  @override
  State<_FilterSheetContent> createState() => _FilterSheetContentState();
}

class _FilterSheetContentState extends State<_FilterSheetContent> {
  late Set<ExpenseCategory> _categories;
  late DateRangeFilter _rangeType;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _categories = {...widget.initial.categories};
    _rangeType = widget.initial.rangeType;
    _customRange = widget.initial.customRange;
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: _customRange,
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _rangeType = DateRangeFilter.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  setState(() {
                    _categories = {};
                    _rangeType = DateRangeFilter.all;
                    _customRange = null;
                  });
                },
                child: const Text('Clear all'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ExpenseCategory.values.map((c) {
              final selected = _categories.contains(c);
              return FilterChip(
                label: Text(c.label),
                avatar: Icon(CategoryStyle.icon(c), size: 16, color: CategoryStyle.color(c)),
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _categories.add(c);
                    } else {
                      _categories.remove(c);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('Date range', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All time'),
                selected: _rangeType == DateRangeFilter.all,
                onSelected: (_) => setState(() {
                  _rangeType = DateRangeFilter.all;
                  _customRange = null;
                }),
              ),
              ChoiceChip(
                label: const Text('This month'),
                selected: _rangeType == DateRangeFilter.thisMonth,
                onSelected: (_) => setState(() {
                  _rangeType = DateRangeFilter.thisMonth;
                  _customRange = null;
                }),
              ),
              ChoiceChip(
                label: const Text('Last month'),
                selected: _rangeType == DateRangeFilter.lastMonth,
                onSelected: (_) => setState(() {
                  _rangeType = DateRangeFilter.lastMonth;
                  _customRange = null;
                }),
              ),
              ChoiceChip(
                label: Text(_customRange == null
                    ? 'Custom…'
                    : '${_fmt(_customRange!.start)} – ${_fmt(_customRange!.end)}'),
                selected: _rangeType == DateRangeFilter.custom,
                onSelected: (_) => _pickCustomRange(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(
                ExpenseFilter(
                  query: widget.initial.query,
                  categories: _categories,
                  rangeType: _rangeType,
                  customRange: _customRange,
                ),
              );
            },
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) => '${d.month}/${d.day}';
}

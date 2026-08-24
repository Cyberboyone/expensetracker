import 'dart:convert';
import 'expense.dart';

class Budget {
  final double? overallMonthly;
  final Map<ExpenseCategory, double> categoryMonthly;

  Budget({this.overallMonthly, Map<ExpenseCategory, double>? categoryMonthly})
      : categoryMonthly = categoryMonthly ?? {};

  bool get isEmpty => overallMonthly == null && categoryMonthly.isEmpty;

  Budget copyWith({
    double? overallMonthly,
    bool clearOverall = false,
    Map<ExpenseCategory, double>? categoryMonthly,
  }) {
    return Budget(
      overallMonthly: clearOverall ? null : (overallMonthly ?? this.overallMonthly),
      categoryMonthly: categoryMonthly ?? this.categoryMonthly,
    );
  }

  Map<String, dynamic> toJson() => {
        'overallMonthly': overallMonthly,
        'categoryMonthly': categoryMonthly.map((k, v) => MapEntry(k.name, v)),
      };

  factory Budget.fromJson(Map<String, dynamic> json) {
    final catMap = <ExpenseCategory, double>{};
    final raw = json['categoryMonthly'] as Map<String, dynamic>?;
    if (raw != null) {
      raw.forEach((key, value) {
        final cat = ExpenseCategory.values.firstWhere(
          (e) => e.name == key,
          orElse: () => ExpenseCategory.other,
        );
        catMap[cat] = (value as num).toDouble();
      });
    }
    return Budget(
      overallMonthly: (json['overallMonthly'] as num?)?.toDouble(),
      categoryMonthly: catMap,
    );
  }

  static String encode(Budget b) => jsonEncode(b.toJson());
  static Budget decode(String s) => Budget.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

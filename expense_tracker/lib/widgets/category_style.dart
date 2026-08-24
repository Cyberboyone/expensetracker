import 'package:flutter/material.dart';
import '../models/expense.dart';

class CategoryStyle {
  static IconData icon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.transport:
        return Icons.directions_car;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag;
      case ExpenseCategory.bills:
        return Icons.receipt_long;
      case ExpenseCategory.health:
        return Icons.favorite;
      case ExpenseCategory.entertainment:
        return Icons.movie;
      case ExpenseCategory.education:
        return Icons.school;
      case ExpenseCategory.other:
        return Icons.category;
    }
  }

  static Color color(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return const Color(0xFFFF7043);
      case ExpenseCategory.transport:
        return const Color(0xFF42A5F5);
      case ExpenseCategory.shopping:
        return const Color(0xFFAB47BC);
      case ExpenseCategory.bills:
        return const Color(0xFF66BB6A);
      case ExpenseCategory.health:
        return const Color(0xFFEF5350);
      case ExpenseCategory.entertainment:
        return const Color(0xFFFFCA28);
      case ExpenseCategory.education:
        return const Color(0xFF26C6DA);
      case ExpenseCategory.other:
        return const Color(0xFF8D6E63);
    }
  }
}

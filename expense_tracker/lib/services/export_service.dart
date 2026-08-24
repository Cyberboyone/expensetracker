import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/budget.dart';
import '../models/expense.dart';

class ExportService {
  /// Exports the given expenses as a CSV file and opens the OS share sheet
  /// so the user can save it to Files, Drive, email it, etc.
  Future<void> exportCsv(List<Expense> expenses) async {
    final rows = <List<dynamic>>[
      ['Title', 'Amount', 'Category', 'Date', 'Note'],
      for (final e in expenses)
        [
          e.title,
          e.amount,
          e.category.label,
          e.date.toIso8601String().split('T').first,
          e.note ?? '',
        ],
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/expenses_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'Expense export');
  }

  /// Exports all local data (expenses + budget) as a single JSON backup file.
  Future<void> exportBackup(List<Expense> expenses, Budget budget) async {
    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'budget': budget.toJson(),
    };
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/expense_tracker_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonStr);
    await Share.shareXFiles([XFile(file.path)], text: 'Expense Tracker backup');
  }

  /// Lets the user pick a previously exported backup .json file.
  /// Returns the parsed (expenses, budget) pair, or null if cancelled.
  Future<(List<Expense>, Budget)?> pickAndReadBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return null;

    final file = File(result.files.single.path!);
    final content = await file.readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;

    final expensesJson = (data['expenses'] as List<dynamic>? ?? []);
    final expenses = expensesJson
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList();
    final budget = data['budget'] != null
        ? Budget.fromJson(data['budget'] as Map<String, dynamic>)
        : Budget();

    return (expenses, budget);
  }
}

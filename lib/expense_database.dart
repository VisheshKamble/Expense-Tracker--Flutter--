// 📁 File: expense_database.dart
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:expense_tracker/expense.dart';
import 'package:path_provider/path_provider.dart';

class ExpenseDatabase extends ChangeNotifier {
  static late Isar isar;
  List<Expense> _allExpenses = [];

  /* SETUP */

  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open([ExpenseSchema], directory: dir.path);
  }

  /* GETTERS */

  List<Expense> get allExpenses => _allExpenses;

  List<Expense> get currentMonthExpenses {
    final now = DateTime.now();
    final filtered = _allExpenses.where((expense) =>
    expense.date.month == now.month &&
        expense.date.year == now.year).toList();
    filtered.sort((a, b) => b.date.compareTo(a.date)); // latest first
    return filtered;
  }

  /* CRUD OPERATIONS */

  Future<void> createNewExpense(Expense newExpense) async {
    await isar.writeTxn(() => isar.expenses.put(newExpense));
    await readExpenses();
  }

  Future<void> readExpenses() async {
    List<Expense> fetchedExpenses = await isar.expenses.where().findAll();
    _allExpenses.clear();
    _allExpenses.addAll(fetchedExpenses);
    notifyListeners();
  }

  Future<void> updateExpense(int id, Expense updatedExpense) async {
    await isar.writeTxn(() => isar.expenses.put(updatedExpense));
    await readExpenses();
  }

  Future<void> deleteExpense(int id) async {
    await isar.writeTxn(() => isar.expenses.delete(id));
    await readExpenses();
  }

  /* HELPERS */

  Future<Map<String, double>> calculateMonthlyTotals() async {
    await readExpenses();
    Map<String, double> monthlyTotals = {};

    for (var expense in _allExpenses) {
      String yearMonth = '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}';
      if (!monthlyTotals.containsKey(yearMonth)) {
        monthlyTotals[yearMonth] = 0;
      }
      monthlyTotals[yearMonth] = monthlyTotals[yearMonth]! + expense.amount;
    }
    return monthlyTotals;
  }

  Future<double> calculateCurrentMonthTotal() async {
    await readExpenses();
    int currentMonth = DateTime.now().month;
    int currentYear = DateTime.now().year;

    List<Expense> currentMonthExpenses = _allExpenses.where((expense) {
      return expense.date.month == currentMonth &&
          expense.date.year == currentYear;
    }).toList();

    double total = currentMonthExpenses.fold(0, (sum, expense) => sum + expense.amount);
    return total;
  }

  Future<Map<String, double>> calculateCurrentMonthCategoryTotals() async {
    await readExpenses();
    int currentMonth = DateTime.now().month;
    int currentYear = DateTime.now().year;

    Map<String, double> categoryTotals = {};
    for (var expense in _allExpenses) {
      if (expense.date.month == currentMonth && expense.date.year == currentYear) {
        categoryTotals.update(expense.category, (value) => value + expense.amount, ifAbsent: () => expense.amount);
      }
    }
    return categoryTotals;
  }

  int getStartMonth() {
    if (_allExpenses.isEmpty) return DateTime.now().month;
    _allExpenses.sort((a, b) => a.date.compareTo(b.date));
    return _allExpenses.first.date.month;
  }

  int getStartYear() {
    if (_allExpenses.isEmpty) return DateTime.now().year;
    _allExpenses.sort((a, b) => a.date.compareTo(b.date));
    return _allExpenses.first.date.year;
  }
}

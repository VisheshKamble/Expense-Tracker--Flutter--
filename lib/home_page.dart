import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/bar_graph.dart';
import 'package:expense_tracker/expense.dart';
import 'package:expense_tracker/expense_database.dart';
import 'package:expense_tracker/helper_functions.dart';
import 'package:expense_tracker/my_list_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  String selectedCategory = 'Food';
  final List<String> categories = [
    'Food',
    'Travel',
    'Entertainment',
    'Bills',
    'Shopping',
    'Other'
  ];

  Future<Map<String, double>>? _monthlyTotalsFuture;
  Future<Map<String, double>>? _categoryTotalsFuture;

  @override
  void initState() {
    super.initState();
    Provider.of<ExpenseDatabase>(context, listen: false).readExpenses();
    refreshData();
  }

  void refreshData() {
    final db = Provider.of<ExpenseDatabase>(context, listen: false);
    _monthlyTotalsFuture = db.calculateMonthlyTotals();
    _categoryTotalsFuture = db.calculateCurrentMonthCategoryTotals();
    setState(() {});
  }

  Future<double> get _calculateCurrentMonthTotal async {
    return await Provider.of<ExpenseDatabase>(context, listen: false)
        .calculateCurrentMonthTotal();
  }

  /// ---- Expense Dialog ----
  void _openExpenseDialog({Expense? existingExpense}) {
    final isEdit = existingExpense != null;
    if (isEdit) {
      nameController.text = existingExpense!.name;
      amountController.text = existingExpense.amount.toString();
      selectedCategory = existingExpense.category;
    } else {
      nameController.clear();
      amountController.clear();
      selectedCategory = 'Food';
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isEdit ? 'Edit Expense' : 'Add Expense',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: "Expense Name",
                  prefixIcon: const Icon(Icons.note_alt_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Amount",
                  prefixIcon: const Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) {
                  setState(() => selectedCategory = val ?? 'Food');
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: const Text("Cancel",
                        style: TextStyle(color: Colors.deepPurple)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save, size: 18),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final amount = convertStringToDouble(amountController.text);
                      if (name.isEmpty || amount <= 0) return;

                      final newExpense = Expense(
                        name: name,
                        amount: amount,
                        date: DateTime.now(),
                        category: selectedCategory,
                      );

                      if (isEdit) {
                        await context
                            .read<ExpenseDatabase>()
                            .updateExpense(existingExpense!.id, newExpense);
                      } else {
                        await context
                            .read<ExpenseDatabase>()
                            .createNewExpense(newExpense);
                      }
                      refreshData();
                      Navigator.pop(context);
                    },
                    label: const Text("Save",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Expense?"),
        content: const Text(
            "Are you sure you want to delete this expense? This action cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await context.read<ExpenseDatabase>().deleteExpense(expense.id);
              refreshData();
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// ---- BUILD UI ----
  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseDatabase>(
      builder: (context, db, _) {
        final startMonth = db.getStartMonth();
        final startYear = db.getStartYear();
        final now = DateTime.now();
        final monthCount =
            calculateMonthCount(startYear, startMonth, now.year, now.month);
        final currentExpenses = db.currentMonthExpenses;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            title: FutureBuilder<double>(
              future: _calculateCurrentMonthTotal,
              builder: (context, snapshot) {
                final total = snapshot.data ?? 0.0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("This Month",
                        style: Theme.of(context).textTheme.bodySmall),
                    Text('₹${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20)),
                  ],
                );
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.pie_chart_outline_rounded),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          height: 320,
                          width: 320,
                          child: FutureBuilder<Map<String, double>>(
                            future: _categoryTotalsFuture,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              final data = snapshot.data!;
                              if (data.isEmpty) {
                                return const Center(
                                    child: Text('No expenses yet.'));
                              }
                              return PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 40,
                                  sections: data.entries.map((entry) {
                                    final color = _getCategoryColor(entry.key);
                                    return PieChartSectionData(
                                      value: entry.value,
                                      title:
                                          '${entry.key}\n₹${entry.value.toStringAsFixed(0)}',
                                      color: color,
                                      radius: 100,
                                      titleStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.deepPurple,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onPressed: () => _openExpenseDialog(),
            child: const Icon(Icons.add, size: 28),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  /// ---- Monthly Summary ----
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SizedBox(
                        height: 220,
                        child: FutureBuilder<Map<String, double>>(
                          future: _monthlyTotalsFuture,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            final monthlySummary = List.generate(
                              monthCount,
                              (i) {
                                final year =
                                    startYear + (startMonth + i - 1) ~/ 12;
                                final month =
                                    (startMonth + i - 1) % 12 + 1;
                                final key =
                                    '$year-${month.toString().padLeft(2, '0')}';
                                return snapshot.data?[key] ?? 0.0;
                              },
                            );
                            return MyBarGraph(
                              monthlySummary: monthlySummary,
                              startMonth: startMonth,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// ---- Expense List ----
                  Expanded(
                    child: currentExpenses.isEmpty
                        ? const Center(
                            child: Text("No expenses yet.",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey)))
                        : ListView.separated(
                            itemCount: currentExpenses.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final expense = currentExpenses[index];
                              return MyListTile(
                                title: expense.name,
                                trailing: formatAmount(expense.amount),
                                category: expense.category,
                                onEditPressed: (_) => _openExpenseDialog(
                                    existingExpense: expense),
                                onDeletePressed: (_) => _confirmDelete(expense),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// ---- CATEGORY COLORS ----
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.green.shade400;
      case 'Travel':
        return Colors.blue.shade400;
      case 'Entertainment':
        return Colors.orange.shade400;
      case 'Bills':
        return Colors.red.shade400;
      case 'Shopping':
        return Colors.purple.shade400;
      default:
        return Colors.grey.shade400;
    }
  }
}

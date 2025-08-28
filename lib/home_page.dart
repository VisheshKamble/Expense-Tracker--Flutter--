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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEdit ? 'Edit Expense' : 'New Expense',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: "Name",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                hintText: "Amount",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
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
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel",
                  style: TextStyle(color: Colors.deepPurple))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
                await context.read<ExpenseDatabase>().createNewExpense(newExpense);
              }
              refreshData();
              Navigator.pop(context);
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Expense?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel",
                  style: TextStyle(color: Colors.deepPurple))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
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
          appBar: AppBar(
            title: FutureBuilder<double>(
              future: _calculateCurrentMonthTotal,
              builder: (context, snapshot) {
                final total = snapshot.data ?? 0.0;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('₹${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20)),
                    Text(getCurrentMonthName(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                );
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.pie_chart),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: const Text('Category Breakdown'),
                      content: SizedBox(
                        height: 300,
                        width: 300,
                        child: FutureBuilder<Map<String, double>>(
                          future: _categoryTotalsFuture,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            final data = snapshot.data!;
                            if (data.isEmpty) {
                              return const Text('No expenses yet.');
                            }
                            return PieChart(
                              PieChartData(
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
                  );
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _openExpenseDialog(),
            child: const Icon(Icons.add),
          ),
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 250,
                  child: FutureBuilder<Map<String, double>>(
                    future: _monthlyTotalsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final monthlySummary = List.generate(
                        monthCount,
                            (i) {
                          final year = startYear + (startMonth + i - 1) ~/ 12;
                          final month = (startMonth + i - 1) % 12 + 1;
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
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: currentExpenses.length,
                    itemBuilder: (context, index) {
                      final expense = currentExpenses[index];
                      return MyListTile(
                        title: expense.name,
                        trailing: formatAmount(expense.amount),
                        category: expense.category,
                        onEditPressed: (_) =>
                            _openExpenseDialog(existingExpense: expense),
                        onDeletePressed: (_) => _confirmDelete(expense),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.green;
      case 'Travel':
        return Colors.blue;
      case 'Entertainment':
        return Colors.orange;
      case 'Bills':
        return Colors.red;
      case 'Shopping':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

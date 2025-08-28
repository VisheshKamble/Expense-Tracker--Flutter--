
import 'package:isar/isar.dart';

part 'expense.g.dart';

@collection
class Expense {
  Id id = Isar.autoIncrement; // auto-increment id

  late String name;
  late double amount;
  late DateTime date;
  late String category;

  Expense({
    required this.name,
    required this.amount,
    required this.date,
    required this.category,
  });
}

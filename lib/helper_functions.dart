// 📁 File: helper_functions.dart
import 'package:intl/intl.dart';

double convertStringToDouble(String string) {
  double? amount = double.tryParse(string);
  return amount ?? 0;
}

String formatAmount(double amount) {
  final format = NumberFormat.currency(
    locale: "en_IN",
    symbol: "₹",
    decimalDigits: 2,
  );
  return format.format(amount);
}

int calculateMonthCount(int startYear, int startMonth, int currentYear, int currentMonth) {
  int monthCount = (currentYear - startYear) * 12 + currentMonth - startMonth + 1;
  return monthCount;
}

String getCurrentMonthName() {
  DateTime now = DateTime.now();
  List<String> months = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec"
  ];
  return months[now.month - 1];
}
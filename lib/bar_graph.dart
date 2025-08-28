
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'individual_bar.dart';

class MyBarGraph extends StatefulWidget {
  final List<double> monthlySummary;
  final int startMonth;

  const MyBarGraph({
    super.key,
    required this.monthlySummary,
    required this.startMonth,
  });

  @override
  State<MyBarGraph> createState() => _MyBarGraphState();
}

class _MyBarGraphState extends State<MyBarGraph> {
  List<IndividualBar> barData = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToEnd());
  }

  void scrollToEnd() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }

  void initializeBarData() {
    barData = List.generate(
      widget.monthlySummary.length,
          (index) => IndividualBar(x: index, y: widget.monthlySummary[index]),
    );
  }

  double calculateMaxY() {
    final values = widget.monthlySummary;
    if (values.isEmpty) return 1000;
    final max = values.reduce((a, b) => a > b ? a : b);
    return max < 1000 ? 1000 : max * 1.2; // Increased padding for aesthetics
  }

  @override
  Widget build(BuildContext context) {
    initializeBarData();
    const double barWidth = 28; // Wider bars for better touch
    const double barSpacing = 20;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: barData.length * (barWidth + barSpacing),
        child: BarChart(
          BarChartData(
            minY: 0,
            maxY: calculateMaxY(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: calculateMaxY() / 5,
              getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            alignment: BarChartAlignment.start,
            groupsSpace: barSpacing,
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) =>
                      getBottomTitles(value, meta, widget.startMonth),
                ),
              ),
            ),
            barGroups: barData.map((bar) {
              return BarChartGroupData(
                x: bar.x,
                barRods: [
                  BarChartRodData(
                    toY: bar.y,
                    width: barWidth,
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.shade300,
                        Colors.deepPurple.shade700,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: calculateMaxY(),
                      color: Colors.grey.shade100.withOpacity(0.5),
                    ),
                  )
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

Widget getBottomTitles(double value, TitleMeta meta, int startMonth) {
  const textStyle = TextStyle(
    color: Colors.deepPurple,
    fontWeight: FontWeight.bold,
    fontSize: 14,
  );

  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final int index = (startMonth + value.toInt() - 1) % 12;
  final text = (index >= 0 && index < months.length) ? months[index] : '';

  return SideTitleWidget(
    axisSide: meta.axisSide,
    space: 8,
    child: Text(text, style: textStyle),
  );
}
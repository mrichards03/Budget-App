import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CategoryPieChart extends StatefulWidget {
  final Map<int, double> breakdown;
  final List<Color> colors;
  final double totalSpending;

  const CategoryPieChart({
    super.key,
    required this.breakdown,
    required this.colors,
    required this.totalSpending,
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _hoveredIndex = -1;

  @override
  Widget build(BuildContext context) {
    final spendingData =
        widget.breakdown.entries.where((e) => e.value > 0).toList();

    if (spendingData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No spending data for this period'),
        ),
      );
    }

    return SizedBox(
      height: 400,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              sections: spendingData.asMap().entries.map((entry) {
                final index = entry.key;
                final amount = entry.value.value;
                final percentage = (amount / widget.totalSpending) * 100;
                final isHovered = _hoveredIndex == index;

                return PieChartSectionData(
                  value: amount,
                  title: '${percentage.toStringAsFixed(0)}%',
                  radius: isHovered ? 160 : 150,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  color: widget.colors[index],
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 80,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (event is FlTapUpEvent || event is FlLongPressEnd) {
                      if (pieTouchResponse
                              ?.touchedSection?.touchedSectionIndex !=
                          null) {
                        final index = pieTouchResponse!
                            .touchedSection!.touchedSectionIndex;
                        _hoveredIndex = _hoveredIndex == index ? -1 : index;
                      }
                    }
                  });
                },
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Spending',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                Text(
                  '\$${widget.totalSpending.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

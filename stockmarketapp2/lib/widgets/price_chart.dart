// lib/widgets/price_chart.dart

/// DEPRECATED: This standalone `PriceChart` widget is no longer used in the app,
/// as charts are now drawn inline within each screen for tighter layout control.
/// You can safely remove this file once all legacy references are cleaned up.
///
/// ────────────────────────────────────────────────────────────────────────────────
/// A simple wrapper around `fl_chart`’s `LineChart` to render a filled area
/// price history chart.
///
/// Parameters:
///   • `spots`             — List of `FlSpot` data points (x=index, y=price).
///   • `isNegativeTrend`   — If true, uses red tones; otherwise green tones.
///   • `timeframe`         — Interval label (e.g. '1D', '1W', etc.), currently unused.
///
/// Appearance:
///   • No grid or axis labels (clean, minimal look).
///   • Smooth (curved) line of width 2.
///   • No individual point markers.
///   • Area under the line filled at 30% opacity of the trend color.
///
/// Legacy usage example:
/// ```dart
/// PriceChart(
///   spots: mySpots,
///   isNegativeTrend: mySpots.last.y < mySpots.first.y,
///   timeframe: '1M',
/// )
/// ```
///

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PriceChart extends StatelessWidget {
  final List<FlSpot> spots;       // The data points
  final bool isNegativeTrend;     // true=red, false=green
  final String timeframe;         // e.g. '1D', '1W', etc.

  const PriceChart({
    Key? key,
    required this.spots,
    required this.isNegativeTrend,
    this.timeframe = '1D',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = isNegativeTrend ? Colors.redAccent : Colors.greenAccent;
    return LineChart(
      LineChartData(
        backgroundColor: Colors.transparent,
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}

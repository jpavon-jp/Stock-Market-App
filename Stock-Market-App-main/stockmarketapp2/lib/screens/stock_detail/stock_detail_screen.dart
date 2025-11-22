/*
  NO LONGER USING IT – Legacy StockDetailScreen

  • StockDetailScreen (StatefulWidget):
      – Receives `symbol` to display details for a given stock.
      – Manages a local `_selectedTimeframe` state ('1D', '1W', '1M', '1Y').

  • Dummy data (_dummySpots1D, _dummySpots1W):
      – Two hard-coded lists of FlSpot for 1-day and 1-week charts.
      – Demonstrates how to generate sample FlSpot sequences.

  • build(context):
      – Chooses the data set (`spots`) based on `_selectedTimeframe`.
      – Computes `isNegativeTrend` by comparing first and last spot values.
      – Computes `priceChangePercent` for display.

      – AppBar:
          • Transparent background so parent gradient can show through.
          • Title displays `widget.symbol` in high-contrast text.

      – Body:
          • Gradient background from AppColors.backgroundStart to backgroundEnd.
          • Current price & percent change:
              – Large headline showing last spot’s value formatted as Euros.
              – Colored pill (red/green background) showing price change percent.

          • Timeframe selector:
              – Row of buttons '1D', '1W', '1M', '1Y'.
              – Highlights the selected timeframe.
              – onTap sets `_selectedTimeframe` and rebuilds chart.

          • Chart area:
              – Expanded PriceChart widget showing `spots`.
              – Passes `isNegativeTrend` and timeframe label.

          • Action buttons:
              – “Sell” (red accent) and “Buy” (green accent) at the bottom.
              – Full-width, rounded corners, placeholder onPressed for actual flows.

  • PriceChart widget:
      – Expects `spots`, `isNegativeTrend`, and `timeframe` parameters.
      – Renders a line chart inside a styled container.

  • AppTheme usage:
      – Uses AppColors.textHigh for primary text.
      – Uses AppColors.primaryAccent for selected highlights.
      – Leverages a parent gradient for the screen background.

  Note: This screen has been superseded and is no longer used in the current navigation flow.
*/


import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/price_chart.dart';

class StockDetailScreen extends StatefulWidget {
  final String symbol;

  const StockDetailScreen({
    Key? key,
    required this.symbol,
  }) : super(key: key);

  @override
  _StockDetailScreenState createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  String _selectedTimeframe = '1D';

  // Dummy data for 1D and 1W charts (FlSpot requires import from fl_chart)
  final List<FlSpot> _dummySpots1D = List.generate(
    8,
        (i) => FlSpot(
      i.toDouble(),
      100 + (i % 2 == 0 ? i * 1.5 : -i * 1.2),
    ),
  );
  final List<FlSpot> _dummySpots1W = List.generate(
    8,
        (i) => FlSpot(
      i.toDouble(),
      110 + (i % 2 == 0 ? i * 0.5 : -i * 0.4),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Choose which data set to display based on the selected timeframe
    final spots =
    _selectedTimeframe == '1D' ? _dummySpots1D : _dummySpots1W;

    // Determine trend by comparing first and last spot's y-values
    final isNegativeTrend = spots.last.y < spots.first.y;
    final priceChangePercent =
    ((spots.last.y - spots.first.y) / spots.first.y * 100)
        .toStringAsFixed(2);

    return Scaffold(
      // Transparent background so a parent gradient (if any) shows through
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.symbol,
          style: textTheme.headlineMedium?.copyWith(
            color: AppColors.textHigh,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundStart,
              AppColors.backgroundEnd,
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Current price and percentage change
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '€${spots.last.y.toStringAsFixed(2)}',
                    style: textTheme.headlineLarge?.copyWith(
                      color: AppColors.textHigh,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isNegativeTrend
                          ? Colors.redAccent.withOpacity(0.2)
                          : Colors.greenAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${isNegativeTrend ? '' : '+'}$priceChangePercent%',
                      style: textTheme.titleMedium?.copyWith(
                        color: isNegativeTrend
                            ? Colors.redAccent
                            : Colors.greenAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Timeframe selector (1D, 1W, 1M, 1Y)
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: ['1D', '1W', '1M', '1Y'].map((tf) {
                  final bool isSelected = _selectedTimeframe == tf;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTimeframe = tf;
                        });
                      },
                      child: Container(
                        margin:
                        const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryAccent
                              .withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tf,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(
                            color: isSelected
                                ? AppColors.primaryAccent
                                : AppColors.textMedium,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Chart area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 16.0, horizontal: 16.0),
                child: PriceChart(
                  spots: spots,
                  isNegativeTrend: isNegativeTrend,
                  timeframe: _selectedTimeframe,
                ),
              ),
            ),

            // Buy / Sell buttons
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor:
                        AppColors.backgroundStart,
                        minimumSize:
                        const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        // TODO: Implement Sell flow
                      },
                      child: Text(
                        'Sell',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        Colors.greenAccent,
                        foregroundColor:
                        AppColors.backgroundStart,
                        minimumSize:
                        const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        // TODO: Implement Buy flow
                      },
                      child: Text(
                        'Buy',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

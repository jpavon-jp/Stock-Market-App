// lib/widgets/stock_card.dart

/// DEPRECATED: This widget is no longer used in the current app.
///
/// A standalone card that once displayed a single stock’s summary:
///   • `symbol`        – the stock ticker, e.g. "AAPL"
///   • `companyName`   – the full company name, e.g. "Apple Inc."
///   • `price`         – current price (displayed in Euros)
///   • `changePercent` – percent change since previous close (e.g. +1.23)
///   • `onTap`         – optional callback when the card is tapped
///
/// Layout & styling:
///   • A rounded container with light border and padding.
///   • Left: ticker & name in a column.
///   • Center: price right-aligned.
///   • Right: percent change right-aligned, colored green for positive and red for negative,
///     plus a small trending arrow icon.
///   • Uses the active theme’s `cardColor` and text styles.
///
/// Usage example:
/// ```dart
/// StockCard(
///   symbol:        'TSLA',
///   companyName:   'Tesla, Inc.',
///   price:         680.32,
///   changePercent: -2.14,
///   onTap:         () => Navigator.push(...),
/// );


import 'package:flutter/material.dart';

class StockCard extends StatelessWidget {
  final String symbol;        // e.g. "AAPL"
  final String companyName;   // e.g. "Apple Inc."
  final double price;         // e.g. 172.98
  final double changePercent; // e.g. +1.23
  final VoidCallback? onTap;  // optional tap callback

  const StockCard({
    Key? key,
    required this.symbol,
    required this.companyName,
    required this.price,
    required this.changePercent,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool isPositive = changePercent >= 0;
    final Color changeColor = isPositive ? Colors.greenAccent : Colors.redAccent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade800, width: 0.5),
        ),
        child: Row(
          children: [
            // Left column: symbol & company name
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    symbol,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    companyName,
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            // Middle: current price
            Expanded(
              flex: 2,
              child: Text(
                '€${price.toStringAsFixed(2)}',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.right,
              ),
            ),

            // Right: percentage change
            Expanded(
              flex: 2,
              child: Text(
                '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                style: textTheme.bodyLarge?.copyWith(color: changeColor),
                textAlign: TextAlign.right,
              ),
            ),

            // Tiny trending arrow
            const SizedBox(width: 8),
            Icon(
              isPositive ? Icons.trending_up : Icons.trending_down,
              color: changeColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

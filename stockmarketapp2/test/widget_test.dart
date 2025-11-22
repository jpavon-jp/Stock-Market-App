// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Use the package name exactly as in pubspec.yaml:
import 'package:stock_market_app/main.dart';

void main() {
  testWidgets('App launches and shows splash text', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const StockMarketApp());

    // Verify that the splash screen’s headline appears.
    // Adjust this to match the exact text on your SplashScreen.
    expect(find.text("This isn’t just an app."), findsOneWidget);
  });
}

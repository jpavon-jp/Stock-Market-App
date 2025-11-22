/*
  AlphaStockService – Alpha Vantage Integration

  • StockData model:
    – Holds:
      • symbol: the stock ticker (e.g. “AAPL”)
      • price: latest quoted price as a double
      • changePercent: percent change since previous close

  • AlphaStockService class:
    – Constructor:
      • Accepts an optional Dio instance or creates one with:
        – Base URL: https://www.alphavantage.co
        – 5-second connect & receive timeouts
    – _apiKey:
      • Your Alpha Vantage API key (free tier)

    – fetchQuote(String symbol):
      • Calls the GLOBAL_QUOTE endpoint:
          GET /query
          function=GLOBAL_QUOTE
          symbol=<symbol>
          apikey=<_apiKey>
      • Expects JSON under ‘Global Quote’
      • Parses:
          – ‘05. price’ → price (double)
          – ‘10. change percent’ → changePercent (strip ‘%’ and parse)
      • Returns a StockData instance
      • Throws if no data is returned

    – fetchQuotes(List<String> symbols):
      • Iterates through tickers one by one
      • Calls fetchQuote for each, catching & skipping any errors
      • Awaits a 15-second delay after each call to respect the free tier rate limit (5 calls/minute)
      • Returns a list of successfully fetched StockData

    – fetchFxRate(String toCurrency):
      • Calls the CURRENCY_EXCHANGE_RATE endpoint:
          GET /query
          function=CURRENCY_EXCHANGE_RATE
          from_currency=USD
          to_currency=<toCurrency>
          apikey=<_apiKey>
      • Parses ‘Realtime Currency Exchange Rate’ → ‘5. Exchange Rate’
      • Returns the parsed double or 1.0 on failure
*/

import 'package:dio/dio.dart';

/// Simple quote + % change model
class StockData {
  final String symbol;
  final double price;
  final double changePercent;
  StockData({
    required this.symbol,
    required this.price,
    required this.changePercent,
  });
}

/// Talks to Alpha Vantage for quotes and FX
class AlphaStockService {
  AlphaStockService({Dio? dio})
      : _dio = dio ??
      Dio(BaseOptions(
        baseUrl: 'https://www.alphavantage.co',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));

  final Dio _dio;
  static const _apiKey = 'P52PDABUOHISN8D2';

  /// Fetches a single quote via GLOBAL_QUOTE
  Future<StockData> fetchQuote(String symbol) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/query',
      queryParameters: {
        'function': 'GLOBAL_QUOTE',
        'symbol': symbol,
        'apikey': _apiKey,
      },
    );
    final data = resp.data?['Global Quote'] as Map<String, dynamic>?;

    if (data == null || data.isEmpty) {
      throw Exception('No quote for $symbol');
    }

    final price = double.tryParse(data['05. price'] ?? '') ?? 0.0;
    final changePct =
        double.tryParse((data['10. change percent'] ?? '').replaceAll('%', '')) ??
            0.0;

    return StockData(
      symbol: symbol,
      price: price,
      changePercent: changePct,
    );
  }

  /// Fetches multiple quotes, skipping any that fail
  Future<List<StockData>> fetchQuotes(List<String> symbols) async {
    final List<StockData> results = [];
    for (var symbol in symbols) {
      try {
        final q = await fetchQuote(symbol);
        results.add(q);
      } catch (_) {
        // skip symbol on error
      }
      // honor the 5-calls/min free tier
      await Future.delayed(const Duration(seconds: 15));
    }
    return results;
  }

  /// Fetches FX rate USD→[toCurrency]
  Future<double> fetchFxRate(String toCurrency) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/query',
      queryParameters: {
        'function': 'CURRENCY_EXCHANGE_RATE',
        'from_currency': 'USD',
        'to_currency': toCurrency,
        'apikey': _apiKey,
      },
    );
    final rateStr = resp.data?['Realtime Currency Exchange Rate']
    ?['5. Exchange Rate']
    as String?;
    return double.tryParse(rateStr ?? '') ?? 1.0;
  }
}

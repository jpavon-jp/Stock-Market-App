// lib/services/marketstack_service.dart

/// A simple wrapper around the Marketstack REST API (https://marketstack.com/)
/// to fetch end-of-day (EOD) stock prices. Uses Dio for HTTP requests and
/// handles JSON parsing, returning Dart-native types.
///
/// Configuration:
///   • Base URL: `https://api.marketstack.com/v1`
///   • Timeout: 5000 ms for connect & receive
///   • API Key: replace `_apiKey` with your own Marketstack access key.
///
/// Methods:
///   • `fetchLatestPrice(symbol)`
///        – Fetches the most recent closing price for [symbol].
///        – Sends GET `/tickers/{symbol}/eod?access_key={key}&limit=1`
///        – Returns 0.0 if no data or on parse failure.
///
///   • `fetchHistory(symbol, limit: n)`
///        – Fetches the last [limit] closing prices (oldest→newest) for [symbol].
///        – Sends GET `/tickers/{symbol}/eod?access_key={key}&limit={limit}`
///        – Maps each entry’s `close` field to double, reverses order so index=0
///          is the oldest date, and returns the list.
///
/// Example usage:
/// ```dart
/// final svc = MarketStackService();
/// final latest = await svc.fetchLatestPrice('AAPL');
/// final history = await svc.fetchHistory('AAPL', limit: 30);
/// ```
///
/// Note:
///   • Marketstack free tier allows only daily EOD data; interval parameter is ignored.
///   • Ensure your API key has sufficient quota for your use case.

import 'package:dio/dio.dart';

class MarketStackService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.marketstack.com/v1',
    connectTimeout: const Duration(milliseconds: 5000),
    receiveTimeout: const Duration(milliseconds: 5000),
  ));

  // TODO: replace with your actual Marketstack key
  static const String _apiKey = 'b4f0609e9d3f8968a052228b43d548b6';

  /// Fetches the latest closing price for [symbol], e.g. "BTCEUR"
  Future<double> fetchLatestPrice(String symbol) async {
    final res = await _dio.get(
      '/tickers/$symbol/eod',
      queryParameters: {
        'access_key': _apiKey,
        'limit': 1,
      },
    );

    final data = res.data['data'] as List<dynamic>;
    if (data.isEmpty) return 0.0;

    // Cast from num→double
    final raw = data.first['close'] as num?;
    return raw != null ? raw.toDouble() : 0.0;
  }

  /// Fetches the last [limit] closing prices (oldest→newest) for [symbol].
  /// [interval] is ignored because Marketstack only offers daily EOD.
  Future<List<double>> fetchHistory(String symbol, {int limit = 30}) async {
    final res = await _dio.get(
      '/tickers/$symbol/eod',
      queryParameters: {
        'access_key': _apiKey,
        'limit': limit,
      },
    );

    final data = res.data['data'] as List<dynamic>;
    // Map each entry’s close to double, then reverse so index=0 is oldest
    return data
        .map((e) {
      final raw = e['close'] as num?;
      return raw != null ? raw.toDouble() : 0.0;
    })
        .toList()
        .reversed
        .toList();
  }
}

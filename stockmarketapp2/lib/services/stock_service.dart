// lib/services/stock_service.dart

/// A unified client for fetching real-time and historical stock data,
/// combining Finnhub (quotes & key metrics) with Marketstack (time-series).
///
/// ────────────────────────────────────────────────────────────────────────────────
/// 1. HTTP clients & base URLs
///
///    • `_fh` (Dio) — Finnhub.io API v1
///      - baseUrl: https://finnhub.io/api/v1
///      - used for real-time quotes and key statistics
///
///    • `_ms` (Dio) — Marketstack.com API v1
///      - baseUrl: https://api.marketstack.com/v1
///      - used for end-of-day historical time series
///
/// ────────────────────────────────────────────────────────────────────────────────
/// 2. API key rotation
///
///    • Finnhub tokens (`_fhTokens`) and Marketstack keys (`_msKeys`) are stored
///      in two separate lists to spread requests across multiple free-tier keys.
///    • `_currentFhToken` / `_currentMsKey` getters return the active key.
///    • `_rotateFh()` / `_rotateMs()` advance the index on error, retrying until
///      all keys are exhausted (then throw).
///
/// ────────────────────────────────────────────────────────────────────────────────
/// 3. Public methods
///
///    • `Future<StockData> fetchQuote(String symbol)`
///        – Calls Finnhub `/quote?symbol={symbol}&token={token}`.
///        – Parses `c` (current price) and `pc` (previous close).
///        – Calculates percent change = (c – pc) / pc * 100.
///        – Retries with rotated tokens on failure.
///
///    • `Future<StockStats> fetchKeyStats(String symbol)`
///        – Calls Finnhub `/stock/metric?symbol={symbol}&metric=all&token={token}`.
///        – Extracts metrics: marketCap, peNormalizedAnnual, dividendYield, beta,
///          52-week low/high, 10-day avg volume.
///        – Rounds values to 2 decimal places.
///        – Retries with rotated tokens on failure.
///
///    • `Future<List<TimeSeriesPoint>> fetchTimeSeries({required String symbol, required String interval})`
///        – Computes `from` / `to` dates based on `interval` (1D, 1W, 1M, 3M, 1Y),
///          adjusting for weekends (no data on Sat/Sun).
///        – Formats dates as `yyyy-MM-dd` with `intl`.
///        – Calls Marketstack `/eod?access_key={key}&symbols={symbol}&date_from={from}&date_to={to}&limit=100&sort=ASC`.
///        – Parses each entry into `TimeSeriesPoint(time: DateTime.parse(date), price: close)`.
///        – Retries with rotated keys on failure.
///
/// ────────────────────────────────────────────────────────────────────────────────
/// Usage example:
/// ```dart
/// final svc = StockService();
///
/// // Real-time quote
/// final quote = await svc.fetchQuote('AAPL');
///
/// // Key metrics
/// final stats = await svc.fetchKeyStats('AAPL');
///
/// // 1-month historical series
/// final history = await svc.fetchTimeSeries(symbol: 'AAPL', interval: '1M');
/// ```
///

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../models/stock_stats.dart';
import '../models/time_series_point.dart' as tsp;
import '../models/company_profile.dart';

/// Holds the latest quote data.
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

class StockService {
  // ─── Dio clients ────────────────────────────────────────
  static const _fhBase = 'https://finnhub.io/api/v1';
  final Dio _fh = Dio(BaseOptions(
    baseUrl: _fhBase,
    connectTimeout: const Duration(milliseconds: 5000),
    receiveTimeout: const Duration(milliseconds: 5000),
  ));

  static const _msBase = 'https://api.marketstack.com/v1';
  final Dio _ms = Dio(BaseOptions(
    baseUrl: _msBase,
    connectTimeout: const Duration(milliseconds: 5000),
    receiveTimeout: const Duration(milliseconds: 5000),
  ));

  // ─── Your API keys (first entry is the one you had) ────
  final List<String> _fhTokens = [
    'd11b449r01qse6lgdd4gd11b449r01qse6lgdd50'
  ];
  int _fhIndex = 0;
  String get _currentFhToken => _fhTokens[_fhIndex];
  void _rotateFh() => _fhIndex = (_fhIndex + 1) % _fhTokens.length;

  final List<String> _msKeys = [
    'c5900ed2e3a29d022d20f8f74f701e17'
  ];
  int _msIndex = 0;
  String get _currentMsKey => _msKeys[_msIndex];
  void _rotateMs() => _msIndex = (_msIndex + 1) % _msKeys.length;

  /// ─── Fetch latest quote (rotating Finnhub tokens) ───────
  Future<StockData> fetchQuote(String symbol) async {
    for (var i = 0; i < _fhTokens.length; i++) {
      final token = _currentFhToken;
      try {
        final resp = await _fh.get<Map<String, dynamic>>(
          '/quote',
          queryParameters: {
            'symbol': symbol,
            'token': token,
          },
        );
        final d = resp.data;
        if (resp.statusCode != 200 || d == null || d['c'] == null) {
          throw Exception('bad response');
        }
        final close = (d['c'] as num).toDouble();
        final prev  = (d['pc'] as num?)?.toDouble() ?? close;
        final pct   = prev != 0 ? (close - prev) / prev * 100 : 0.0;
        return StockData(symbol: symbol, price: close, changePercent: pct);
      } catch (_) {
        _rotateFh();
      }
    }
    throw Exception('All Finnhub tokens failed for quote($symbol)');
  }

  /// ─── Fetch key stats (rotating Finnhub tokens) ─────────
  Future<StockStats> fetchKeyStats(String symbol) async {
    for (var i = 0; i < _fhTokens.length; i++) {
      final token = _currentFhToken;
      try {
        final resp = await _fh.get<Map<String, dynamic>>(
          '/stock/metric',
          queryParameters: {
            'symbol': symbol,
            'metric': 'all',
            'token': token,
          },
        );
        final data = resp.data;
        if (resp.statusCode != 200 || data == null) {
          throw Exception('bad response');
        }
        final m = data['metric'] as Map<String, dynamic>? ?? {};

        double toD(String k) => (m[k] as num?)?.toDouble() ?? 0.0;
        double r2(double v)  => double.parse(v.toStringAsFixed(2));

        return StockStats(
          marketCap:     r2(toD('marketCapitalization')),
          peRatio:       r2(toD('peNormalizedAnnual')),
          dividendYield: r2(toD('dividendYield') * 100),
          week52Low:     r2(toD('52WeekLow')),
          week52High:    r2(toD('52WeekHigh')),
          avgVolume:     r2(toD('10DayAverageTradingVolume')),
          beta:          r2(toD('beta')),
        );
      } catch (_) {
        _rotateFh();
      }
    }
    throw Exception('All Finnhub tokens failed for keyStats($symbol)');
  }

  /// ─── Fetch historical series (rotating Marketstack keys) ─
  Future<List<tsp.TimeSeriesPoint>> fetchTimeSeries({
    required String symbol,
    required String interval,
  }) async {
    // compute end (avoid weekends)
    DateTime end = DateTime.now();
    if (end.weekday == DateTime.saturday) end = end.subtract(const Duration(days: 1));
    if (end.weekday == DateTime.sunday)   end = end.subtract(const Duration(days: 2));

    // compute from
    late DateTime from;
    switch (interval) {
      case '1D':
        from = end.subtract(const Duration(days: 2));
        while (from.weekday == DateTime.saturday || from.weekday == DateTime.sunday) {
          from = from.subtract(const Duration(days: 1));
        }
        break;
      case '1W':
        from = end.subtract(const Duration(days: 7)); break;
      case '1M':
        from = end.subtract(const Duration(days: 30)); break;
      case '3M':
        from = end.subtract(const Duration(days: 90)); break;
      case '1Y':
        from = end.subtract(const Duration(days: 365)); break;
      default:
        from = end.subtract(const Duration(days: 2));
    }

    final df       = DateFormat('yyyy-MM-dd');
    final dateFrom = df.format(from);
    final dateTo   = df.format(end);

    for (var i = 0; i < _msKeys.length; i++) {
      final key = _currentMsKey;
      try {
        final resp = await _ms.get<Map<String, dynamic>>(
          '/eod',
          queryParameters: {
            'access_key': key,
            'symbols':    symbol,
            'date_from':  dateFrom,
            'date_to':    dateTo,
            'limit':      100,
            'sort':       'ASC',
          },
        );
        final data = resp.data;
        if (resp.statusCode != 200 || data == null) {
          throw Exception('bad response');
        }
        final raw = data['data'] as List<dynamic>? ?? [];
        return raw.map((e) {
          final m = e as Map<String, dynamic>;
          return tsp.TimeSeriesPoint(
            time:  DateTime.parse(m['date'] as String),
            price: (m['close'] as num).toDouble(),
          );
        }).toList();
      } catch (_) {
        _rotateMs();
      }
    }

    throw Exception('All Marketstack keys failed for timeSeries($symbol)');
  }
}

// lib/services/news_service.dart
///
/// A simple wrapper around the Finnhub “company-news” and “news” endpoints
/// to fetch either general market news or company-specific articles.
///
/// Configuration:
///   • Uses Dio for HTTP requests (default BaseOptions).
///   • API key: `_apiKey` (replace with your own Finnhub token).
///
/// Usage:
///   • To fetch general headlines:
///       final news = await NewsService().fetchLatestNews('general');
///   • To fetch company-specific articles (e.g. AAPL):
///       final news = await NewsService().fetchLatestNews('AAPL');
///
/// Methods:
///   • `fetchLatestNews(symbolOrCategory)`
///       – If `symbolOrCategory.toLowerCase() == 'general'`, sends GET to
///         `/v1/news?category=general&token={_apiKey}`
///       – Otherwise, sends GET to
///         `/v1/company-news?symbol={symbolOrCategory}&from=2025-01-01&to=2025-06-01&token={_apiKey}`
///       – Parses the JSON array into a `List<NewsItem>`, mapping:
///           • `headline` ← raw['headline']
///           • `source`   ← raw['source']
///           • `urlToImage`← raw['image']
///           • `url`      ← raw['url']
///       – Returns an empty list if the response is null or cannot be parsed.
///
/// Example:
/// ```dart
/// final svc = NewsService();
/// final general = await svc.fetchLatestNews('general');
/// final appleNews = await svc.fetchLatestNews('AAPL');
/// ```
import 'package:dio/dio.dart';
import '../models/news_item.dart';

class NewsService {
  final Dio _dio = Dio();
  static const _apiKey = 'd11b449r01qse6lgdd4gd11b449r01qse6lgdd50';

  /// If [symbolOrCategory] == 'general', hits /v1/news?category=general,
  /// otherwise hits /v1/company-news?symbol=...&from=...&to=...
  Future<List<NewsItem>> fetchLatestNews(String symbolOrCategory) async {
    final bool isGeneral = symbolOrCategory.toLowerCase() == 'general';
    final String url = isGeneral
        ? 'https://finnhub.io/api/v1/news'
        : 'https://finnhub.io/api/v1/company-news';

    final Map<String, dynamic> params = isGeneral
        ? {
      'category': 'general',
      'token': _apiKey,
    }
        : {
      'symbol': symbolOrCategory,
      'from':   '2025-01-01',
      'to':     '2025-06-01',
      'token':  _apiKey,
    };

    final resp = await _dio.get<List<dynamic>>(url, queryParameters: params);
    final List<dynamic> data = resp.data ?? [];

    return data.cast<Map<String, dynamic>>().map((raw) {
      return NewsItem(
        headline:   raw['headline'] ?? '',
        source:     raw['source']   ?? '',
        urlToImage: raw['image']    ?? '',
        url:        raw['url']      ?? '',
      );
    }).toList();
  }
}

/*
  models/time_series_point.dart – Single price‐point for charting

  • time  : A Dart DateTime representing when the price was recorded.
  • price : The closing price at that point in time.

  This immutable model is used to encapsulate each data point fetched
  from your historical price APIs. You map a list of TimeSeriesPoint
  directly into charting library spots (e.g., FlSpot) for rendering.
*/
class TimeSeriesPoint {
  final DateTime time;
  final double price;

  TimeSeriesPoint({required this.time, required this.price});
}

/*
  models/news_item.dart – Basic news article representation

  • headline   : The title of the article, shown prominently in the UI.
  • source     : The name of the publisher or news source.
  • urlToImage : URL for the article’s thumbnail image, used for card backgrounds.

  This simple data class holds exactly the fields needed to display
  a news feed. All fields are required and non-nullable, ensuring
  the UI always has valid strings to work with.
*/
class NewsItem {
  final String headline;
  final String source;
  final String urlToImage;

  NewsItem({
    required this.headline,
    required this.source,
    required this.urlToImage,
  });
}
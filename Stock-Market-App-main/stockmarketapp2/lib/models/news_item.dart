/*
  models/news_item.dart – News article data model

  • headline   : The article’s title (from JSON `title`), displayed in the UI.
  • source     : The publisher name (from JSON `source.name`), shown as a subtitle or badge.
  • urlToImage : URL of the article’s thumbnail image (from JSON `urlToImage`), used for card backgrounds.
  • url        : The full article URL (from JSON `url`), loaded in a WebView when the user taps the card.

  The `fromJson` factory safely reads each field from the incoming JSON map,
  using the null-aware cast (`as String?`) and defaulting to an empty string
  if the key is missing or null—so all non-nullable fields are always populated.
*/

class NewsItem {
  final String headline;
  final String source;
  final String urlToImage;
  final String url;

  NewsItem({
    required this.headline,
    required this.source,
    required this.urlToImage,
    required this.url,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      headline:   json['title']        as String?        ?? '',
      source:     (json['source']?['name'] as String?)  ?? '',
      urlToImage: json['urlToImage']   as String?        ?? '',
      url:        json['url']          as String?        ?? '',
    );
  }
}

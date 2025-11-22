/*
  models/stock_time_series.dart – JSON‐serializable historical price data

  • TimePrice:
    – timestamp   : Raw UNIX timestamp (in seconds) from the API
    – price       : The price at that timestamp
    – factory     : `TimePrice.fromJson` parses a JSON map into a TimePrice
    – toJson      : Serializes this instance back to JSON
    – getter time : Converts `timestamp` → Dart `DateTime` (multiplies by 1000)

  • StockTimeSeries:
    – points      : A list of `TimePrice` objects, representing the full history
    – latestPrice : The most recent closing price from the API payload
    – factory     : `StockTimeSeries.fromJson` parses the JSON into this model
    – toJson      : Serializes this model back to JSON

  Using `json_serializable` (see `part 'stock_time_series.g.dart'`), this file
  lets you round-trip between Dart objects and JSON, making it trivial to fetch
  and decode historical price series for charting or caching.
*/

import 'package:json_annotation/json_annotation.dart';
part 'stock_time_series.g.dart';

/// A single timestamp & price point.
@JsonSerializable()
class TimePrice {
  /// UNIX timestamp in **seconds** (or milliseconds; see your API).
  final int timestamp;

  /// Price at that time.
  final double price;

  TimePrice({
    required this.timestamp,
    required this.price,
  });

  /// Converts JSON map to a TimePrice.
  factory TimePrice.fromJson(Map<String, dynamic> json) =>
      _$TimePriceFromJson(json);

  /// Converts this to JSON map.
  Map<String, dynamic> toJson() => _$TimePriceToJson(this);

  /// Convenient DateTime getter (adjust if your API uses seconds vs ms).
  DateTime get time =>
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
}

/// The full time-series payload for a ticker.
@JsonSerializable()
class StockTimeSeries {
  /// List of timestamped price points.
  final List<TimePrice> points;

  /// The most recent closing price.
  final double latestPrice;

  StockTimeSeries({
    required this.points,
    required this.latestPrice,
  });

  /// Parses from JSON.
  factory StockTimeSeries.fromJson(Map<String, dynamic> json) =>
      _$StockTimeSeriesFromJson(json);

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => _$StockTimeSeriesToJson(this);
}
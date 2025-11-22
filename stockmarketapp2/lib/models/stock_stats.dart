/*
  models/stock_stats.dart – Fundamental Stock Metrics Model

  • marketCap      : The company’s market capitalization (in billions/trillions),
                     typically used to gauge size and valuation.
  • peRatio        : Price–earnings ratio, indicating how much investors
                     are willing to pay per euro of earnings.
  • beta           : A measure of volatility compared to the overall market
                     (β > 1 is more volatile, β < 1 is less volatile).
  • dividendYield  : Annual dividend expressed as a percentage of share price,
                     used to assess income-generating potential.
  • avgVolume      : The average daily trading volume (number of shares),
                     indicating liquidity.
  • week52Low      : The lowest closing price over the last 52 weeks.
  • week52High     : The highest closing price over the last 52 weeks.

  This immutable class holds all the key statistics we fetch from Finnhub’s
  `/stock/metric` endpoint. By making every field `final` and `required`,
  we ensure our UI code always has valid, non-null metrics to display.
*/
class StockStats {
  final double marketCap;
  final double peRatio;
  final double beta;
  final double dividendYield;
  final double avgVolume;
  final double week52Low;
  final double week52High;

  StockStats({
    required this.marketCap,
    required this.peRatio,
    required this.beta,
    required this.dividendYield,
    required this.avgVolume,
    required this.week52Low,
    required this.week52High,
  });
}

/*
  models/time_series_point.dart – Single Point in a Price History Series

  • time  : A `DateTime` representing when the price was recorded.
  • price : The closing price at that specific time.

  Used for building historical charts (1D, 1W, 1M, etc.). Each API call
  returns a list of `TimeSeriesPoint`, which we map directly into
  `FlSpot` instances for Fl_Chart rendering. Keeping it simple and
  immutable makes time-series manipulation straightforward.
*/
class TimeSeriesPoint {
  final DateTime time;
  final double price;

  TimeSeriesPoint({required this.time, required this.price});
}


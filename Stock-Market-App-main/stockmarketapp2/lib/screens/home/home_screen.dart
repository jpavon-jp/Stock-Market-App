/*
  home_screen.dart – Main Dashboard: Greeting, News, Popular Stocks & Chat FAB

  • StatefulWidget (_HomeScreenState):
      – initState():
          • Instantiates StockService.
          • Calls _loadData() to fetch top news and popular stock quotes.
          • Sets up a periodic Timer (every 60 minutes) to refresh stock prices via _fetchQuotes().

      – dispose():
          • Cancels the refresh timer to avoid leaks.

      – _greeting():
          • Returns localized “Good Morning” / “Good Afternoon” / “Good Evening” based on current hour.

      – _loadData():
          • Kicks off both newsFuture and stocksFuture.

      – _fetchTopNews(count):
          • Dio GET to Finnhub’s “general” news endpoint.
          • Maps the first [count] items into a simple (_NewsItem) model.

      – _fetchQuotes(symbols):
          • Parallel-fetches each symbol’s quote via StockService.fetchQuote.
          • Wraps results (or errors) into a local _StockData model for display.

  • build():
      – Scaffold with transparent background & gradient container.

      – Stack:
          1) SingleChildScrollView (bottom padding for nav):
              • Top bar: app logo + greeting text.
              • “Market News” section:
                  – FutureBuilder over _newsFuture.
                  – Shows loading spinner, error/no-news text, or two _NewsCard widgets.
              • “Popular Stocks” section:
                  – FutureBuilder over _stocksFuture.
                  – Shows loading, error/no-stocks text, or a column of _StockCard widgets.
                  – At bottom: tappable “See other stocks” row with arrow icon → AllStocksScreen.
          2) Positioned pill-shaped bottom nav:
              • 5 icons: Home, News, Portfolio, Bitcoin, Profile.
              • Each _NavIcon handles isActive state & pushReplacement to its screen.
          3) Positioned FloatingActionButton (Chat):
              • Tapping opens ChatAssistantScreen in new route.

  • Helper Widgets & Models:
      – _NewsItem: holds headline & source.
      – _NewsCard: styled card displaying headline, source, and “See other news” row with arrow → NewsScreen.
      – _StockData: holds symbol, company, price, changePercent.
      – _StockCard: rounded container with logo image, symbol, price, percent-change; taps to StockDetailScreen.
      – _NavIcon: animated icon container highlighting active tab.

  Usage:
    // From anywhere:
    Navigator.pushNamed(context, HomeScreen.routeName);
*/


import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'news_screen.dart';
import 'all_stocks_screen.dart';
import 'portfolio_screen.dart';
import 'bitcoin_screen.dart';
import 'profile_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'stock_detail_screen.dart';
import '../chat/chat_assistant_screen.dart';
import '../../services/stock_service.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  int _currentIndex = 0;
  // API keys
  final String _finnhubKey = 'd11b449r01qse6lgdd4gd11b449r01qse6lgdd50';
  //final String _avKey      = '3f956e9d47732d3b5995906cd7822712';

  // Futures for asynchronous data
  late Future<List<_NewsItem>> _newsFuture;
  late Future<List<_StockData>> _stocksFuture;
  Timer? _refreshTimer;
  //late Future<List<MarketQuote>> _quotesFuture;
  //final _marketService = MarketStackService();
  late final StockService _stockService;

  // Popular symbols for home
  final List<String> _popularSyms = ['AAPL', 'TSLA', 'AMZN', 'MSFT', 'GOOGL'];
  final Map<String, String> _companyNames = {
    'AAPL': 'Apple Inc.',
    'TSLA': 'Tesla Inc.',
    'AMZN': 'Amazon Inc.',
    'MSFT': 'Microsoft Corp.',
    'GOOGL': 'Alphabet Inc.',
  };


  @override
  void initState() {
    super.initState();
    //_loadData();
    _stockService = StockService();
    _loadData();
    // Refresh stock prices every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(minutes: 60), (_) {
      setState(() {
        _stocksFuture = _fetchQuotes(_popularSyms);
      });
    });
  }

  void _loadData() {
    _newsFuture = _fetchTopNews(2);
    _stocksFuture = _fetchQuotes(_popularSyms);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'goodMorning'.tr();
    if (hour < 18) return 'goodAfternoon'.tr();
    return 'Good Evening';
  }

  Future<List<_NewsItem>> _fetchTopNews(int count) async {
    final resp = await Dio().get(
      'https://finnhub.io/api/v1/news',
      queryParameters: {'category': 'general', 'token': _finnhubKey},
    );
    final List<dynamic> data = resp.data as List<dynamic>;
    return data.take(count).map((json) {
      return _NewsItem(
        headline: json['headline'] as String? ?? '',
        source: json['source'] as String? ?? '',
      );
    }).toList();
  }

   Future<List<_StockData>> _fetchQuotes(List<String> symbols) async {
       // Fetch each symbol in parallel via your Finnhub-backed StockService
       final list = await Future.wait(symbols.map((sym) async {
         try {
           final quote = await _stockService.fetchQuote(sym);
           return _StockData(
             symbol: sym,
             company: _companyNames[sym] ?? '',
             price: quote.price,
             changePercent: quote.changePercent,
           );
         } catch (_) {
           return _StockData(
             symbol: sym,
             company: _companyNames[sym] ?? '',
             price: 0.0,
             changePercent: 0.0,
           );
         }
       }));
       return list;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Scrollable content
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar: logo + greeting
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/tradion_dark.png',
                            width: 100,
                            height: 100,
                          ),
                          const Spacer(),
                          Text(
                            _greeting(),
                            style: tt.bodyLarge!
                                .copyWith(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                    ),

                    // Market News section title
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'marketNews'.tr(),
                        style: tt.headlineSmall!
                            .copyWith(color: Colors.white, fontSize: 20),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Two news cards
                    FutureBuilder<List<_NewsItem>>(
                      future: _newsFuture,
                      builder: (context, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          );
                        }
                        if (snap.hasError || snap.data!.isEmpty) {
                          return Center(
                            child: Text(
                              'noNews'.tr(),
                              style: tt.bodyMedium!
                                  .copyWith(color: AppColors.textMedium),
                            ),
                          );
                        }
                        return Column(
                          children: snap.data!
                              .map((item) => _NewsCard(item: item))
                              .toList(),
                        );
                      },
                    ),

                    // Popular Stocks section
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'popularStocks'.tr(),
                        style: tt.headlineSmall!
                            .copyWith(color: Colors.white, fontSize: 20),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Stock list + "See other stocks"
                    FutureBuilder<List<_StockData>>(
                      future: _stocksFuture,
                      builder: (context, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return const Center(
                            child: CircularProgressIndicator(color: AppColors.Borders1),
                          );
                        }
                        if (snap.hasError || snap.data!.isEmpty) {
                          return Center(
                            child: Text(
                              'noStocks'.tr(),
                              style: tt.bodyMedium!
                                  .copyWith(color: AppColors.textMedium),
                            ),
                          );
                        }
                        final stocks = snap.data!;
                        return Column(
                          children: [
                            for (final s in stocks) _StockCard(item: s),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AllStocksScreen(),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'seeOtherStocks'.tr(),
                                        style: tt.bodyMedium!.copyWith(color: Colors.white),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                        color: Colors.white70,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Floating pill-shaped bottom nav bar
              Positioned(
                left: 24,
                right: 24,
                bottom: 16,
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: AppColors.textMedium.withAlpha(100),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.40),
                        blurRadius: 8,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _NavIcon(
                        Icons.bar_chart,
                            () {
                          setState(() {
                            _currentIndex = 0;
                          });
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => NewsScreen()),
                          );
                        }, // match the index you just set
                        isActive: _currentIndex == 0,
                      ),
                      _NavIcon(
                        Icons.calendar_today,
                            () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NewsScreen(),
                          ),
                        ),
                      ),
                      _NavIcon(
                        Icons.account_balance_wallet_outlined,
                            () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PortfolioScreen(),
                          ),
                        ),
                      ),
                      _NavIcon(
                        Icons.currency_bitcoin,
                            () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>  BitcoinScreen(),
                          ),
                        ),
                      ),
                      _NavIcon(
                        Icons.person,
                            () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>  ProfileScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 24,
                bottom: 100, // adjust as needed to sit above the nav
                child: FloatingActionButton(
                  backgroundColor: AppColors.primaryAccent,
                  child: const Icon(Icons.circle_outlined, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatAssistantScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// News item model
class _NewsItem {
  final String headline, source;
  _NewsItem({required this.headline, required this.source});
}

/// Single news card widget
class _NewsCard extends StatelessWidget {
  final _NewsItem item;
  const _NewsCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.Borders2, width: 1), boxShadow: [
          BoxShadow(
            color: AppColors.Borders2.withValues(alpha: 0.50),
            blurRadius: 9,
            offset: const Offset(1, 1),
          ),
        ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'marketNews'.tr(),
              style: tt.bodyMedium!
                  .copyWith(color: AppColors.textMedium, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              item.headline,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style:
              tt.bodyLarge!.copyWith(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              item.source,
              style: tt.bodySmall!
                  .copyWith(color: AppColors.textMedium, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewsScreen()),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'seeOtherNews'.tr(),
                      style: tt.bodyMedium!.copyWith(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stock data model
class _StockData {
  final String symbol, company;
  final double price, changePercent;
  _StockData({
    required this.symbol,
    required this.company,
    required this.price,
    required this.changePercent,
  });
}

/// Single stock card widget (now navigates on tap)
class _StockCard extends StatelessWidget {
  final _StockData item;

  const _StockCard(
      {Key? key, required this.item})
      : super(key: key);

  static const _logoToken = 'pk_T8uVtgcmQsClYpLzZg2t1g';

  @override
  Widget build(BuildContext context) {
    final tt = Theme
        .of(context)
        .textTheme;
    final isUp = item.changePercent >=
        0;

    // Build the Logo.dev URL using the stock ticker
    final logoUrl =
        'https://img.logo.dev/ticker/${item
        .symbol}'
        '?token=$_logoToken&retina=true';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                StockDetailScreen(
                    symbol: item
                        .symbol,
                    companyName: item.company),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets
            .symmetric(horizontal: 24,
            vertical: 6),
        child: Container(
          padding: const EdgeInsets
              .symmetric(vertical: 12,
              horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors
                .cardBackground,
            borderRadius: BorderRadius
                .circular(20),
            border: Border.all(
                color: AppColors
                    .Borders2,
                width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors
                    .Borders2
                    .withOpacity(0.50),
                blurRadius: 9,
                offset: const Offset(
                    1, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // Logo.dev network image with placeholder and error fallback
              ClipRRect(
                borderRadius: BorderRadius
                    .circular(8),
                child: FadeInImage
                    .assetNetwork(
                  placeholder: 'assets/icons/placeholder.png',
                  image: logoUrl,
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                  imageErrorBuilder: (_,
                      __, ___) {
                    // fallback to generic icon if logo fails
                    return const Icon(
                      Icons.show_chart,
                      color: Colors
                          .white,
                      size: 28,
                    );
                  },
                ),
              ),

              const SizedBox(width: 12),

              // Symbol text
              Expanded(
                child: Text(
                  item.symbol,
                  style: tt.bodyLarge!
                      .copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),

              // Price & % change
              Column(
                crossAxisAlignment: CrossAxisAlignment
                    .end,
                children: [
                  Text(
                    '€${item.price
                        .toStringAsFixed(
                        2)}',
                    style: tt.bodyLarge!
                        .copyWith(
                        color: Colors
                            .white,
                        fontSize: 16),
                  ),
                  const SizedBox(
                      height: 4),
                  Text(
                    '${isUp
                        ? '+'
                        : ''}${item
                        .changePercent
                        .toStringAsFixed(
                        2)}%',
                    style: tt
                        .bodyMedium!
                        .copyWith(
                      color: isUp
                          ? AppColors
                          .upwardMovement
                          : AppColors
                          .downwardMovement,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single bottom‐nav icon that highlights when `isActive == true`
class _NavIcon extends StatelessWidget {
  final IconData iconData;
  final VoidCallback onTap;
  final bool isActive;

  /// You can pass [isActive] as a named parameter; defaults to false.
  const _NavIcon(
      this.iconData,
      this.onTap, {
        Key? key,
        this.isActive = false,
      }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      splashColor: const Color(0xFF180E8D),
      radius: 28,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: isActive
            ? BoxDecoration(
          color: AppColors.Borders1.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.Borders1.withValues(alpha: 0.20),
              blurRadius: 10,
              spreadRadius: 3,
            ),
          ],
        )
            : null,
        child: Icon(
          iconData,
          size: 28,
          color: isActive ? AppColors.primaryAccent : AppColors.textMedium,
        ),
      ),
    );
  }
}

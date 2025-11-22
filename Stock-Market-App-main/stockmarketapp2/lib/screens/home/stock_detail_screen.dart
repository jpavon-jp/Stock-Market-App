/*
  stock_detail_screen.dart – Detailed view for a single stock symbol

  • ConsumerStatefulWidget (_StockDetailScreenState):
      – Receives `symbol` and `companyName` via constructor.
      – Uses Riverpod for dependency management (favorites).

  • initState():
      – Instantiates StockService and NewsService.
      – Kicks off three futures:
          1. _timeSeriesFuture → fetchTimeSeries(symbol, interval)
          2. _keyStatsFuture   → fetchKeyStats(symbol)
          3. _newsFuture       → fetchLatestNews(symbol)
      – Default interval = '1D'; NumberFormat for market cap (_capFmt).

  • build():
      – Full‐screen gradient background with SafeArea + Stack.
      – Scrollable Column:
          ─ Top bar Row:
             • Back icon → HomeScreen
             • Symbol text (large)
             • Favorite icon toggle via FavoritesService.toggle().
          ─ Time series section:
             • FutureBuilder for _timeSeriesFuture:
               – Loading spinner, error/empty message, or chart.
             • Timeframe selector (1D,1W,1M,3M,1Y):
               – Highlights selected, onTap sets `_selectedRange` and reloads future.
             • PriceChart widget inside styled container.
          ─ Key stats section:
             • FutureBuilder for _keyStatsFuture:
               – Loading spinner, error text, or two‐column stats grid:
                 Market Cap, P/E, Div Yield, 52W Range, Avg Volume, Beta.
          ─ News preview:
             • Title (‘news’.tr()), then FutureBuilder for _newsFuture:
               – Loading spinner, error text, or up to 3 NewsItems via _NewsCard.
               – If more than 3 items, “See other news” row navigates to NewsScreen.
      – Padding leaves room at bottom for nav bar.

  • Floating Bottom Navigation bar:
      – Positioned pill‐shaped container with 5 _NavIcon:
        Home, News, Portfolio, Bitcoin, Profile.
      – _NavIcon animates when active and pushesReplacement to each screen.

  • Helper widgets:
      – _NavIcon: iconData, isActive, onTap; AnimatedContainer “glow” when isActive.
      – _NewsCard: simple card showing headline and source.

  Key techniques:
    • FutureBuilder for async data with proper loading/error/empty states.
    • Stateful selection of chart interval.
    • FavoritesService integration for toggling.
    • Consistent theming via AppColors and textTheme.
    • easy_localization for all displayed strings ('.tr()').
*/


import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import '../home/home_screen.dart';
import '../home/news_screen.dart';
import '../home/portfolio_screen.dart';
import '../home/bitcoin_screen.dart';
import '../home/profile_screen.dart';
import '../../models/stock_stats.dart' show StockStats;
import '../../models/time_series_point.dart' show TimeSeriesPoint;
import '../../models/news_item.dart' show NewsItem;
import '../../services/stock_service.dart';
import '../../services/news_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../widgets/price_chart.dart';
import 'package:intl/intl.dart';
import '../../services/favorites_service.dart';
import '../../models/company_profile.dart';

class StockDetailScreen extends ConsumerStatefulWidget {
  static const String routeName = '/stockDetail';
  final String symbol;
  final String companyName;

  const StockDetailScreen({
    Key? key,
    required this.symbol,
    required this.companyName,
  }) : super(key: key);

  @override
  _StockDetailScreenState createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends ConsumerState<StockDetailScreen> {
  late final StockService _stockService;
  late final NewsService _newsService;
  late Future<CompanyProfile> _profileFuture;

  late Future<List<TimeSeriesPoint>> _timeSeriesFuture;
  late Future<StockStats>             _keyStatsFuture;
  late Future<List<NewsItem>>         _newsFuture;

  int _currentIndex = 0;
  String _selectedRange = '1D';

  // Compact formatter for market cap, ranges, etc.
  final _capFmt = NumberFormat.compactCurrency(symbol: '€', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _stockService = StockService();
    _newsService = NewsService();

    _timeSeriesFuture = _stockService.fetchTimeSeries(
      symbol: widget.symbol,
      interval: _selectedRange,
    );
    _keyStatsFuture = _stockService.fetchKeyStats(widget.symbol);
    _newsFuture = _newsService.fetchLatestNews(widget.symbol);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final logoUrl = 'https://img.logo.dev/ticker/${widget.symbol}?token=pk_T8uVtgcmQsClYpLzZg2t1g&retina=true';
    final isFav = FavoritesService.isFavorite(widget.symbol);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Top bar ───────────────────────────────────────
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.symbol,
                          style: tt.headlineMedium!
                              .copyWith(color: AppColors.textHigh, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color:  isFav ? Colors.redAccent : AppColors.textMedium,
                          ),
                          onPressed: () async {
                            await FavoritesService.toggle(widget.symbol);
                            setState(() {}); // rebuild will re-read `isFav`
                          },
                        ),


                      ],
                    ),
                    const SizedBox(height: 16),

                    // ─── Time series chart ─────────────────────────────
                    FutureBuilder<List<TimeSeriesPoint>>(
                      future: _timeSeriesFuture,
                      builder: (context, snapshot) {
                        // loading
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return SizedBox(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          );
                        }
                        if (snapshot.connectionState == ConnectionState.done) {
                          print('chart[$_selectedRange] for ${widget.symbol} → ${snapshot.data?.length ?? 0} points');
                        }

                        // error
                        if (snapshot.hasError || (snapshot.data?.isEmpty ?? true)) {
                          return SizedBox(
                            height: 200,
                            child: Center(
                              child: Text(
                                'noChartData'.tr(),
                                style: tt.bodyMedium?.copyWith(color: Colors.white70),
                              ),
                            ),
                          );
                        }

                        final data = snapshot.data;
                        // no data
                        if (data == null || data.isEmpty) {
                          return Container(
                            height: 200,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Center(
                              child: Text(
                                'noChartData'.tr(),
                                style: tt.bodyMedium!.copyWith(color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
                        // success: map to spots
                        final spots = data
                            .asMap()
                            .entries
                            .map((e) => FlSpot(e.key.toDouble(), e.value.price))
                            .toList();
                        final isNegativeTrend = spots.last.y < spots.first.y;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Stock header: logo, symbol, name, price & %change
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                children: [
                                  ClipOval(
                                    child: Image.network(
                                      logoUrl,
                                      width: 32,
                                      height: 32,
                                      errorBuilder: (_, __, ___) =>
                                          Icon(Icons.image, color: AppColors.textMedium),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(widget.symbol,
                                          style: tt.bodyMedium?.copyWith(color: Colors.white)),
                                      Text(widget.companyName,
                                          style: tt.bodySmall?.copyWith(color: AppColors.textMedium)),
                                    ],
                                  ),
                                  const Spacer(),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '€${spots.last.y.toStringAsFixed(2)}',
                                        style: tt.headlineLarge?.copyWith(
                                          color: AppColors.textHigh,
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${isNegativeTrend ? '' : '+'}'
                                            '${((spots.last.y - spots.first.y) / spots.first.y * 100).toStringAsFixed(2)}%',
                                        style: tt.titleMedium?.copyWith(
                                          color: isNegativeTrend ? Colors.redAccent : Colors.greenAccent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Timeframe selector
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: ['1D', '1W', '1M', '3M', '1Y'].map((tf) {
                                final isSelected = _selectedRange == tf;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedRange = tf;
                                        _timeSeriesFuture = _stockService.fetchTimeSeries(
                                          symbol: widget.symbol,
                                          interval: tf,
                                        );
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primaryAccent
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        tf,
                                        textAlign: TextAlign.center,
                                        style: isSelected
                                            ? tt.bodyMedium?.copyWith(color: AppColors.textHigh)
                                            : tt.bodyMedium?.copyWith(color: AppColors.textMedium),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),

                            // The actual chart
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: AppColors.Borders1, width: 1),
                              ),
                              child: PriceChart(
                                spots: spots,
                                isNegativeTrend: isNegativeTrend,
                                timeframe: _selectedRange,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // ─── Key stats ─────────────────────────────────
                    FutureBuilder<StockStats>(
                      future: _keyStatsFuture,
                      builder: (context, snap) {
                        final tt = Theme.of(context).textTheme;

                        // 1) Loading or initial
                        if (snap.connectionState != ConnectionState.done) {
                          return SizedBox(
                            height: 120,
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          );
                        }
                        // 2) Error
                        if (snap.hasError || snap.data == null) {
                          return SizedBox(
                            height: 120,
                            child: Center(
                              child: Text('errorKeyStats'.tr(),
                                  style: tt.bodyMedium?.copyWith(color: Colors.redAccent)),
                            ),
                          );
                        }

                        // 3) Success – show stats
                        final stats = snap.data!;
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              // Left column (3 stats)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'keyStats'.tr(),
                                      style: tt.bodyMedium?.copyWith(color: Colors.white70),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Market Cap: ${_capFmt.format(stats.marketCap)}',
                                      style: tt.bodySmall?.copyWith(color: Colors.white),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'P/E Ratio: ${stats.peRatio.toStringAsFixed(2)}',
                                      style: tt.bodySmall?.copyWith(color: Colors.white),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Div Yield: ${stats.dividendYield.toStringAsFixed(2)}%',
                                      style: tt.bodySmall?.copyWith(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Right column (3 stats)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [

                                    Text(
                                      '52Wk Range:',
                                      style: tt.bodySmall?.copyWith(color: Colors.white),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${_capFmt.format(stats.week52Low)}–${_capFmt.format(stats.week52High)}',
                                      style: tt.bodySmall?.copyWith(color: Colors.white),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Avg Vol: ${NumberFormat.compact().format(stats.avgVolume)}',
                                      style: tt.bodySmall?.copyWith(color: Colors.white),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Beta: ${stats.beta.toStringAsFixed(2)}',
                                      style: tt.bodySmall?.copyWith(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );

                      },
                    ),

                    const SizedBox(height: 16),

                    // ─── News list ─────────────────────────────────
                    Text('news'.tr(), style: tt.headlineSmall?.copyWith(color: Colors.white)),
                    const SizedBox(height: 8),
                    FutureBuilder<List<NewsItem>>(
                      future: _newsFuture,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          );
                        } else if (snap.hasError) {
                          return Center(
                            child: Text(
                              'errorNews'.tr(),
                              style: tt.bodyMedium!.copyWith(color: Colors.white70),
                            ),
                          );
                        }
                        final newsItems = snap.data ?? [];
                        final preview = newsItems.length > 3
                            ? newsItems.sublist(0, 3)
                            : newsItems;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ...preview.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: _NewsCard(item: item),
                            )),
                            if (newsItems.length > 3)
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const NewsScreen()),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        'seeOtherNews'.tr(),
                                        style: tt.bodyLarge!
                                            .copyWith(color: Colors.white70, fontWeight: FontWeight.bold),
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
                        );
                      },
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),

              // ─── Floating nav ─────────────────────────────────
              Positioned(
                left: 24,
                right: 24,
                bottom: 16,
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: AppColors.textMedium.withAlpha(100), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(1, 1),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _NavIcon(
                        iconData: Icons.bar_chart,
                        isActive: _currentIndex == 0,
                        onTap: () {
                          setState(() => _currentIndex = 0);
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const HomeScreen()));
                        },
                      ),
                      _NavIcon(
                        iconData: Icons.calendar_today,
                        isActive: _currentIndex == 1,
                        onTap: () {
                          setState(() => _currentIndex = 1);
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const NewsScreen()));
                        },
                      ),
                      _NavIcon(
                        iconData: Icons.account_balance_wallet_outlined,
                        isActive: _currentIndex == 2,
                        onTap: () {
                          setState(() => _currentIndex = 2);
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PortfolioScreen()));
                        },
                      ),
                      _NavIcon(
                        iconData: Icons.currency_bitcoin,
                        isActive: _currentIndex == 3,
                        onTap: () {
                          setState(() => _currentIndex = 3);
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const BitcoinScreen()));
                        },
                      ),
                      _NavIcon(
                        iconData: Icons.person,
                        isActive: _currentIndex == 4,
                        onTap: () {
                          setState(() => _currentIndex = 4);
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ProfileScreen()));
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nav icon widget
class _NavIcon extends StatelessWidget {
  final IconData iconData;
  final bool isActive;
  final VoidCallback onTap;

  const _NavIcon({
    Key? key,
    required this.iconData,
    required this.isActive,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      splashColor: const Color(0xFF180E8D),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: isActive
            ? BoxDecoration(
          color: AppColors.primaryAccent.withAlpha(30),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryAccent.withAlpha(100),
              blurRadius: 8,
              spreadRadius: 2,
            )
          ],
        )
            : null,
        child:
        Icon(iconData, size: 28, color: isActive ? AppColors.primaryAccent : AppColors.textMedium),
      ),
    );
  }
}

/// Simple news card implementation
class _NewsCard extends StatelessWidget {
  final NewsItem item;

  const _NewsCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.headline, style: tt.bodyLarge!.copyWith(color: Colors.white)),
          const SizedBox(height: 4),
          Text(item.source, style: tt.bodySmall!.copyWith(color: AppColors.textMedium)),
        ],
      ),
    );
  }
}

/*
  portfolio_screen.dart – Displays the user’s favorite‐stock portfolio, with
  a combined value chart, holdings list, summary stats, and bottom nav.

  • ConsumerStatefulWidget (_PortfolioScreenState):
      – initState():
          • If static cache (_didLoad) exists, reuses cached spots, quotes, totals.
          • Else calls _loadPortfolio().
      – didChangeDependencies():
          • Calls _loadPortfolio() on every rebuild (e.g. when returning from detail).
      – _loadPortfolio():
          1) Sets _loading = true.
          2) Reads favorites via FavoritesService.list.
             – If empty → sets empty state and returns.
          3) Fetches 1M history for each symbol in parallel (fetchTimeSeries).
             – Catches per‐symbol errors, filters out empties.
          4) Fetches latest quotes for each symbol in parallel (fetchQuote).
             – Catches errors, filters nulls.
          5) If there’s valid history:
             – Aligns by shortest series length.
             – Builds List<FlSpot> summing prices at each index.
             – Computes total (last), profit (last − first), min/max wallet values.
          6) Updates state (_favs, _quotes, _spots, _total, _profit, etc.) and caches results.
          7) Finally sets _loading = false.
      – _currentIndex & _onNavTap():
          • Track and navigate between tabs (Home, News, Portfolio, Bitcoin, Profile).

  • build():
      – Shows a full‐screen gradient background.
      – If _loading: shows a centered CircularProgressIndicator.
      – Else: Column layout:
          1) Top Bar:
             – Back button → HomeScreen.
             – Localized title 'portfolioTitle'.tr().
          2) Total Balance + Chart:
             – Card showing _total balance and monthly _profit, with a PriceChart.
          3) Analysis Button:
             – Outlined “analysisPortfolio”.tr() button (TODO action).
          4) Holdings Header: localized text.
          5) Holdings List (ListView.separated):
             – For each StockData in _quotes:
               • Logo (Image.network with errorBuilder).
               • Symbol & placeholder company name.
               • Price & percent change (colored up/down).
               • Heart IconButton to toggle favorite and reload portfolio.
               • onTap → StockDetailScreen; refresh portfolio when returning.
          6) Profit & Wallet Cards:
             – Two side‐by‐side cards summarizing all‐time profit and min/max wallet.
          7) Bottom Nav Bar:
             – Pill‐shaped container with five _NavIcon tabs.

  • _NavIcon:
      – StatelessWidget taking icon & index.
      – Uses context.findAncestorStateOfType to read _currentIndex.
      – AnimatedContainer highlights the active tab (primaryAccent background/shadow).
*/


import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/theme/app_theme.dart';
import '../../services/stock_service.dart';
import '../../services/favorites_service.dart';
import '../../models/time_series_point.dart';
import '../../widgets/price_chart.dart';
import 'home_screen.dart';
import 'news_screen.dart';
import 'bitcoin_screen.dart';
import 'profile_screen.dart';
import 'stock_detail_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  final _stockService = StockService();

  bool _loading = true;

  // portfolio history
  List<FlSpot> _spots = [];
  double _total = 0, _profit = 0, _minWallet = 0, _maxWallet = 0;

  // saved tickers & quotes
  List<String> _favs = [];
  List<StockData> _quotes = [];

  // ─── STATIC CACHE ────────────────────────────────────────
  static bool    _didLoad     = false;
  static List<FlSpot>? _cacheSpots;
  static double?       _cacheTotal;
  static double?       _cacheProfit;
  static List<String>? _cacheFavs;
  static List<StockData>? _cacheQuotes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // every time this widget rebuilds after navigation, reload
    _loadPortfolio();
  }

  @override
  void initState() {
    super.initState();
    if (_didLoad &&
        _cacheSpots != null &&
        _cacheFavs != null &&
        _cacheQuotes != null &&
        _cacheTotal != null &&
        _cacheProfit != null) {
      // reuse cache
      _spots   = _cacheSpots!;
      _favs    = _cacheFavs!;
      _quotes  = _cacheQuotes!;
      _total   = _cacheTotal!;
      _profit  = _cacheProfit!;
      _loading = false;
    } else {
      _loadPortfolio();
    }
  }

  Future<void> _loadPortfolio() async {
    setState(() => _loading = true);

    try {
      final favs = FavoritesService.list;
      if (favs.isEmpty) {
        // No favorites → show empty state
        if (!mounted) return;
        setState(() {
          _favs = [];
          _quotes = [];
          _spots = [];
          _total = 0;
          _profit = 0;
          _minWallet = 0;
          _maxWallet = 0;
        });
        return;
      }

      // 1) Fetch 1M history in parallel, but catch per‐symbol errors
      final seriesList = await Future.wait<List<TimeSeriesPoint>>(
        favs.map((sym) async {
          try {
            return await _stockService.fetchTimeSeries(
              symbol: sym,
              interval: '1M',
            );
          } catch (e) {
            debugPrint('TimeSeries load failed for $sym: $e');
            return <TimeSeriesPoint>[];
          }
        }),
      );

      // Filter out any empty histories
      final validSeries = seriesList.where((l) => l.isNotEmpty).toList();

      // 2) Fetch current quotes in parallel, also guarded
      final quotes = (await Future.wait<StockData?>(favs.map((sym) async {
        try {
          return await _stockService.fetchQuote(sym);
        } catch (e) {
          debugPrint('Quote load failed for $sym: $e');
          return null;
        }
      })))
          .whereType<StockData>()
          .toList();

      // Prepare defaults
      List<FlSpot> spots = [];
      double total = 0, profit = 0, minW = 0, maxW = 0;

      // 3) Only build the chart if we have at least one non-empty series
      if (validSeries.isNotEmpty) {
        // Align by the shortest series
        final len = validSeries.map((l) => l.length).reduce(min);

        // If the shortest length is still at least 1, build spots
        if (len > 0) {
          spots = List<FlSpot>.generate(len, (i) {
            final sum = validSeries.fold<double>(
              0,
                  (acc, series) => acc + series[i].price,
            );
            return FlSpot(i.toDouble(), sum);
          });

          final values = spots.map((s) => s.y).toList();
          final first = values.first;
          final last = values.last;

          total = last;
          profit = last - first;
          minW = values.reduce(min);
          maxW = values.reduce(max);
        }
      }

      // 4) Commit to state
      if (!mounted) return;
      setState(() {
        _favs      = favs;
        _quotes    = quotes;
        _spots     = spots;
        _total     = total;
        _profit    = profit;
        _minWallet = minW;
        _maxWallet = maxW;
      });

      // 5) Update static cache if you still want it
      _didLoad     = true;
      _cacheSpots  = spots;
      _cacheFavs   = favs;
      _cacheQuotes = quotes;
      _cacheTotal  = total;
      _cacheProfit = profit;
    } catch (e, st) {
      debugPrint('Unexpected error in _loadPortfolio: $e\n$st');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }



  int _currentIndex = 2; // portfolio tab

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isNegative = _profit < 0;
    final favs       = FavoritesService.list;

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
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ─── Top Bar ────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'portfolioTitle'.tr(),
                      style: tt.headlineMedium!.copyWith(
                        color: AppColors.textHigh,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── Total Balance + Chart ───────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '€${_total.toStringAsFixed(2)}',
                            style: tt.headlineLarge!.copyWith(
                              fontSize: 36,
                              color: AppColors.textHigh,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isNegative ? Icons.trending_down : Icons.trending_up,
                                    color: isNegative ? Colors.redAccent : Colors.greenAccent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${isNegative ? '' : '+'}${_profit.toStringAsFixed(2)}€',
                                    style: tt.bodyMedium!.copyWith(
                                      color: isNegative ? Colors.redAccent : Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'for month'.tr(),
                                style: tt.bodySmall!.copyWith(color: AppColors.textMedium),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 120,
                        child: PriceChart(
                          spots: _spots,
                          isNegativeTrend: isNegative,
                          timeframe: '1M',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ─── Analysis Button Only ────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: navigate to analysis screen
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primaryAccent),
                    backgroundColor: AppColors.cardBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  icon: const Icon(Icons.bar_chart, color: AppColors.primaryAccent),
                  label: Text(
                    'analysisPortfolio'.tr(),
                    style: tt.bodyMedium!.copyWith(color: AppColors.textHigh),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ─── Holdings Header ─────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'portfolioManagement'.tr(),
                  style: tt.titleMedium!.copyWith(
                    color: AppColors.textHigh,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ─── Holdings List ───────────────────────
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _quotes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final q    = _quotes[i];
                    final up   = q.changePercent >= 0;
                    final isFav = favs.contains(q.symbol);

                    return GestureDetector(
                      onTap: () async {
                        // push and wait until detail screen is popped
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StockDetailScreen(
                              symbol:      q.symbol,
                              companyName: q.symbol,
                            ),
                          ),
                        );
                        // now that we're back, reload
                        if (mounted) {
                          _loadPortfolio();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            ClipOval(
                              child: Image.network(
                                'https://img.logo.dev/ticker/${q.symbol}?token=pk_T8uVtgcmQsClYpLzZg2t1g&retina=true',
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Icon(Icons.show_chart, color: AppColors.textMedium),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    q.symbol,
                                    style: tt.bodyLarge!.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${q.symbol} Corp.',
                                    style: tt.bodySmall!.copyWith(color: AppColors.textMedium),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '€${q.price.toStringAsFixed(2)}',
                                  style: tt.bodyLarge!.copyWith(color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${up ? '+' : ''}${q.changePercent.toStringAsFixed(2)}%',
                                  style: tt.bodySmall!.copyWith(
                                    color: up
                                        ? AppColors.upwardMovement
                                        : AppColors.downwardMovement,
                                  ),
                                ),
                              ],
                            ),

                            // ← Heart icon to favorite/unfavorite
                            IconButton(
                              icon: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.redAccent : AppColors.textMedium,
                              ),
                              onPressed: () async {
                                await FavoritesService.toggle(q.symbol);
                                await _loadPortfolio();  // rebuilds _favs, _quotes, chart, etc.
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
              // ─── Profit & Wallet Cards ───────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('profit'.tr(), style: tt.bodyMedium!.copyWith(color: AppColors.textMedium)),
                            const SizedBox(height: 8),
                            Text(
                              '${_profit >= 0 ? '+' : ''}${_profit.toStringAsFixed(2)}€',
                              style: tt.headlineSmall!
                                  .copyWith(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${(_profit / _total * 100).toStringAsFixed(2)}%',
                              style: tt.bodyMedium!.copyWith(color: Colors.greenAccent),
                            ),
                            Text('for all time'.tr(), style: tt.bodySmall!.copyWith(color: AppColors.textMedium)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('wallet'.tr(), style: tt.bodyMedium!.copyWith(color: AppColors.textMedium)),
                            const SizedBox(height: 8),
                            Text('Min: €${_minWallet.toStringAsFixed(2)}',
                                style: tt.bodyMedium!.copyWith(color: AppColors.textHigh)),
                            Text('Max: €${_maxWallet.toStringAsFixed(2)}',
                                style: tt.bodyMedium!.copyWith(color: AppColors.textHigh)),
                            Text('2W ago'.tr(), style: tt.bodySmall!.copyWith(color: AppColors.textMedium)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── Bottom Nav Bar ─────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: AppColors.textMedium.withAlpha(100), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.40),
                        blurRadius: 8,
                        offset: const Offset(1, 1),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _NavIcon(Icons.bar_chart, 0),
                      _NavIcon(Icons.calendar_today, 1),
                      _NavIcon(Icons.account_balance_wallet_outlined, 2),
                      _NavIcon(Icons.currency_bitcoin, 3),
                      _NavIcon(Icons.person, 4),
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

  void _onNavTap(int idx) {
    setState(() => _currentIndex = idx);
    Widget dest;
    switch (idx) {
      case 0:
        dest = HomeScreen();
        break;
      case 1:
        dest = NewsScreen();
        break;
      case 2:
        dest = const PortfolioScreen();
        break;
      case 3:
        dest = const BitcoinScreen();
        break;
      case 4:
        dest = const ProfileScreen();
        break;
      default:
        dest = HomeScreen();
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => dest));
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final int index;
  const _NavIcon(this.icon, this.index, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_PortfolioScreenState>()!;
    final isActive = state._currentIndex == index;
    return InkResponse(
      onTap: () => state._onNavTap(index),
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
        child: Icon(icon, size: 28, color: isActive ? AppColors.primaryAccent : AppColors.textMedium),
      ),
    );
  }
}

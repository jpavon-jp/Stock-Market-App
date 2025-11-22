/*
  bitcoin_screen.dart – Bitcoin Price, Chart & News

  • StatefulWidget (_BitcoinScreenState):
      – initState():
          • Generates mock FlSpot data for various timeframes (1D,1W,1M,3M,1Y).
          • Kicks off NewsService.fetchLatestNews('BTC') to load headlines.
          • Reads FavoritesService.isFavorite('BTC') to set heart icon.
          • Schedules a one-time pro upsell dialog via PurchaseService.hasPro().

      – _generateSpots():
          • Randomly walks price around a base value to simulate a chart.
          • Rebuilds _spots for the active timeframe when switching tabs.

      – _setFrame(frame):
          • Changes the selected timeframe label.
          • Calls _generateSpots() to refresh the chart.

      – _toggleFavorite():
          • Adds/removes 'BTC' from persistent favorites.
          • Updates the heart icon state immediately.

      – _showProDialog():
          • Non-dismissable custom dialog showing Pro features.
          • Navigates to PaymentScreen or HomeScreen on button taps.

  • build():
      – Root Stack:
          1) Gradient background + scrollable content:
              • Top bar with back arrow + favorite icon.
              • BTC card: icon, price, %change, FlChart line chart, timeframe selector.
              • Key Stats card: Market Cap, 52W Range, P/E, Avg Volume, Div Yield, Beta.
              • News preview: first 3 headlines via FutureBuilder.
          2) Floating bottom nav (pill shape):
              • Icons for Home, All Stocks, Portfolio, Bitcoin (active), Profile.
              • onTap: Navigator.pushReplacement to switch screens.

  • Helper Widgets:
      – _buildBitcoinCard(): styles the BTC info & chart card.
      – _buildKeyStats(): lays out stats in a rounded container.
      – _buildNews(): wraps FutureBuilder for news items.
      – _statItem(): a reusable label+value column.
      – _CheckRow(): row with a green check and text.
      – _NewsCard(): simple card for a NewsItem.
      – _NavIcon(): animated bottom-nav icon with active state.

  Usage:
    Navigator.pushNamed(context, BitcoinScreen.routeName);
*/


import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/theme/app_theme.dart';
import '../../models/news_item.dart';
import '../../services/news_service.dart';
import '../../services/favorites_service.dart';
import '../../services/purchase_service.dart';
import '../../widgets/price_chart.dart';

import 'home_screen.dart';
import 'all_stocks_screen.dart';
import 'portfolio_screen.dart';
import 'profile_screen.dart';
import '../auth/payment_screen.dart';

class BitcoinScreen extends StatefulWidget {
  const BitcoinScreen({Key? key}) : super(key: key);

  @override
  _BitcoinScreenState createState() => _BitcoinScreenState();
}

class _BitcoinScreenState extends State<BitcoinScreen> {
  final _newsService = NewsService();
  late final Future<List<NewsItem>> _newsFuture;
  bool _proDialogAlreadyScheduled = false;

  // ── mock data ─────────────────────────
  final double _price = 93674.68;
  final double _percentChange = 1.39;
  final Map<String, int> _timeframeLengths = {
    '1D': 30,
    '1W': 50,
    '1M': 60,
    '3M': 80,
    '1Y': 100,
  };

  String _activeFrame = '1D';
  List<FlSpot> _spots = [];
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _generateSpots();
    _newsFuture = _newsService.fetchLatestNews('BTC');
    _isFavorite = FavoritesService.isFavorite('BTC');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowProDialog();
    });
  }

  Future<void> _maybeShowProDialog() async {
    if (_proDialogAlreadyScheduled) return;
    _proDialogAlreadyScheduled = true;
    final hasPro = await PurchaseService.hasPro();
    if (!hasPro) _showProDialog();
  }

  void _generateSpots() {
    final rnd = Random();
    final count = _timeframeLengths[_activeFrame]!;
    var y = _price;
    final spots = <FlSpot>[];
    for (var i = 0; i < count; i++) {
      y += rnd.nextDouble() * 200 - 100;
      spots.add(FlSpot(i.toDouble(), y));
    }
    setState(() => _spots = spots);
  }

  void _setFrame(String frame) {
    if (frame == _activeFrame) return;
    setState(() => _activeFrame = frame);
    _generateSpots();
  }

  void _toggleFavorite() {
    setState(() {
      if (_isFavorite) {
        FavoritesService.remove('BTC');
      } else {
        FavoritesService.add('BTC');
      }
      _isFavorite = !_isFavorite;
    });
  }

  void _showProDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.backgroundGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'goPro'.tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall!
                        .copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  _CheckRow('realTimePrice'.tr()),
                  _CheckRow('advancedCharts'.tr()),
                  _CheckRow('adFreeExperience'.tr()),
                  _CheckRow('unlimitedPortfolio'.tr()),
                  _CheckRow('trial'.tr()),
                  Text('plans'.tr()),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.upwardMovement,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PaymentScreen()),
                          ),
                          child: Text('upgradeNow'.tr()),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                          ),
                          child: Text(
                            'maybeLater'.tr(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDown = _spots.isNotEmpty && _spots.last.y < _spots.first.y;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Main scrollable area with gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: AppColors.backgroundGradient,
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    children: [
                      // Top bar
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const HomeScreen()),
                              ),
                              child: const Icon(Icons.arrow_back_ios,
                                  color: Colors.white, size: 28),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                _isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _isFavorite
                                    ? AppColors.upwardMovement
                                    : Colors.white,
                              ),
                              onPressed: _toggleFavorite,
                            ),
                          ],
                        ),
                      ),

                      // BTC chart card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildBitcoinCard(tt, isDown),
                      ),

                      const SizedBox(height: 24),

                      // Key stats (Table)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildKeyStats(tt),
                      ),

                      const SizedBox(height: 16),

                      // News preview
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildNews(tt),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ─── Floating, pill‐shaped bottom nav ─────────────────────
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.cardBackground.withOpacity(0.99),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.Borders1,
                    blurRadius: 10,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavIcon(
                    icon: Icons.bar_chart,
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    ),
                    isActive: false,
                  ),
                  _NavIcon(
                    icon: Icons.list,
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const AllStocksScreen()),
                    ),
                    isActive: false,
                  ),
                  _NavIcon(
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const PortfolioScreen()),
                    ),
                    isActive: false,
                  ),
                  _NavIcon(
                    icon: Icons.currency_bitcoin,
                    onTap: () {}, // current screen
                    isActive: true,
                  ),
                  _NavIcon(
                    icon: Icons.person,
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    ),
                    isActive: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── helper widgets ────────────────────────────────────────────────

  Widget _buildBitcoinCard(TextTheme tt, bool isDown) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.currency_bitcoin, color: AppColors.textMedium),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BTC',
                      style: tt.headlineSmall!.copyWith(color: Colors.white)),
                  Text('Bitcoin',
                      style: tt.bodySmall!.copyWith(color: AppColors.textMedium)),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('€${_price.toStringAsFixed(2)}',
                      style: tt.headlineLarge!
                          .copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(
                    '${_percentChange >= 0 ? '+' : ''}${_percentChange.toStringAsFixed(2)}%',
                    style: tt.bodyMedium!.copyWith(
                        color: _percentChange >= 0
                            ? AppColors.upwardMovement
                            : AppColors.downwardMovement),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PriceChart(spots: _spots, isNegativeTrend: isDown),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _timeframeLengths.keys.map((f) {
              final active = f == _activeFrame;
              return GestureDetector(
                onTap: () => _setFrame(f),
                child: Text(
                  f,
                  style: tt.bodyMedium!.copyWith(
                    color: active ? Colors.white : AppColors.textMedium,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyStats(TextTheme tt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('keyStats'.tr(),
              style: tt.bodyMedium!.copyWith(color: Colors.white70)),
          const SizedBox(height: 8),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(1),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(children: [
                _statItem('Market Cap', '€1.12T'),
                _statItem('52 W Range', '21 350'),
              ]),
              TableRow(children: [
                _statItem('P/E Ratio', 'N/A'),
                _statItem('Avg Volume', '32.6B'),
              ]),
              TableRow(children: [
                _statItem('Div Yield', '0 %'),
                _statItem('Beta', '1.62'),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNews(TextTheme tt) {
    return FutureBuilder<List<NewsItem>>(
      future: _newsFuture,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.white));
        }
        if (snap.hasError || snap.data == null) {
          return Text('errorNews'.tr(),
              style: tt.bodyMedium!.copyWith(color: Colors.redAccent));
        }
        final news = snap.data!;
        final preview = news.length > 3 ? news.sublist(0, 3) : news;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('news'.tr(),
                style: tt.headlineSmall!.copyWith(color: Colors.white)),
            const SizedBox(height: 8),
            ...preview.map((i) => _NewsCard(item: i)),
          ],
        );
      },
    );
  }

  Widget _statItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: AppColors.textMedium)),
          const SizedBox(height: 2),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String text;
  const _CheckRow(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        const Icon(Icons.check_circle, color: Colors.green),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: Theme.of(c)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: Colors.white)),
        ),
      ],
    ),
  );
}

class _NewsCard extends StatelessWidget {
  final NewsItem item;
  const _NewsCard({required this.item, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext c) {
    final tt = Theme.of(c).textTheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.headline,
              style: tt.bodyLarge!.copyWith(color: Colors.white)),
          const SizedBox(height: 4),
          Text(item.source,
              style: tt.bodySmall!.copyWith(color: AppColors.textMedium)),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _NavIcon({
    required this.icon,
    required this.onTap,
    required this.isActive,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext c) =>
      InkResponse(
        onTap: onTap,
        splashColor: const Color(
            0xFF180E8D),
        radius: 28,
        child: AnimatedContainer(
          duration: const Duration(
              milliseconds: 200),
          padding: const EdgeInsets.all(
              8),
          decoration: isActive
              ? BoxDecoration(
            color: AppColors
                .primaryAccent
                .withAlpha(30),
            borderRadius: BorderRadius
                .circular(24),
            boxShadow: [
              BoxShadow(
                  color: AppColors
                      .primaryAccent
                      .withAlpha(100),
                  blurRadius: 8,
                  spreadRadius: 2)
            ],
          )
              : null,
          child: Icon(icon,
              size: 28,
              color: isActive
                  ? AppColors
                  .primaryAccent
                  : AppColors
                  .textMedium),
        ),
      );
}
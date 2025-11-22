/*
  all_stocks_screen.dart – Browse & Search Stocks

  • StatefulWidget + StockService:
      – Uses StockService.fetchQuote() to pull live quotes for a predefined list of US & EU tickers.
      – Maintains _stocksFuture that reloads whenever the selected market or search query changes.

  • Market Filter (DropdownButtonFormField):
      – Toggles between “All”, “US”, and “EU” markets.
      – On change, clears the search bar and calls _reloadList() to rebuild _stocksFuture.

  • Search Bar (TextField):
      – Uppercases user input and filters the fetched stock rows in real time.
      – ListView only displays rows whose symbol or company name contains the query.

  • FutureBuilder & ListView:
      – Shows a loading spinner until quotes load.
      – On success, maps each _StockRow to a tappable Container:
          • Displays a logo image, symbol, company, price, and percent change.
          • Tapping navigates to StockDetailScreen via Navigator.push.

  • Bottom Navigation Row:
      – Five _NavIcon widgets (Home, News, Portfolio, Bitcoin, Profile).
      – Highlights the active index and uses Navigator.pushReplacement to switch screens.

  • Helper Classes:
      – _StockRow: simple model holding symbol, company, price, changePercent.
      – _NavIcon: reusable icon with active styling and onTap callback.

  Usage:
    Navigator.pushNamed(context, AllStocksScreen.routeName);
*/


import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/theme/app_theme.dart';
import '../../services/stock_service.dart';
import 'stock_detail_screen.dart';
import 'home_screen.dart';
import 'news_screen.dart';
import 'portfolio_screen.dart';
import 'bitcoin_screen.dart';
import 'profile_screen.dart';

class AllStocksScreen extends StatefulWidget {
  static const String routeName = '/all_stocks';
  const AllStocksScreen({Key? key}) : super(key: key);

  @override
  _AllStocksScreenState createState() => _AllStocksScreenState();
}

class _AllStocksScreenState extends State<AllStocksScreen> {
  final _service = StockService();
  final _searchCtrl = TextEditingController();

  // 40 large-cap U.S. tickers
  static const List<String> _usSymbols = [
    'AAPL','MSFT','AMZN','GOOGL','TSLA','META','NVDA','BRK.B','JPM','UNH',
    'V','MA','HD','XOM','BAC','PFE','KO','PEP','CVX','DIS',
    'CMCSA','INTC','ADBE','CSCO','NFLX','WMT','CRM','NKE','ABBV','COST',
    'MCD','ORCL','MRK','ACN','TXN','AVGO','AMD','GS','QCOM','IBM'
  ];

  // well-known Eurozone blue-chips
  static const List<String> _euSymbols = [
    'SAP','ASML','LVMH','ROG','BAS','AIR','SIE','SAN','BNP','ORP',
  ];

  static const List<String> _markets = ['All','US','EU'];

  String _market       = 'All';
  String _searchQuery  = '';
  int    _currentIndex = 0;

  late Future<List<_StockRow>> _stocksFuture;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toUpperCase();
      });
    });
    _reloadList();
  }

  void _reloadList() {
    final symbols = (_market == 'US')
        ? _usSymbols
        : (_market == 'EU')
        ? _euSymbols
        : [..._usSymbols, ..._euSymbols];
    setState(() {
      _stocksFuture = _fetchRows(symbols);
    });
  }

  Future<List<_StockRow>> _fetchRows(List<String> syms) async {
    final rows = <_StockRow>[];
    for (final sym in syms) {
      try {
        final q = await _service.fetchQuote(sym);
        rows.add(_StockRow(
          symbol:        q.symbol,
          company:       sym, // detail screen will fetch full name
          price:         q.price,
          changePercent: q.changePercent,
        ));
      } catch (_) {
        // skip symbols with no data
      }
    }
    return rows;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

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
          child: Column(
            children: [
              // ─── Market Filter ───────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DropdownButtonFormField<String>(
                  value: _market,
                  items: _markets
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) {
                    _market = v!;
                    _searchCtrl.clear();
                    _searchQuery = '';
                    _reloadList();
                  },
                  decoration: InputDecoration(
                    labelText: 'market'.tr(),
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              // ─── Search Bar ─────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchCtrl,
                  style: tt.bodyMedium?.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    hintText: 'search'.tr(),
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),

              // ─── Stock List ─────────────────────────
              Expanded(
                child: FutureBuilder<List<_StockRow>>(
                  future: _stocksFuture,
                  builder: (ctx, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }
                    if (snap.hasError) {
                      return Center(
                        child: Text(
                          'errorStocks'.tr(),
                          style: tt.bodyMedium?.copyWith(color: AppColors.textMedium),
                        ),
                      );
                    }

                    final all = snap.data ?? [];
                    final filtered = all.where((row) {
                      if (_searchQuery.isEmpty) return true;
                      return row.symbol.contains(_searchQuery)
                          || row.company.toUpperCase().contains(_searchQuery);
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          'noMatching'.tr(),
                          style: tt.bodyMedium?.copyWith(color: AppColors.textMedium),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final s  = filtered[i];
                        final up = s.changePercent >= 0;
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StockDetailScreen(
                                symbol:      s.symbol,
                                companyName: s.company,
                              ),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                ClipOval(
                                  child: Image.network(
                                    'https://img.logo.dev/ticker/${s.symbol}?token=pk_T8uVtgcmQsClYpLzZg2t1g&retina=true',
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Icon(Icons.image, color: AppColors.textMedium),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.symbol,
                                          style: tt.bodyLarge
                                              ?.copyWith(color: Colors.white)),
                                      Text(s.company,
                                          style: tt.bodySmall
                                              ?.copyWith(color: AppColors.textMedium)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '€${s.price.toStringAsFixed(2)}',
                                      style: tt.bodyLarge
                                          ?.copyWith(color: Colors.white),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${up ? '+' : ''}${s.changePercent.toStringAsFixed(2)}%',
                                      style: tt.bodySmall?.copyWith(
                                        color: up
                                            ? AppColors.upwardMovement
                                            : AppColors.downwardMovement,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // ─── Bottom Nav ─────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavIcon(Icons.bar_chart,       _currentIndex == 0, () => _goTo(const HomeScreen())),
                    _NavIcon(Icons.calendar_today,  _currentIndex == 1, () => _goTo(const NewsScreen())),
                    _NavIcon(Icons.account_balance_wallet_outlined,
                        _currentIndex == 2, () => _goTo(const PortfolioScreen())),
                    _NavIcon(Icons.currency_bitcoin, _currentIndex == 3, () => _goTo(const BitcoinScreen())),
                    _NavIcon(Icons.person,          _currentIndex == 4, () => _goTo(const ProfileScreen())),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goTo(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

/// Simple view-model for each row
class _StockRow {
  final String symbol, company;
  final double price, changePercent;
  _StockRow({
    required this.symbol,
    required this.company,
    required this.price,
    required this.changePercent,
  });
}

/// Bottom-nav icon widget
class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool     isActive;
  final VoidCallback onTap;
  const _NavIcon(this.icon, this.isActive, this.onTap, {Key? key})
      : super(key: key);

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
        child: Icon(icon,
            size: 28,
            color: isActive ? AppColors.primaryAccent : AppColors.textMedium),
      ),
    );
  }
}

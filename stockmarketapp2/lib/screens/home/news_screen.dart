/*
  news_screen.dart – Displays the “News” tab with article list and bottom navigation

  • StatefulWidget (_NewsScreenState):
      – initState():
          • Initializes _newsFuture by calling NewsService().fetchLatestNews('general').
      – _onNavTap(idx):
          • Handles bottom‐nav taps (Home, News, Portfolio, Bitcoin, Profile).
          • Avoids reloading if tapped tab is already active.
          • Uses Navigator.pushReplacement to switch screens and update `_currentIndex`.

  • build():
      – Scaffold with transparent background and full‐screen gradient container.
      – SafeArea → Stack:
          1) Column:
              • Top Bar:
                  – Back arrow IconButton → HomeScreen.
                  – Localized title 'news'.tr().
              • Expanded FutureBuilder<List<NewsItem>> over `_newsFuture`:
                  – Loading: white CircularProgressIndicator.
                  – Error: localized error text.
                  – Empty: localized “no news” message.
                  – Data: ListView.separated of articles:
                      – Each item is a GestureDetector:
                          • onTap → opens NewsWebView(url: item.url, title: item.headline).
                          • Child is _NewsCard(item).
          2) Positioned Floating Bottom Nav (pill‐shaped):
              • Container with cardBackground color, rounded 32px, border, and drop shadow.
              • Row of five _NavIcon widgets:
                  – Icons.bar_chart (Home), calendar_today (News), account_balance_wallet (Portfolio),
                    currency_bitcoin (Bitcoin), person (Profile).
                  – Each _NavIcon takes icon, onTap callback, and `isActive` flag for styling.

  • _NewsCard:
      – StatelessWidget taking a NewsItem.
      – Renders a 180px‐tall Container:
          • If item.urlToImage is non‐empty: uses it as a full‐cover background image.
          • Otherwise: solid cardBackground.
          • Always overlays a 60px‐tall bottom gradient (transparent→black 70%).
          • Positions the headline text (max 2 lines, ellipsis) above the gradient,
            styled with high‐contrast text color and bold weight.

  • _NavIcon:
      – StatelessWidget for bottom‐nav icons.
      – InkResponse wrapping an AnimatedContainer:
          • 200ms animation of padding & decoration.
          • If `isActive`:
              – backgroundColor = primaryAccent with alpha
              – rounded corners (24px) + purple accent drop shadow
              – icon tinted primaryAccent
          • Else: transparent.
*/


import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/theme/app_theme.dart';
import '../../models/news_item.dart';
import '../../services/news_service.dart';
import '../news/news_webview.dart';
import 'home_screen.dart';
import 'portfolio_screen.dart';
import 'bitcoin_screen.dart';
import 'profile_screen.dart';

class NewsScreen extends StatefulWidget {
  static const String routeName = '/news';
  const NewsScreen({Key? key}) : super(key: key);

  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<NewsItem>> _newsFuture;
  int _currentIndex = 1; // News tab

  @override
  void initState() {
    super.initState();
    // <-- Pass 'general' so the service has its required argument
    _newsFuture = NewsService().fetchLatestNews('general');
  }

  void _onNavTap(int idx) {
    if (idx == _currentIndex) return;
    setState(() => _currentIndex = idx);
    Widget dest;
    switch (idx) {
      case 0:
        dest = const HomeScreen();
        break;
      case 1:
        dest = const NewsScreen();
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
        dest = const HomeScreen();
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => dest),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final tt   = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Top Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios,
                              color: Colors.white),
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const HomeScreen()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'news'.tr(),
                          style: tt.headlineMedium!.copyWith(
                            color: AppColors.textHigh,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // News List
                  Expanded(
                    child: FutureBuilder<List<NewsItem>>(
                      future: _newsFuture,
                      builder: (ctx, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                              child:
                              CircularProgressIndicator(color: Colors.white));
                        }
                        if (snap.hasError) {
                          return Center(
                            child: Text(
                              'errorNews'.tr(),
                              style: tt.bodyMedium!
                                  .copyWith(color: AppColors.textMedium),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        final items = snap.data ?? [];
                        if (items.isEmpty) {
                          return Center(
                            child: Text(
                              'noNewsMoment'.tr(),
                              style: tt.bodyMedium!
                                  .copyWith(color: AppColors.textMedium),
                            ),
                          );
                        }
                        return ListView.separated(
                          padding: EdgeInsets.only(
                            top: 8,
                            left: 16,
                            right: 16,
                            bottom: size.height * 0.14,
                          ),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final item = items[i];
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NewsWebView(
                                    url:   item.url,
                                    title: item.headline,
                                  ),
                                ),
                              ),
                              child: _NewsCard(item: item),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),

              // Floating Bottom Nav
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
                        width: 1.5),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.white.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(1, 1)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _NavIcon(Icons.bar_chart, () => _onNavTap(0),
                          isActive: _currentIndex == 0),
                      _NavIcon(Icons.calendar_today, () => _onNavTap(1),
                          isActive: _currentIndex == 1),
                      _NavIcon(Icons.account_balance_wallet_outlined,
                              () => _onNavTap(2),
                          isActive: _currentIndex == 2),
                      _NavIcon(Icons.currency_bitcoin, () => _onNavTap(3),
                          isActive: _currentIndex == 3),
                      _NavIcon(Icons.person, () => _onNavTap(4),
                          isActive: _currentIndex == 4),
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

class _NewsCard extends StatelessWidget {
  final NewsItem item;
  const _NewsCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasImage = item.urlToImage.isNotEmpty;
    final tt       = Theme.of(context).textTheme;

    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: hasImage ? Colors.black : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        image: hasImage
            ? DecorationImage(
            image: NetworkImage(item.urlToImage), fit: BoxFit.cover)
            : null,
      ),
      child: Stack(
        children: [
          // gradient overlay
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          // headline
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Text(
              item.headline,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tt.bodyLarge!
                  .copyWith(color: AppColors.textHigh, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  const _NavIcon(this.icon, this.onTap,
      {Key? key, this.isActive = false})
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
                spreadRadius: 2)
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

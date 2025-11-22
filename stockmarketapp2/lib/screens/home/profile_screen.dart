/*
  profile_screen.dart – Displays the user’s profile info, settings cards, and logout, with bottom navigation

  • ConsumerStatefulWidget (_ProfileScreenState):
      – _currentIndex = 4 to highlight the Profile tab.
      – Reads current AppUser from userProvider; shows loading spinner if null.

  • build():
      – Full‐screen gradient background.
      – SafeArea + Stack to overlay scrollable content & bottom nav.
      – SingleChildScrollView:
          1) Avatar Row:
             • CircleAvatar with person icon.
             • Username (or “—” if empty).
             • Theme toggle IconButton (TODO).
          2) Settings Cards (_buildCard):
             • identityVerification: shows “Verified” with check icon.
             • language: navigates to LanguageScreen.
             • proVersion: (placeholder arrow).
             • UID: displays user.uid with copy‐to‐clipboard button & snackbar.
             • personalData, connectedAccounts, countryRegion: each with arrow.
          3) Logout Row:
             • exit_to_app icon + “logOut”.tr().
             • onTap: calls authServiceProvider.signOut(), clears FavoritesService,
               resets userProvider, and navigates to LoginScreen clearing the stack.
      – Padding on scroll content leaves room for nav.

  • _buildCard():
      – Reusable container with title, optional subtitle, and trailing widget.
      – Styled with semi‐transparent cardBackground, rounded corners, accent border.

  • Floating Bottom Navigation:
      – Positioned at bottom: pill‐shaped container with 5 _NavIcon tabs.
      – Each _NavIcon:
         • iconData, isActive flag, and onTap callback.
         • AnimatedContainer “glows” when active (primaryAccent background & shadow).
         • onTap: updates _currentIndex and pushesReplacement to the corresponding screen
           (Home, News, Portfolio, Bitcoin, self).

  Key concepts:
    • Riverpod for reading/writing userProvider and authServiceProvider.
    • easy_localization for all displayed strings ('.tr()').
    • FavoritesService cleared on logout.
    • Clipboard.setData for copying UID.
    • SnackBar feedback on copy.
    • Consistent theming via AppColors and textTheme.
*/


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_user.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_providers.dart';
import '../../services/favorites_service.dart';
import '../auth/login_screen.dart';
import '../settings/language_screen.dart';
import 'home_screen.dart';
import 'portfolio_screen.dart';
import 'news_screen.dart';
import 'bitcoin_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  static const String routeName = '/profile';
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _currentIndex = 4; // Profile tab

  @override
  Widget build(BuildContext context) {
    final AppUser? user = ref.watch(userProvider);
    final size = MediaQuery.of(context).size;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userName    = user.name.isEmpty    ? '—' : user.name;
    final userCountry = user.country.isEmpty ? '—' : user.country;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundEnd,
              AppColors.backgroundStart,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  bottom: size.height * 0.14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Avatar, Name, Theme Toggle
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.transparent,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          userName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium!
                              .copyWith(
                            color: AppColors.textHigh,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.wb_sunny_outlined,
                            color: AppColors.textHigh.withAlpha(200),
                            size: 24,
                          ),
                          onPressed: () {
                            // TODO: Theme toggle
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    _buildCard(
                      context: context,
                      title: 'identityVerification'.tr(),
                      subtitle: 'status_verified'.tr(),
                      trailing: const Icon(Icons.check, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(
                        context,
                        LanguageScreen.routeName,
                      ),
                      child: _buildCard(
                        context: context,
                        title: 'language'.tr(),
                        subtitle: null,
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      context: context,
                      title: 'proVersion'.tr(),
                      subtitle: null,
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      context: context,
                      title: 'UID',
                      subtitle: user.uid,
                      trailing: IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: user.uid));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('uidCopied'.tr())),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      context: context,
                      title: 'personalData'.tr(),
                      subtitle: null,
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      context: context,
                      title: 'connectedAccounts'.tr(),
                      subtitle: null,
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      context: context,
                      title: 'countryRegion'.tr(),
                      subtitle: userCountry,
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          // sign out
                          await ref.read(authServiceProvider).signOut();
                          FavoritesService.clear();
                          ref.read(userProvider.notifier).state = null;
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            LoginScreen.routeName,
                                (route) => false,
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.exit_to_app,
                              size: 24,
                              color: AppColors.errorRed,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'logOut'.tr(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                color: AppColors.errorRed,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Bottom Navigation ────────────────────────────
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
                      color: AppColors.backgroundStart.withAlpha(100),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.Borders1.withOpacity(0.99),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(2, 2),
                      ),
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
                              builder: (_) => const HomeScreen(),
                            ),
                          );
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
                              builder: (_) => const NewsScreen(),
                            ),
                          );
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
                              builder: (_) => const PortfolioScreen(),
                            ),
                          );
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
                              builder: (_) => const BitcoinScreen(),
                            ),
                          );
                        },
                      ),
                      _NavIcon(
                        iconData: Icons.person,
                        isActive: _currentIndex == 4,
                        onTap: () {
                          // already here
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

  Widget _buildCard({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Widget trailing,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground.withAlpha(50),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primaryAccent.withAlpha(100),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium!
                        .copyWith(
                      color: AppColors.textHigh,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(
                        color: AppColors.textMedium,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing,
          ],
        ),
      );
}

/// Animated nav‐icon with “glow” on active
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

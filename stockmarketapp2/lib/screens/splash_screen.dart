/*
  splash_screen.dart – App Launch & Introductory Screen

  • ConsumerWidget
    – Uses Riverpod’s WidgetRef to watch `localeProvider`, pulling the
      current locale code (e.g. “en”, “es”) to display the matching flag icon.

  • Full-screen Gradient Background
    – Applies the `AppColors.backgroundGradient` from top to bottom, giving
      a smooth, multi-stop purple→navy backdrop on launch.

  • Language Selector
    – Positioned at the top-right (25px down + horizontal padding),
      shows a circular flag asset (`assets/images/<localeCode>.png`).
      Tapping it navigates to `LanguageScreen` for changing the app locale.

  • Centered Logo
    – Displays the “Tradion Dark” logo at 250×250px, providing brand
      reinforcement during the splash.

  • Headline & Body Copy
    – Headline: large, 50px, bold white text (`’headline’.tr()`), left-aligned.
    – Body: 16px white-70 text (`’bodyText’.tr()`), justified, giving a
      brief welcome message or app description.

  • Bottom CTA
    – A 3px white24 divider sits above the action.
    – “Take control” button: a centered `Row` with localized text
      and a forward arrow icon. Tapping it pushes replacement to
      `LoginScreen`.

  • Layout Spacers
    – Strategic `Spacer(flex: …)` calls push content to desired vertical
      positions without hard-coding absolute pixel offsets.

  This screen sets the tone on launch—handling localization, branding,
  and the first navigation step—while keeping all styling and text
  driven by centralized theme and translation resources.
*/


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/locale_provider.dart';
import 'settings/language_screen.dart';
import 'auth/login_screen.dart';

class SplashScreen extends ConsumerWidget {
  static const String routeName = '/splash';
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // Pull the current locale code for the flag asset

    final localeCode = ref.watch(localeProvider).languageCode;

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [

                // ── Language button, moved down 25px total ───────
                const SizedBox(height: 25),
                Row(
                  children: [
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LanguageScreen(),
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/$localeCode.png',
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Logo, enlarged to 160x160 ────────────────────
                const SizedBox(height: 35),
                Center(
                  child: Image.asset(
                    'assets/images/tradion_dark.png',
                    width: 250,
                    height: 250,
                  ),
                ),

                // Push headline/body down toward bottom
                const Spacer(flex: 16),

                // ── Headline, larger (32px) ───────────────────────
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'headline'.tr(),
                    textAlign: TextAlign.left,
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Extra gap before body
                const SizedBox(height: 35),

                // ── Body text, justified and further down ─────────
                Text(
                  'bodyText'.tr(),
                  textAlign: TextAlign.justify,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),

                // Push the divider/button all the way to bottom
                const Spacer(flex: 5),

                // ── Divider ───────────────────────────────────────
                const Divider(color: Colors.white24, thickness: 3),
                const SizedBox(height: 15),

                // ── “Take control” button centered at bottom ─────
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => LoginScreen()),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'takeControl'.tr(),
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

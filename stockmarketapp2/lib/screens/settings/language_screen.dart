/*
  language_screen.dart – In‐app language selection screen

  • LanguageScreen (ConsumerWidget):
      – Reads current locale code from Riverpod `localeProvider`.
      – Defines a static list `_languages` of available locales (_Lang(name, code, flag)).

  • build(context, ref):
      – Retrieves `currentCode` to know which language is active.
      – Configures a transparent AppBar with:
          • White back button.
          • Title text from localization: `'Language'.tr()`.
      – Displays a `ListView.separated` where each row is:
          • An `InkWell` wrapping a rounded Container:
              – Shows the language name, styled in white if selected or secondary text color otherwise.
              – Shows the corresponding flag image asset (32×32).
              – Applies a 2px accent border if selected, otherwise a 1px neutral border.
          • `onTap`:
              – Updates `localeProvider` state to `Locale(lang.code)`.
              – Calls `context.setLocale(...)` to notify `easy_localization`.
              – Pops back to the previous screen.

  • _Lang class:
      – Simple model holding:
          • `name`  – Display name (e.g. "English").
          • `code`  – Locale code (e.g. "en").
          • `flag`  – Filename for the flag asset (e.g. "english.png").

  • Usage:
      – Push with:
          Navigator.pushNamed(context, LanguageScreen.routeName);
      – Allows users to switch app language on the fly with immediate visual feedback.
*/


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/locale_provider.dart';

class LanguageScreen extends ConsumerWidget {
  static const String routeName = '/language';
  const LanguageScreen({Key? key}) : super(key: key);

  static const List<_Lang> _languages = <_Lang>[
    _Lang(name: 'English', code: 'en', flag: 'english.png'),
    _Lang(name: 'Spanish', code: 'es', flag: 'spanish.png'),
    _Lang(name: 'German',  code: 'de', flag: 'german.png'),
    _Lang(name: 'Russian', code: 'ru', flag: 'russian.png'),
    _Lang(name: 'Turkish', code: 'tr', flag: 'turkish.png'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCode = ref.watch(localeProvider).languageCode;
    final textTheme = Theme.of(context).textTheme;
    // Grab the "secondary" text color from the theme:
    final secondaryTextColor = textTheme.bodyMedium!.color!;

    return Scaffold(
      backgroundColor: AppColors.backgroundGradient.first,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Language'.tr(),
          style: textTheme.headlineSmall!.copyWith(color: Colors.white),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        itemCount: _languages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final lang = _languages[index];
          final selected = lang.code == currentCode;

          return InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () async {
              // Update Riverpod state
              ref.read(localeProvider.notifier).state = Locale(lang.code);
              // Notify easy_localization
              await context.setLocale(Locale(lang.code));
              Navigator.of(context).pop();
            },
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: selected ? AppColors.backgroundStart : AppColors.Borders1,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      lang.name,
                      style: textTheme.bodyLarge!.copyWith(
                        color: selected ? Colors.white : secondaryTextColor,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Image.asset(
                    'assets/images/${lang.flag}',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Lang {
  final String name, code, flag;
  const _Lang({required this.name, required this.code, required this.flag});
}

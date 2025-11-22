/*
  main.dart – Application Entry Points and Routing

This file bootstraps the Flutter app by first ensuring all native bindings and
localization resources are initialized (`WidgetsFlutterBinding.ensureInitialized()` and `EasyLocalization.ensureInitialized()`),
then configures Firebase once (`Firebase.initializeApp()`). We wrap our root widget in both a Riverpod `ProviderScope` (for global state management)
and `EasyLocalization` (for multi-language support, specifying supported locales, translation asset path, and a fallback
locale). The `AuthGate` widget (a `ConsumerWidget`) listens to Firebase auth state via `authStateProvider`,
showing either a loading spinner, error message, `LoginScreen` (if no user is logged in), or—upon successful login—fetching
the user’s profile from Firestore, populating our `userProvider`, initializing `FavoritesService` with the user’s UID, and
finally displaying the `HomeScreen`. We define two `MaterialApp` configurations: `StockMarketApp` (using named routes for
splash, login, signup, password reset, home, profile, and news screens) and `StockApp` (our actual root, also a `ConsumerWidget`
that watches `localeProvider`, sets the app’s locale, and defines the initial `home` as `AuthGate`, plus routes for login and
language selection). This structure cleanly separates concerns—initialization, authentication gating, localization,
state management, and navigation—so you can easily extend, test, and maintain your stock-market application.
*/


import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/new_password_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/profile_screen.dart';
import 'screens/home/news_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/locale_provider.dart';
import 'screens/settings/language_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_providers.dart';
import 'providers/user_provider.dart';                 // ← userProvider
import 'models/app_user.dart';                         // ← AppUser
import 'services/favorites_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // only ONE initialisation
  await Firebase.initializeApp();

  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('es'), Locale('de'), Locale('ru'), Locale('tr')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: const StockApp(),
      ),
    ),
  );
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos authStateProvider, que ahora devuelve AsyncValue<User?>
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        body: Center(child: Text('Auth error: $err')),
      ),
      data: (firebaseUser) {
        if (firebaseUser == null) {
          // Si no hay usuario logueado → pantalla de login
          return  LoginScreen();
        } else {
          // Si hay usuario, antes de mostrar Home traemos su perfil
          ref.read(authServiceProvider)
              .getProfile(firebaseUser.uid)
              .then((snap) {
            final data = snap.data()!;
            ref.read(userProvider.notifier).state = AppUser(
              uid:     firebaseUser.uid,
              name:    data['name']    ?? firebaseUser.displayName ?? '–',
              country: data['country'] ?? '–',
            );
          });
          FavoritesService.init(firebaseUser.uid);
          return const HomeScreen();
        }
      },
    );
  }
}


class StockMarketApp extends StatelessWidget {
  const StockMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Market App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(), // Ensure AppTheme is correctly defined in app_theme.dart
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (context) => SplashScreen(),
        LoginScreen.routeName: (context) => LoginScreen(),
        SignUpScreen.routeName: (context) => SignUpScreen(),
        NewPasswordScreen.routeName: (context) => NewPasswordScreen(),
        HomeScreen.routeName: (context) => HomeScreen(),
        ProfileScreen.routeName: (context) =>  ProfileScreen(),
        NewsScreen.routeName: (context) => NewsScreen(),
      },

    );
  }
}


class StockApp extends ConsumerWidget {
  const StockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    context.setLocale(locale);
    return MaterialApp(
      title: 'Tradion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),                 // <-- now defined
      locale: context.locale, // from EasyLocalization,                                       // ← add this
      supportedLocales: context.supportedLocales,     // ← add this
      localizationsDelegates: context.localizationDelegates
      ,
      home: const AuthGate(),
      routes: {
        LoginScreen.routeName: (_) =>  LoginScreen(),
        LanguageScreen.routeName: (_) =>  LanguageScreen(),
      },
    );
  }
}


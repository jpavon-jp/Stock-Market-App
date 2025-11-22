/*
  login_screen.dart – User Sign-In Screen

  • ConsumerStatefulWidget
    – Allows this screen to read and write Riverpod providers (e.g., authServiceProvider, userProvider).

  • Controllers & State Flags
    – _emailController, _passwordController : manage the text input for email/phone and password.
    – _loading : whether a login request is in progress (used to show a spinner and disable the button).
    – _error : holds any FirebaseAuthException message to display.
    – _showErrorText, _isEmailValid, _isPasswordValid : control inline validation messages and border coloring.

  • _submit()
    – Entry point for “Take Control” button tap.
    – Validates non-empty fields, toggles _loading, invokes Firebase signIn via authServiceProvider.
    – On success:
        • Initializes FavoritesService for the authenticated user.
        • Fetches user profile from Firestore and updates userProvider with AppUser.
        • Navigates to HomeScreen, replacing the login stack.
    – On failure:
        • Catches FirebaseAuthException, stores e.message in _error for UI display.
    – Always resets _loading at the end (in finally).

  • build()
    – Uses a full-screen gradient container (AppColors.backgroundEnd → backgroundStart).
    – Transparent AppBar with a back arrow → returns to SplashScreen.
    – Logo at top, followed by “Sign In” title (localized).
    – Conditional error messages:
        • “fill in” if fields are blank (_showErrorText)
        • Firebase error text if _error is non-null.
    – TextFields for email & password:
        • Styled with rounded borders (47px radius), color-coded based on validity flags.
        • onChanged handlers clear errors as the user types.
    – “Forgot Password?” link navigates to NewPasswordScreen.
    – Social sign-in row within a pill-shaped container:
        • CircleAvatar buttons for Apple, Google, Facebook (TODO placeholders).
    – “Take Control” CTA:
        • OutlinedButton with an arrow icon
        • Disabled while _loading is true
    – Bottom RichText:
        • “Don’t have an account? Sign up now” with a tappable TextSpan to push SignupScreen.

  • _SocialIconButton
    – Lightweight widget for circular social icons:
      • 48×48 CircleAvatar, using AppColors.cardBackground with 30% alpha.

  Localization & Theming
    – All user-facing text uses EasyLocalization’s `.tr()`.
    – Colors, padding, and typography derive from AppColors and the app’s TextTheme.
*/


import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';
import 'signup_screen.dart';         // ← Signup screen import
import 'new_password_screen.dart';   // ← New Password screen import
import 'package:easy_localization/easy_localization.dart';
import '../../screens/splash_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/app_user.dart';
import '../../providers/user_provider.dart';
import '../../services/favorites_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  static const String routeName = '/login';

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController    = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool  _loading   = false;
  String? _error;

  bool _showErrorText   = false;
  bool _isEmailValid    = true;
  bool _isPasswordValid = true;

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      final firebaseUser = await ref
          .read(authServiceProvider)
          .signIn(_emailController.text, _passwordController.text);

      if (firebaseUser != null) {
        // initialize FavoritesService with the real uid
        await FavoritesService.init(firebaseUser.uid);
      }


      final snap = await ref
          .read(authServiceProvider)
          .getProfile(firebaseUser!.uid);
      final data = snap.data() ?? {};

      final appUser = AppUser(
        uid:     firebaseUser.uid,
        name:    data['name'] ?? firebaseUser.displayName ?? '',
        country: data['country'] ?? '',
      );
      ref.read(userProvider.notifier).state = appUser;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch(e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SplashScreen()),
            );
          },
        ),

      ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 5),

                // --- LOGO ---
                Center(
                  child: Image.asset(
                    'assets/images/tradion_dark.png',
                    width: 200,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 10),

                // --- Title “Sign In” ---
                Center(
                  child: Text(
                    'signIn'.tr(),
                    style: textTheme.headlineMedium?.copyWith(
                      color: AppColors.textHigh,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_showErrorText) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'fillIn'.tr(),
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.errorRed,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
                // --- Firebase-auth error (e.g. wrong password) ---
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _error!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.errorRed,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                // --- Loading spinner while we contact Firebase ---
                if (_loading) ...[
                  const SizedBox(height: 16),
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryAccent,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // --- Email/Phone TextField ---
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style:
                  textTheme.bodyLarge?.copyWith(color: AppColors.textHigh),
                  decoration: InputDecoration(
                    labelText: 'emailOrPhone'.tr(),
                    labelStyle:
                    textTheme.bodyMedium?.copyWith(color: AppColors.textMedium),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    errorText:
                    !_isEmailValid ? 'enterEmail'.tr() : null,
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(47),
                      borderSide: BorderSide(
                        color: _isEmailValid
                            ? AppColors.primaryAccent
                            : AppColors.errorRed,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(47),
                      borderSide: BorderSide(
                        color: _isEmailValid
                            ? AppColors.primaryAccent
                            : AppColors.errorRed,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(47),
                      borderSide: BorderSide(
                        color: AppColors.primaryAccent,
                        width: 2.0,
                      ),
                    ),
                  ),
                  cursorColor: AppColors.primaryAccent,
                  onChanged: (_) {
                    if (!_isEmailValid) {
                      setState(() {
                        _isEmailValid = true;
                        if (!_isPasswordValid && !_showErrorText) {
                          _showErrorText = false;
                        }
                      });
                    }
                  },
                ),

                const SizedBox(height: 24),

                // --- Password TextField ---
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style:
                  textTheme.bodyLarge?.copyWith(color: AppColors.textHigh),
                  decoration: InputDecoration(
                    labelText: 'password'.tr(),
                    labelStyle:
                    textTheme.bodyMedium?.copyWith(color: AppColors.textMedium),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    errorText:
                    !_isPasswordValid ? 'enterPassword'.tr() : null,
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(47),
                      borderSide: BorderSide(
                        color: _isPasswordValid
                            ? AppColors.primaryAccent
                            : AppColors.errorRed,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(47),
                      borderSide: BorderSide(
                        color: _isPasswordValid
                            ? AppColors.primaryAccent
                            : AppColors.errorRed,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(47),
                      borderSide: BorderSide(
                        color: AppColors.primaryAccent,
                        width: 2.0,
                      ),
                    ),
                  ),
                  cursorColor: AppColors.primaryAccent,
                  onChanged: (_) {
                    if (!_isPasswordValid) {
                      setState(() {
                        _isPasswordValid = true;
                        if (!_isEmailValid && !_showErrorText) {
                          _showErrorText = false;
                        }
                      });
                    }
                  },
                ),

                const SizedBox(height: 8),

                // --- “Forgot Password?” link (now navigates to NewPasswordScreen) ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NewPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'forgotPassword'.tr(),
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.primaryAccent,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.only(top: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // --- “or sign in with” text (centered) ---
                Center(
                  child: Text(
                    'signInWith'.tr(),
                    style: textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textMedium),
                  ),
                ),

                const SizedBox(height: 16),

                // --- Social sign‐in icons in a 47px‐radius pill container ---
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(47),
                      border: Border.all(
                        color: AppColors.primaryAccent,
                        width: 1.5,
                      ),
                      color: AppColors.cardBackground.withAlpha(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SocialIconButton(
                          icon: Icons.apple,
                          color: Colors.white,
                          onPressed: () {
                            // TODO: Apple Sign-In
                          },
                        ),
                        const SizedBox(width: 16),
                        _SocialIconButton(
                          icon: Icons.g_mobiledata,
                          color: Colors.redAccent,
                          onPressed: () {
                            // TODO: Google Sign-In
                          },
                        ),
                        const SizedBox(width: 16),
                        _SocialIconButton(
                          icon: Icons.facebook,
                          color: Colors.blueAccent,
                          onPressed: () {
                            // TODO: Facebook Sign-In
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // --- “Take Control” outlined button (47px radius) ---
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.arrow_forward,
                        color: AppColors.primaryAccent,
                        size: 20,
                      ),
                      label: Text(
                        'takeControlBtn'.tr(),
                        style: textTheme.bodyLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        side: const BorderSide(
                          color: AppColors.primaryAccent,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(47),
                        ),
                      ),
                      onPressed: _loading ? null : _submit,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // --- Bottom: “You don't have an account? Sign up now” ---
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: 'haveAccount'.tr() + " ",
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textMedium,
                      ),
                      children: [
                        TextSpan(
                          text: 'signUpNow'.tr(),
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.primaryAccent,
                            decoration: TextDecoration.none,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SignUpScreen(),
                                ),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A 48x48 circular icon button for social sign‐in.
class _SocialIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _SocialIconButton({
    Key? key,
    required this.icon,
    required this.color,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.cardBackground.withAlpha(30),
      child: IconButton(
        icon: Icon(icon, color: color, size: 28),
        onPressed: onPressed,
      ),
    );
  }
}

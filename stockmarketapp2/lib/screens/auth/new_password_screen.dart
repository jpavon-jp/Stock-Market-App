/*
  new_password_screen.dart – Reset/Create New Password Screen

  • StatefulWidget
    – Manages three TextEditingControllers for email, password, and password confirmation.
    – Holds validation booleans:
      • _isEmailValid: whether the email contains “@”
      • _isPasswordValid: whether the new password is non-empty
      • _doPasswordsMatch: whether password and repeated password are identical
      • _showErrorText: whether to display a generic “fill in correctly” error

  • _attemptSubmit()
    – Reads and trims the three input values.
    – Updates validation flags based on simple checks.
    – If all checks pass, immediately navigates to HomeScreen (replace stack).
    – Otherwise, redisplays the form with red outlines and a central error message.

  • build()
    – Full-screen Container with top-to-bottom gradient (AppColors.backgroundEnd → backgroundStart).
    – Stack layout:
        1) SingleChildScrollView with Column:
           • Title (“New Password”) localized and centered.
           • Inline error message (if _showErrorText).
           • Three TextFields (email, password, repeat password):
             – Rounded borders (47px radius), colored red on validation failure, accent otherwise.
             – onChanged handlers clear the relevant error flag when the user edits.
           • “Take Control” CTA: an OutlinedButton with arrow icon, styled with AppColors.primaryAccent.
        2) Positioned close (“X”) icon at top-right:
           • Tapping it pops the screen to return to the previous context.

  • Theming & Localization
    – Uses EasyLocalization’s `.tr()` for all text.
    – Font sizes and weights drawn from the app’s TextTheme.
    – Colors (text, borders, background) come from AppColors.
*/

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class NewPasswordScreen extends StatefulWidget {
  static const String routeName = '/new_password';

  @override
  _NewPasswordScreenState createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  // Controllers for the three text fields
  final TextEditingController _emailController        = TextEditingController();
  final TextEditingController _passwordController     = TextEditingController();
  final TextEditingController _repeatPasswordController = TextEditingController();

  // Validation flags
  bool _showErrorText       = false;
  bool _isEmailValid        = true;
  bool _isPasswordValid     = true;
  bool _doPasswordsMatch    = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  void _attemptSubmit() {
    final email       = _emailController.text.trim();
    final password    = _passwordController.text.trim();
    final repeatPass  = _repeatPasswordController.text.trim();

    setState(() {
      _isEmailValid     = email.contains('@');
      _isPasswordValid  = password.isNotEmpty;
      _doPasswordsMatch = password == repeatPass && repeatPass.isNotEmpty;
      _showErrorText    = !_isEmailValid || !_isPasswordValid || !_doPasswordsMatch;
    });

    if (_isEmailValid && _isPasswordValid && _doPasswordsMatch) {
      // Navigate to HomeScreen after successful new password submission
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
              // Main content
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 48),

                    // --- Title “New Password” (centered) ---
                    Center(
                      child: Text(
                        'newPassword'.tr(),
                        style: textTheme.headlineMedium?.copyWith(
                          color: AppColors.textHigh,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // --- Error text below title (if any) ---
                    if (_showErrorText) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          // Show a generic error; individual field errors are indicated by red borders
                          'fillInCorrect'.tr(),
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.errorRed,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // --- EMAIL FIELD ---
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: textTheme.bodyLarge?.copyWith(color: AppColors.textHigh),
                      decoration: InputDecoration(
                        labelText: 'email'.tr(),
                        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMedium),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        errorText: !_isEmailValid ? 'enterEmail'.tr() : null,
                        filled: true,
                        fillColor: AppColors.cardBackground,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(47),
                          borderSide: BorderSide(
                            color: _isEmailValid ? AppColors.primaryAccent : AppColors.errorRed,
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(47),
                          borderSide: BorderSide(
                            color: _isEmailValid ? AppColors.primaryAccent : AppColors.errorRed,
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
                            if (!_isPasswordValid || !_doPasswordsMatch) _showErrorText = false;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    // --- PASSWORD FIELD ---
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: textTheme.bodyLarge?.copyWith(color: AppColors.textHigh),
                      decoration: InputDecoration(
                        labelText: 'password'.tr(),
                        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMedium),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        errorText: !_isPasswordValid ? 'enterPassword'.tr() : null,
                        filled: true,
                        fillColor: AppColors.cardBackground,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(47),
                          borderSide: BorderSide(
                            color: _isPasswordValid ? AppColors.primaryAccent : AppColors.errorRed,
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(47),
                          borderSide: BorderSide(
                            color: _isPasswordValid ? AppColors.primaryAccent : AppColors.errorRed,
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
                            if (!_isEmailValid || !_doPasswordsMatch) _showErrorText = false;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    // --- REPEAT PASSWORD FIELD ---
                    TextField(
                      controller: _repeatPasswordController,
                      obscureText: true,
                      style: textTheme.bodyLarge?.copyWith(color: AppColors.textHigh),
                      decoration: InputDecoration(
                        labelText: 'repeatPassword'.tr(),
                        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMedium),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        errorText: !_doPasswordsMatch ? 'Passwords must match' : null,
                        filled: true,
                        fillColor: AppColors.cardBackground,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(47),
                          borderSide: BorderSide(
                            color: _doPasswordsMatch ? AppColors.primaryAccent : AppColors.errorRed,
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(47),
                          borderSide: BorderSide(
                            color: _doPasswordsMatch ? AppColors.primaryAccent : AppColors.errorRed,
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
                        if (!_doPasswordsMatch) {
                          setState(() {
                            _doPasswordsMatch = true;
                            if (!_isEmailValid || !_isPasswordValid) _showErrorText = false;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 48),

                    // --- “Take Control” outlined button (47px radius, centered) ---
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
                          onPressed: _attemptSubmit,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),

              // --- Close (“X”) icon at top-right to dismiss ---
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close,
                    size: 28,
                    color: AppColors.textHigh,
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

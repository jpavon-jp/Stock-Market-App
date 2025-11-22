/*
  signup_screen.dart – User Registration Screen

  • ConsumerStatefulWidget + Riverpod:
      – Uses ConsumerStatefulWidget to access Riverpod providers (authServiceProvider, userProvider).
      – On successful signup, writes AppUser into userProvider and navigates to HomeScreen.

  • Form fields & controllers:
      – _nameController, _emailController, _phoneController, _passwordController, _countryController.
      – _dialCode auto‐populated from _determineCountryFromLocation() via Geolocator + Geocoding.
      – _countryController is readOnly once fetched.

  • Country & Dial Code:
      – On initState, schedules a post‐frame callback to:
          • Request location permission.
          • Fetch current Position.
          • Reverse‐geocode to Placemark to extract country name.
          • Look up dial code from a built‐in map.
      – Populates the country text field and prefix for the phone number.

  • Validation flags & error handling:
      – Boolean flags (_isNameValid, _isEmailValid, etc.) control per‐field errorText.
      – _showErrorText toggles a generic “fill in all fields” message.
      – _error captures FirebaseAuthException messages to display below the title.

  • _submit():
      – Shows loading spinner.
      – Calls authServiceProvider.signUp(...) passing name, country, email, password, phone with dial code.
      – On success:
          • Stores AppUser (uid, name, country) in userProvider.
          • Navigates to HomeScreen.
      – On FirebaseAuthException: captures and displays the error message.
      – Finally hides the loading spinner.

  • build():
      – Full‐screen gradient background using AppColors.backgroundGradient.
      – SingleChildScrollView for keyboard avoidance.
      – Logo and “Sign Up” title, with conditional error messages and loading spinner.
      – Five TextFields (Name, Email, Phone with prefix, Password, Country readOnly), each:
          • 47px borderRadius, filled with cardBackground, colored border on error or focus.
      – “Or sign up with” centered text + social sign‐up pill with Apple/Google/Facebook icons.
      – “Take Control” outlined button (47px radius) that triggers _submit().
      – Top‐right “X” to dismiss with Navigator.pop().
*/


import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/user_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../providers/auth_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/app_user.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  static const String routeName = '/signup';
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}


class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  // Controllers for the three text fields
  final _formKey      = GlobalKey<FormState>();
  final TextEditingController _nameController    = TextEditingController();
  final TextEditingController _emailController    = TextEditingController();
  final TextEditingController _phoneController    = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _countryController    = TextEditingController();

  bool  _loading = false;
  String? _error;


  // Validation flags
  bool _showErrorText   = false;
  bool _isNameValid    = true;
  bool _isEmailValid    = true;
  bool _isPhoneValid    = true;
  bool _isPasswordValid = true;
  bool _isCountryValid = true;

  String _dialCode = '';

  // A minimal dial‐code lookup. You can expand this as needed.
  static const Map<String, String> _countryDialCodes = {
    // Current entries
    'Germany'        : '+49',
    'United States'  : '+1',
    'France'         : '+33',
    'United Kingdom' : '+44',

    // EU members
    'Austria'        : '+43',
    'Belgium'        : '+32',
    'Bulgaria'       : '+359',
    'Croatia'        : '+385',
    'Cyprus'         : '+357',
    'Czech Republic' : '+420',
    'Denmark'        : '+45',
    'Estonia'        : '+372',
    'Finland'        : '+358',
    'Greece'         : '+30',
    'Hungary'        : '+36',
    'Ireland'        : '+353',
    'Italy'          : '+39',
    'Latvia'         : '+371',
    'Lithuania'      : '+370',
    'Luxembourg'     : '+352',
    'Malta'          : '+356',
    'Netherlands'    : '+31',
    'Poland'         : '+48',
    'Portugal'       : '+351',
    'Romania'        : '+40',
    'Slovakia'       : '+421',
    'Slovenia'       : '+386',
    'Spain'          : '+34',
    'Sweden'         : '+46',
  };




  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _countryController.dispose();
    super.dispose();
  }


  Future<void> _determineCountryFromLocation() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return; // user refused
    }
    if (perm == LocationPermission.deniedForever) {
      // permissions are permanently denied, handle gracefully
      return;
    }

    // got permission, now get current position
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    );

    // reverse geocode to get a Placemark list
    final List<Placemark> places = await placemarkFromCoordinates(
      pos.latitude,
      pos.longitude,
    );
    final country = places.first.country ?? '';

    // update the form field
    setState(() {
      _countryController.text = country;
      _isCountryValid = country.isNotEmpty;
      _dialCode = _countryDialCodes[country] ?? '';
    });
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      final firebaseUser = await ref.read(authServiceProvider).signUp(
        name: _nameController.text,
        country: _countryController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phone: '$_dialCode${_phoneController.text}',
      );

      final appUser = AppUser(
        uid:     firebaseUser!.uid,
        name:    _nameController.text.trim(),
        country: _countryController.text.trim(),
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
  void initState() {
    super.initState();

    // … your existing setup (controllers, etc.)

    // AFTER the first frame, try to fill in the country
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _determineCountryFromLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // Transparent so gradient covers entire view
      backgroundColor: Colors.transparent,
      body: Container(
        key: _formKey,
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
              // Main scrollable content
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // --- LOGO (centered) ---
                    Center(
                      child: Image.asset(
                        'assets/images/tradion_dark.png',
                        width: 120,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 1),

                    // --- “Sign Up” Title (centered) ---
                    Center(
                      child: Text(
                        'signUp'.tr(),
                        style: textTheme.headlineMedium?.copyWith(
                          color: AppColors.textHigh,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // If error, show message under title
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
                    // Firebase specific error
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

// Loading spinner
                    if (_loading) ...[
                      const SizedBox(height: 16),
                      const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryAccent,
                        ),
                      ),
                    ],


                    //NAME FIELD
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      //keyboardType: TextInputType.emailAddress,
                      style: textTheme.bodyLarge
                          ?.copyWith(color: AppColors.textHigh),
                      decoration: InputDecoration(
                        labelText: 'name'.tr(),
                        labelStyle: textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textMedium),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        errorText: !_isNameValid ? 'enterName'.tr() : null,
                        filled: true,
                        fillColor: AppColors.cardBackground,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(47),
                          borderSide: BorderSide(
                            color: _isNameValid
                                ? AppColors.primaryAccent
                                : AppColors.errorRed,
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(47),
                          borderSide: BorderSide(
                            color: _isNameValid
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
                        if (!_isNameValid) {
                          setState(() {
                            _isNameValid = true;
                            if ((!_isPhoneValid || !_isPasswordValid || !_isEmailValid || !_isCountryValid) &&
                                !_showErrorText) {
                              _showErrorText = false;
                            }
                          });
                        }
                      },
                    ),

                    // --- EMAIL FIELD (47px radius) ---
                    const SizedBox(height: 10),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: textTheme.bodyLarge
                          ?.copyWith(color: AppColors.textHigh),
                      decoration: InputDecoration(
                        labelText: 'email'.tr(),
                        labelStyle: textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textMedium),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        errorText: !_isEmailValid ? 'enterEmail'.tr() : null,
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
                            if ((!_isPhoneValid || !_isPasswordValid || !_isNameValid || !_isCountryValid) &&
                                !_showErrorText) {
                              _showErrorText = false;
                            }
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 10),

                    // --- PHONE NUMBER FIELD (47px radius) ---
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ], // only allow digits
                      style: textTheme.bodyLarge
                          ?.copyWith(color: AppColors.textHigh),
                      decoration: InputDecoration(
                        labelText: 'phoneNumber'.tr(),
                        labelStyle: textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textMedium),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        errorText: !_isPhoneValid
                            ? 'enterPhoneNumber'.tr()
                            : null,

                        // ← here’s the magic: non-editable prefix
                        prefixText: '$_dialCode ',
                        prefixStyle: textTheme.bodyLarge
                            ?.copyWith(color: AppColors.textHigh),

                        filled: true,
                        fillColor: AppColors.cardBackground,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(47),
                          borderSide: BorderSide(
                            color: _isPhoneValid
                                ? AppColors.primaryAccent
                                : AppColors.errorRed,
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(47),
                          borderSide: BorderSide(
                            color: _isPhoneValid
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
                        if (!_isPhoneValid) {
                          setState(() {
                            _isPhoneValid = true;
                            if ((!_isEmailValid || !_isPasswordValid || !_isNameValid || !_isCountryValid) &&
                                !_showErrorText) {
                              _showErrorText = false;
                            }
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 10),

                    // --- PASSWORD FIELD (47px radius) ---
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: textTheme.bodyLarge
                          ?.copyWith(color: AppColors.textHigh),
                      decoration: InputDecoration(
                        labelText: 'password'.tr(),
                        labelStyle: textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textMedium),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        errorText: !_isPasswordValid
                            ? 'enterPassword'.tr()
                            : null,
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
                            if ((!_isEmailValid || !_isPhoneValid || !_isNameValid || !_isCountryValid) &&
                                !_showErrorText) {
                              _showErrorText = false;
                            }
                          });
                        }
                      },
                    ),
                    //COUNTRY/REGION  FIELD
                    const SizedBox(height: 10),
                    TextField(
                      controller: _countryController,
                      readOnly: true,                     // user can’t type
                      style: textTheme.bodyLarge
                          ?.copyWith(color: AppColors.textHigh),
                      decoration: InputDecoration(
                        labelText: 'countryRegion'.tr(),
                        labelStyle: textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textMedium),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        errorText: !_isCountryValid
                            ? 'countryRegionValid'.tr()
                            : null,
                        filled: true,
                        fillColor: AppColors.cardBackground,
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(47),
                          borderSide: BorderSide(
                            color: _isCountryValid
                                ? AppColors.primaryAccent
                                : AppColors.errorRed,
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(47),
                          borderSide: BorderSide(
                            color: _isCountryValid
                                ? AppColors.primaryAccent
                                : AppColors.errorRed,
                            width: 1.5,
                          ),
                        ),
                        // no focusedBorder, since the field is readOnly
                      ),
                      cursorColor: AppColors.primaryAccent,
                    ),

                    const SizedBox(height: 10),

                    // --- “or sign up with” text (centered) ---
                    Center(
                      child: Text(
                        'signInWith'.tr(),
                        style: textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textMedium),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- Social icons in a 47px‐radius container ---
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
                                // TODO: Apple Sign-Up
                              },
                            ),
                            const SizedBox(width: 16),
                            _SocialIconButton(
                              icon: Icons.g_mobiledata,
                              color: Colors.redAccent,
                              onPressed: () {
                                // TODO: Google Sign-Up
                              },
                            ),
                            const SizedBox(width: 16),
                            _SocialIconButton(
                              icon: Icons.facebook,
                              color: Colors.blueAccent,
                              onPressed: () {
                                // TODO: Facebook Sign-Up
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

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
                          onPressed: () {
                            _submit();         // contacts Firebase
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),
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

/// A 48x48 circular icon button for social sign‐up (Apple, Google, Facebook).
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

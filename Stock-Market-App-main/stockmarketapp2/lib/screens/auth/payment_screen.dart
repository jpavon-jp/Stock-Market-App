/*
  payment_screen.dart – In‐App Purchase / Payment Entry Screen

  • StatefulWidget & Form:
    – _PaymentScreenState holds four TextEditingControllers for:
        • Cardholder name
        • Card number
        • CVV
        • Expiration date
    – A GlobalKey<FormState> (_formKey) wraps all TextFormFields for
      synchronous validation on “Buy Now” tap.

  • ExpiryDateTextInputFormatter:
    – Custom TextInputFormatter that:
        1) Strips non‐digits
        2) Inserts a “/” after the first two digits
        3) Limits total to 4 digits (MMYY) via composition with LengthLimitingTextInputFormatter
    – Ensures the expiration field always reads “MM/YY” as the user types.

  • _onBuyNow():
    – Validates the form; if any validator fails, returns early.
    – Calls PurchaseService.setHasPro(true) to record that the user has upgraded.
    – Displays a modal Dialog with:
        • A localized title (“Tradion Pro”)
        • A success icon (check_circle_outline)
        • A localized thank‐you message
        • A “Continue” button that pops the entire stack back to the home screen.

  • _ghostDecoration():
    – Centralizes the InputDecoration for all TextFormFields:
        • Semi‐transparent fill matching cardBackground
        • Rounded borders (24px radius)
        • Colored border on focus (primaryAccent) or default (textMedium)

  • build():
    – Top gradient Container using AppColors.backgroundGradient.
    – SafeArea Column:
        1) Top Row with Back (→ BitcoinScreen) and Close (→ HomeScreen) icons.
        2) Expanded SingleChildScrollView for the payment form:
           • Company logo
           • “Proceed Payment” title
           • Form with four TextFormFields:
               – Name: non‐empty validator
               – Number: min length 12
               – CVV: min length 3
               – Expiry: uses ExpiryDateTextInputFormatter + slash‐required validator
           • Icons for payment methods (Apple, PayPal, Card)
           • “Buy Now” ElevatedButton styled with primaryAccent.
*/

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';
import '../home/bitcoin_screen.dart';
import '../../services/purchase_service.dart';
import 'package:flutter/services.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class ExpiryDateTextInputFormatter extends TextInputFormatter {
  /// Formats input as MM/YY, inserting the slash after two digits.
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    // strip out anything that's not a digit
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();

    for (var i = 0; i < digitsOnly.length && i < 4; i++) {
      // after the month (2 digits), insert a slash
      if (i == 2) buffer.write('/');
      buffer.write(digitsOnly[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      // place the cursor at the end
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _expCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _numberCtrl.dispose();
    _cvvCtrl.dispose();
    _expCtrl.dispose();
    super.dispose();
  }

  Future<void> _onBuyNow() async {
    // 1) Validate
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // 2) Persist that user has purchased Pro
    await PurchaseService.setHasPro(true);

    // 3) Show the styled success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                'tradionPro'.tr(), // e.g. “Tradion Pro”
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primaryAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 16),

              // Success icon
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: AppColors.primaryAccent,
              ),
              const SizedBox(height: 16),

              // Message
              Text(
                'thankYouUpgrade'.tr(), // e.g. “Thank you for upgrading!”
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textHigh,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Pop back to your root/home
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'continue'.tr(), // e.g. “Continue”
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  InputDecoration _ghostDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: AppColors.textMedium),
    filled: true,
    fillColor: AppColors.cardBackground.withAlpha(50),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(color: AppColors.textMedium.withAlpha(80)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(color: AppColors.textMedium.withAlpha(80)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(color: AppColors.primaryAccent),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ─── Top Bar with Back & Close ───────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back → BitcoinScreen
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const BitcoinScreen()),
                      ),
                      splashRadius: 24,
                    ),
                    // Close → HomeScreen (clear stack)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      ),
                      splashRadius: 24,
                    ),
                  ],
                ),
              ),

              // ─── Main Content ────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      // LOGO
                      Image.asset(
                        'assets/images/tradion_dark.png',
                        width: 100,
                        height: 100,
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'proceedPayment'.tr(),
                        style: tt.headlineSmall
                            ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 32),

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: _ghostDecoration('cardholderName'.tr()),
                              validator: (v) =>
                              v?.trim().isEmpty ?? true ? 'enterCardName'.tr() : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _numberCtrl,
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                              decoration: _ghostDecoration('cardNumber'.tr()),
                              validator: (v) => (v?.trim().length ?? 0) < 12
                                  ? 'enterValidCard'.tr()
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _cvvCtrl,
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                              decoration: _ghostDecoration('cvv'.tr()),
                              validator: (v) =>
                              (v?.trim().length ?? 0) < 3 ? 'enterCVV'.tr() : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _expCtrl,
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.datetime,
                              decoration: _ghostDecoration('expiration'.tr()),
                              validator: (v) =>
                              (v?.contains('/') ?? false) ? null : 'enterExpiry'.tr(),
                              inputFormatters: [
                                 // only allow digits
                                 FilteringTextInputFormatter.digitsOnly,
                                 // max of 4 digits (MMYY)
                                 LengthLimitingTextInputFormatter(4),
                                 // auto-insert slash
                                 ExpiryDateTextInputFormatter(),
                               ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Payment Method Icons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.apple, color: Colors.white, size: 32),
                            onPressed: () {/* Apple Pay */},
                          ),
                          const SizedBox(width: 24),
                          IconButton(
                            icon: const Icon(Icons.account_balance_wallet,
                                color: Colors.white, size: 32),
                            onPressed: () {/* PayPal */},
                          ),
                          const SizedBox(width: 24),
                          IconButton(
                            icon:
                            const Icon(Icons.credit_card, color: Colors.white, size: 32),
                            onPressed: () {/* Card */},
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),

                      // BUY NOW Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _onBuyNow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                            elevation: 4,
                            shadowColor: AppColors.primaryAccent.withAlpha(80),
                          ),
                          child: Text(
                            'buyNow'.tr(),
                            style: tt.bodyLarge
                                ?.copyWith(color: Colors.white, fontSize: 16),
                          ),
                        ),
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
}

/// A lightweight flag service that uses SharedPreferences to persist
/// whether the user has unlocked the “Pro” (premium) features.
///
/// Keys:
///   • `_keyHasPro` — the SharedPreferences boolean key for the Pro flag.
///
/// Methods:
///   • `hasPro()`
///       – Asynchronously reads the boolean flag from SharedPreferences.
///       – Returns `true` if the user has previously purchased Pro, `false` otherwise.
///
///   • `setHasPro(value)`
///       – Asynchronously writes the boolean flag to SharedPreferences.
///       – Pass `true` to mark the user as having Pro (permanently unlocked),
///         or `false` to revoke it.
///
/// Usage example:
/// ```dart
/// // Check if Pro is unlocked
/// final isPro = await PurchaseService.hasPro();
///
/// // Grant Pro when the user completes purchase
/// await PurchaseService.setHasPro(true);
/// ```
///
/// Notes:
///   • Since SharedPreferences is asynchronous, both methods return `Future`.
///   • This is purely local storage; for real purchase validation you’d
///     integrate with your payment provider and possibly server-side checks.

import 'package:shared_preferences/shared_preferences.dart';

/// A very simple purchase flag service.
/// Uses SharedPreferences under the hood to remember if the user has unlocked Pro.
class PurchaseService {
  static const _keyHasPro = 'has_pro';

  /// Returns true if the user has already bought Pro.
  static Future<bool> hasPro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasPro) ?? false;
  }

  /// Marks the user as having purchased Pro forever.
  static Future<void> setHasPro(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasPro, value);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

// Holds the currently selected Locale. Default to English.
final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));

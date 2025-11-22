// lib/providers/auth_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

/// Nuestro AuthService (envuelve FirebaseAuth + Firestore)
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// STREAM que emite cambios en el estado de auth (User? de firebase_auth)
final authStateProvider = StreamProvider<User?>((ref) {
  // Fíjate en el <User?> para que Riverpod conozca el tipo real
  return ref.watch(authServiceProvider).authChanges;
});

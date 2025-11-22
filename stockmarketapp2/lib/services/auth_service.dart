/*
  AuthService – Firebase Authentication & Firestore Profile

  • Singleton handles:
    – _auth:
      • FirebaseAuth.instance
      • Manages e-mail/password sign-in, sign-up, and auth state
    – _db:
      • FirebaseFirestore.instance
      • Stores and retrieves a “public profile” document per user

  • authChanges:
    – Exposes _auth.authStateChanges() as a Stream<User?>
    – Your AuthGate (in main.dart) listens to this to switch between
      login and home screens automatically when the user signs in or out

  1. signIn(email, password):
    – Calls _auth.signInWithEmailAndPassword()
      • Trims both email and password
    – Returns the Firebase User on success (or null if it fails)

  2. signUp({name, country, email, password, phone?}):
    – Creates an Auth account via createUserWithEmailAndPassword()
    – Updates the new User’s displayName to the provided name
    – Calls upsertProfile() to create/update the Firestore profile document:
        • users/{uid} with fields: name, country, phone (if provided),
          updated timestamp, and an empty favorites list
    – Returns the Firebase User

  3. upsertProfile({uid, name, country, phone?}):
    – Writes to Firestore at users/{uid}
    – Merges with existing data (merge: true) to perform an “upsert”
    – Always sets:
        • name, country (trimmed)
        • updated: server timestamp
        • favorites: empty array (only if missing)
      – Optionally includes phone if non-null/non-empty

  4. getProfile(uid):
    – Fetches the Firestore document at users/{uid}
    – Returns a DocumentSnapshot<Map<String, dynamic>>
    – Used by ProfileScreen and by your Riverpod providers to populate AppUser

  5. signOut():
    – Calls _auth.signOut()
    – Automatically triggers authChanges listeners to show the login screen
*/

//
// One tiny, central wrapper around the two Firebase SDKs your app needs:
//
//   • Firebase **Auth**       → handles e-mail / password credentials
//   • Cloud **Firestore**     → stores an extra “public profile” document
//
// Nothing here is UI-specific; you can call these methods from
// Riverpod Notifiers, Cubits, BLoCs … whatever you like.
//
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // ────────────────────────────────────────────────────────────────────
  // SINGLETON handles
  // ────────────────────────────────────────────────────────────────────
  final FirebaseAuth      _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db   = FirebaseFirestore.instance;

  // Expose the auth-changes stream so your **AuthGate** in main.dart
  // can react to log-ins / log-outs automatically.
  Stream<User?> get authChanges => _auth.authStateChanges();

  // ────────────────────────────────────────────────────────────────────
  // 1.  SIGN-IN  (returns the Firebase [User] on success)
  // ────────────────────────────────────────────────────────────────────
  Future<User?> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email   : email.trim(),
      password: password.trim(),
    );
    return cred.user;                     // may be null if something fails
  }


  // ────────────────────────────────────────────────────────────────────
  // 2.  SIGN-UP
  //     • creates the Auth account
  //     • stores a simple profile document under   users/{uid}
  // ────────────────────────────────────────────────────────────────────
  Future<User?> signUp({
    required String name,
    required String country,
    required String email,
    required String password,
    String?  phone,            // optional extra field
  }) async {
    // ① Auth account ---------------------------------------------------
    final cred = await _auth.createUserWithEmailAndPassword(
      email   : email.trim(),
      password: password.trim(),
    );

    // (purely cosmetic but nice to have)
    await cred.user?.updateDisplayName(name.trim());

    // ② Profile doc ----------------------------------------------------
    await upsertProfile(
      uid     : cred.user!.uid,
      name    : name,
      country : country,
      phone   : phone,
    );

    return cred.user;
  }

  // ────────────────────────────────────────────────────────────────────
  // 3.  UPSERT PROFILE  (can be reused whenever the user edits data)
  // ────────────────────────────────────────────────────────────────────
  Future<void> upsertProfile({
    required String uid,
    required String name,
    required String country,
    String?  phone,
  }) =>
      _db.collection('users').doc(uid).set({
        'name'    : name.trim(),
        'country' : country.trim(),
        if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
        'updated' : FieldValue.serverTimestamp(),
        'favorites': <String>[],
      }, SetOptions(merge: true));   // merge = “upsert”

  // ────────────────────────────────────────────────────────────────────
  // 4.  READ PROFILE  (ProfileScreen / providers call this)
  // ────────────────────────────────────────────────────────────────────
  Future<DocumentSnapshot<Map<String, dynamic>>> getProfile(String uid) =>
      _db.collection('users').doc(uid).get();

  // ────────────────────────────────────────────────────────────────────
  // 5.  SIGN-OUT
  // ────────────────────────────────────────────────────────────────────
  Future<void> signOut() => _auth.signOut();
}


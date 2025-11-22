// lib/services/favorites_service.dart
///
/// A simple, Firestore-backed service to manage the user’s “favorites” (watchlist)
/// entirely in memory with a mirror in the database. Call `init(uid)` once after
/// login to load the list from Firestore; afterwards you can:
///   • Read `FavoritesService.list` to get the current symbols
///   • Call `FavoritesService.isFavorite(symbol)` to check membership
///   • Call `FavoritesService.add(symbol)` or `.remove(symbol)` (or `.toggle(symbol)`)
///     to update both the in-memory set and the Firestore document under `users/{uid}`
///   • Call `FavoritesService.clear()` on logout to wipe the cache.
///
/// Internally:
///   • `_uid` holds the Firestore document ID for the current user.
///   • `_favs` is a `Set<String>` mirroring the `favorites` array in Firestore.
///   • All modifications use Firestore’s `arrayUnion`/`arrayRemove` operations,
///     then update the local `_favs` set so the UI can react immediately.
///
import 'package:cloud_firestore/cloud_firestore.dart';

/// A Firestore-backed favourites service with the same
/// in-memory static API you already use elsewhere.
class FavoritesService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final Set<String> _favs = {};

  static String? _uid;

  /// Call this once after the user signs in (or on app start
  /// if you already have their uid) to load their favourites.
  static Future<void> init(String uid) async {
    _uid = uid;
    final doc = await _db.collection('users').doc(uid).get();
    final raw = doc.data()?['favorites'] as List<dynamic>? ?? [];
    _favs
      ..clear()
      ..addAll(List<String>.from(raw));
  }

  /// Read-only copy of the current in-memory favourites list.
  static List<String> get list => List.unmodifiable(_favs);

  /// Synchronous check whether a symbol is in the in-memory set.
  static bool isFavorite(String symbol) => _favs.contains(symbol);

  /// Adds a symbol both locally *and* to Firestore.
  static Future<void> add(String symbol) async {
    if (_uid == null) return;
    final docRef = _db.collection('users').doc(_uid);
    await docRef.update({
      'favorites': FieldValue.arrayUnion([symbol]),
    });
    _favs.add(symbol);
  }

  /// Removes a symbol both locally *and* in Firestore.
  static Future<void> remove(String symbol) async {
    if (_uid == null) return;
    final docRef = _db.collection('users').doc(_uid);
    await docRef.update({
      'favorites': FieldValue.arrayRemove([symbol]),
    });
    _favs.remove(symbol);
  }

  static void clear() {
    _uid = null;
    _favs.clear();
  }

  /// Toggles membership, updating both local cache & Firestore.
  static Future<void> toggle(String symbol) async {
    if (_favs.contains(symbol)) {
      await remove(symbol);
    } else {
      await add(symbol);
    }
  }
}

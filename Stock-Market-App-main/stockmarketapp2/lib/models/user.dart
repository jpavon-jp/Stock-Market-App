/*
  models/user.dart – User Profile Data Model

  • name    : The user’s display name (e.g., “Jane Doe”), shown throughout the UI.
  • country : The user’s country code or name (e.g., “DE”), used for locale settings
               and regional preferences.
  • uid     : The unique identifier (UID) from Firebase Auth, used to fetch and
               store user-specific data in Firestore or local services.

  This immutable class encapsulates exactly the three fields our app needs
  to represent a logged-in user. By marking each as `final` and `required`,
  we ensure every `User` instance is fully populated and cannot be modified
  after creation, simplifying state management and data consistency.
*/
class User {
  final String name;
  final String country;
  final String uid;

  User({
    required this.name,
    required this.country,
    required this.uid,
  });
}

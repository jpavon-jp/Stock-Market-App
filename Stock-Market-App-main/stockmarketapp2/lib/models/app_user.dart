/*
  models/app_user.dart – Authenticated User Data Model

  • uid     : The unique Firebase user ID (UID), used to identify and fetch
               data for the currently authenticated user throughout the app.

  • name    : The display name of the user, shown in the UI (e.g., “John Doe”).

  • country : The user’s country (e.g., “Germany”), used for locale-specific
               settings, content filtering, or displaying regional information.

  This immutable class holds exactly the core profile fields we need.
  Every field is marked `final` and `required`, ensuring that once an
  AppUser instance is created (for example, after login and profile fetch),
  it cannot be modified and always contains valid values.
  We store and watch AppUser in our Riverpod `userProvider` to reactively
  update the UI whenever the user’s profile changes.
*/

class AppUser {
  final String uid;
  final String name;
  final String country;

  AppUser({
    required this.uid,
    required this.name,
    required this.country,
  });
}

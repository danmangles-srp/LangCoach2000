// coverage:ignore-file — production wrapper over the google_sign_in plugin
// (platform channels, no unit test). The drain loop is covered via the fake
// EmailService in email_queue_handler_test; this class only resolves OAuth
// tokens at runtime.
//
// GoogleSignIn + Play Services own the access-token lifecycle (refresh,
// caching) — we never persist tokens ourselves. The queue handler calls
// [ensureFreshCredentials] per drain on the MAIN isolate only (the background
// workmanager isolate does not register the email handler), so the platform
// channel is always available.

import 'package:google_sign_in/google_sign_in.dart';

import 'package:rivendell/features/report/data/gmail_api_email_service.dart';
import 'package:rivendell/features/report/domain/gmail_credentials.dart';

/// Resolves Gmail OAuth credentials via the google_sign_in plugin. The single
/// source of "is a Google account signed in + what's its current token" for the
/// email feature.
class GoogleSignInService {
  GoogleSignInService()
    : _googleSignIn = GoogleSignIn(scopes: const [GmailApiEmailService.scope]);

  final GoogleSignIn _googleSignIn;

  /// Resolve credentials for a background drain, refreshing the access token if
  /// the cached one is stale. Returns null when no account is signed in (or the
  /// platform refuses) — the queue handler treats that as "not configured" and
  /// leaves items pending.
  Future<GmailCredentials?> ensureFreshCredentials() async {
    try {
      final account =
          await _googleSignIn.signInSilently() ?? _googleSignIn.currentUser;
      return await _credentialsFor(account);
    } on Object {
      // signInSilently can throw if Play Services is unavailable or the user
      // revoked access server-side. Treat as signed-out; the next foreground
      // session re-prompts.
      return null;
    }
  }

  /// Interactive sign-in from the Settings "Sign in with Google" button.
  /// Returns the resolved credentials, or null if the user cancelled.
  Future<GmailCredentials?> signIn() async {
    final account = await _googleSignIn.signIn();
    return _credentialsFor(account);
  }

  /// Sign out the current account. Clears the cached token; subsequent drains
  /// throw EmailNotConfiguredException until the user signs in again.
  Future<void> signOut() => _googleSignIn.signOut();

  /// The currently signed-in account's email, or null. For UI display only —
  /// never used as a credential.
  String? get currentAccountEmail => _googleSignIn.currentUser?.email;

  Future<GmailCredentials?> _credentialsFor(
    GoogleSignInAccount? account,
  ) async {
    if (account == null) return null;
    final auth = await account.authentication;
    final token = auth.accessToken;
    if (token == null) return null;
    return GmailCredentials(emailAddress: account.email, accessToken: token);
  }
}

// Gmail OAuth credentials (FR-1.5.3). The transport-agnostic handle the email
// service + queue handler pass around: the signed-in account's address + a
// freshly-resolved access token authorized for the `gmail.send` scope. Pure
// value type — no platform deps. Tokens are NEVER persisted; the
// GoogleSignIn plugin + Play Services own refresh, and we resolve a fresh token
// per drain so a rotation takes effect without re-enqueueing.

/// A Gmail account + an access token good for `gmail.send`. The access token
/// is short-lived (~1h); callers must resolve it fresh at drain time via the
/// GoogleSignIn service rather than caching it.
class GmailCredentials {
  const GmailCredentials({
    required this.emailAddress,
    required this.accessToken,
  });

  /// The signed-in Gmail address. Used as the `From` envelope + the recipient
  /// default when the user hasn't set an override.
  final String emailAddress;

  /// An OAuth 2.0 access token with the `gmail.send` scope, sent as a Bearer
  /// header to the Gmail REST API.
  final String accessToken;

  @override
  String toString() => 'GmailCredentials($emailAddress)';
}

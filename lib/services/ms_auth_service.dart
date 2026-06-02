import 'package:msal_auth/msal_auth.dart';

class MsAuthService {
  static const String clientId = '8f4255de-a679-47c3-8415-2446db13e41f';
  static const String tenantId = 'f3901143-69d8-4274-a01e-4b269d7e4a36';

  static SingleAccountPca? _pca;

  static Future<SingleAccountPca> _getInstance() async {
    _pca ??= await SingleAccountPca.create(
      clientId: clientId,
      androidConfig: AndroidConfig(
        configFilePath: 'assets/auth_config.json',
        redirectUri:
            'msauth://com.vebol.employee.hr/kCueV98f7QrMBT09jQIUZxsafZY%3D',
      ),
      appleConfig: AppleConfig(
        authority: 'https://login.microsoftonline.com/$tenantId',
        authorityType: AuthorityType.aad,
        broker: Broker.safariBrowser,
      ),
    );
    return _pca!;
  }

  /// Returns the access token, null if the user explicitly cancelled,
  /// or throws [MsalException] on any other failure.
  static Future<String?> signIn() async {
    final pca = await _getInstance();

    // If a cached account exists, try silent auth first (no UI prompt needed).
    try {
      await pca.currentAccount;
      final result = await pca.acquireTokenSilent(
        scopes: ['User.Read'],
      );
      return result.accessToken;
    } on MsalUserCancelException {
      return null;
    } catch (_) {
      // No cached account or silent failed — fall through to interactive.
    }

    // Interactive sign-in. whenRequired won't bother the user if they're
    // already signed in via the MS Authenticator app.
    try {
      final result = await pca.acquireToken(
        scopes: ['User.Read'],
        prompt: Prompt.whenRequired,
      );
      return result.accessToken;
    } on MsalUserCancelException {
      return null; // User tapped Back / cancelled — not an error.
    }
    // Any other MsalException propagates to the caller.
  }

  static Future<void> signOut() async {
    try {
      final pca = await _getInstance();
      await pca.signOut();
      _pca = null; // Reset so the next signIn() re-initialises cleanly.
    } catch (_) {}
  }
}

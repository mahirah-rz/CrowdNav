import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleAuthService {
  
  // flutter build apk --debug --dart-define=GOOGLE_WEB_CLIENT_ID=394906136895-dri4qomlqhdot9e5calae78ulua7ach0.apps.googleusercontent.com
  static const String _definedClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const String _fallbackClientId = '394906136895-dri4qomlqhdot9e5calae78ulua7ach0.apps.googleusercontent.com';

  static String get _webClientId =>
      _definedClientId.isNotEmpty ? _definedClientId : _fallbackClientId;

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email', 'profile'],
    clientId: kIsWeb ? _webClientId : null,
    serverClientId: kIsWeb ? null : _webClientId,
  );

  static Future<AuthResponse?> signInWithGoogle() async {
    if (_webClientId.contains('PASTE_YOUR_WEB_CLIENT_ID')) {
      throw const AuthException(
        'Google Web Client ID is missing. Add your WEB client ID in google_auth_service.dart or build with --dart-define=GOOGLE_WEB_CLIENT_ID=...',
      );
    }

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw const AuthException(
        'Google ID token missing. Check Firebase SHA-1/SHA-256, google-services.json, and Web Client ID.',
      );
    }

    return Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await Supabase.instance.client.auth.signOut();
  }
}

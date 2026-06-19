import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleAuthService {
  static const String _webClientId =
      '394906136895-dri4qomlqhdot9e5calae78ulua7ach0.apps.googleusercontent.com';
      

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email', 'profile'],

    
    clientId: kIsWeb ? _webClientId : null,

    
    serverClientId: kIsWeb ? null : _webClientId,
  );

  static Future<AuthResponse?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;

    if (googleAuth.idToken == null) {
      throw const AuthException(
        'Google ID token missing. Check Web Client ID, Firebase SHA keys, and Google OAuth setup.',
      );
    }

    return Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: googleAuth.idToken!,
      accessToken: googleAuth.accessToken,
    );
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await Supabase.instance.client.auth.signOut();
  }
}
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleAuthService {
  static final _googleSignIn = GoogleSignIn(
    clientId:
        '776668088-eldgkqbfjeq99puemp5mgq260rtlib7m.apps.googleusercontent.com',
  );

  static Future<AuthResponse?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;

    final response = await Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: googleAuth.idToken!,
      accessToken: googleAuth.accessToken,
    );

    return response;
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await Supabase.instance.client.auth.signOut();
  }
}

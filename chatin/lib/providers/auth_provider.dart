import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendlyException implements Exception {
  final String message;
  FriendlyException(this.message);

  @override
  String toString() => message;
}

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _user = _supabase.auth.currentUser;
    _supabase.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      notifyListeners();
    });
  }

  String _getFriendlyErrorMessage(dynamic e) {
    if (e is AuthException) {
      if (e.code == 'user_already_exists') return 'Email ini sudah terdaftar. Silakan login.';
      if (e.code == 'invalid_credentials') return 'Email atau kata sandi salah.';
      return e.message;
    }
    if (e is PostgrestException) {
      return e.message;
    }
    final str = e.toString();
    if (str.startsWith('Exception: ')) return str.substring(11);
    if (str.startsWith('FriendlyException: ')) return str.substring(19);
    return str;
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      
      // If session is null, email confirmation is required (OTP sent)
      return res.session == null;
    } catch (e) {
      throw FriendlyException(_getFriendlyErrorMessage(e));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyRegistrationOtp(String email, String otp) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _supabase.auth.verifyOTP(
        type: OtpType.signup,
        email: email,
        token: otp,
      );
    } catch (e) {
      throw FriendlyException(_getFriendlyErrorMessage(e));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resendOtp(String email) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
    } catch (e) {
      throw FriendlyException(_getFriendlyErrorMessage(e));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      throw FriendlyException(_getFriendlyErrorMessage(e));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(String name, String? avatarUrl) async {
    try {
      _isLoading = true;
      notifyListeners();

      final updates = {'name': name};
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        updates['avatar_url'] = avatarUrl;
      }

      await _supabase.auth.updateUser(
        UserAttributes(data: updates),
      );
      
      // Update local user reference
      _user = _supabase.auth.currentUser;
    } catch (e) {
      throw FriendlyException(_getFriendlyErrorMessage(e));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw FriendlyException(_getFriendlyErrorMessage(e));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================
  // Native Google Sign-In (google_sign_in v7.x)
  // ==========================================
  Future<void> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      final googleSignIn = GoogleSignIn.instance;

      /// 1. Initialize (wajib dipanggil sebelum authenticate)
      ///    Isi serverClientId dengan Web Client ID dari Google Cloud Console
      ///    jika diperlukan untuk mendapatkan idToken di Android.
      await googleSignIn.initialize(
        serverClientId:
            '412247068827-e5t9gk0q221tollr7k1tn0pulehib5tk.apps.googleusercontent.com',
      );

      /// 2. Jalankan flow autentikasi interaktif
      final account = await googleSignIn.authenticate();

      /// 3. Ambil idToken dari authentication
      final auth = account.authentication;
      final idToken = auth.idToken;

      if (idToken == null) {
        throw 'Gagal mendapatkan Google ID Token.';
      }

      /// 4. Kirim ke Supabase Auth
      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } catch (e) {
      if (e.toString().contains('canceled') || 
          e.toString().contains('sign_in_canceled') || 
          e.toString().contains('GoogleSignInExceptionCode.canceled')) {
        // User membatalkan proses login, abaikan error secara diam-diam.
        return;
      }
      throw FriendlyException(_getFriendlyErrorMessage(e));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _supabase.auth.signOut();
      
      // Fix: Also sign out from Google so it prompts for account next time
      try {
        final googleSignIn = GoogleSignIn.instance;
        await googleSignIn.signOut();
      } catch (e) {
        // Ignore Google sign out errors if not previously signed in with Google
      }
    } catch (e) {
      throw FriendlyException(_getFriendlyErrorMessage(e));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

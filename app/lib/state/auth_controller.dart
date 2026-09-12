import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/api_models.dart';
import '../services/api_service.dart';

/// Router gate: true once the user is signed in OR browsing as a guest.
/// Kept outside Riverpod so the GoRouter redirect can read it synchronously
/// without rebuilding the router.
final authGate = ValueNotifier<bool>(false);

/// True only when a real account session exists (not guest mode).
/// Signed-in users are bounced off the login/signup routes; guests are
/// allowed there so they can create an account.
final signedInGate = ValueNotifier<bool>(false);

/// Persists the session token between app launches.
///
/// The default keeps the token in memory only (sign-in is required again on
/// app restart). Swap in a SharedPreferences- or secure-storage-backed
/// implementation here without touching any UI code.
abstract class TokenStore {
  String? read();
  Future<void> write(String token);
  Future<void> clear();
}

class InMemoryTokenStore implements TokenStore {
  String? _token;
  @override
  String? read() => _token;
  @override
  Future<void> write(String token) async => _token = token;
  @override
  Future<void> clear() async => _token = null;
}

final tokenStoreProvider = Provider<TokenStore>((ref) => InMemoryTokenStore());

/// The signed-in user, or null when signed out (guest mode).
class AuthState {
  const AuthState({this.user, this.token, this.isGuest = false});
  final UserProfile? user;
  final String? token;
  final bool isGuest;
  bool get isSignedIn => user != null;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final token = ref.read(tokenStoreProvider).read();
    if (token != null && token.isNotEmpty) {
      // Restore the header immediately; the profile is re-verified lazily by
      // the router via checkSession().
      ref.read(apiServiceProvider).setAuthToken(token);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        authGate.value = true;
        signedInGate.value = true;
      });
      return AuthState(token: token);
    }
    return const AuthState();
  }

  void _apply(AuthResult result) {
    ref.read(tokenStoreProvider).write(result.token);
    ref.read(apiServiceProvider).setAuthToken(result.token);
    state = AuthState(user: result.user, token: result.token);
    authGate.value = true;
    signedInGate.value = true;
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    required String preferredLang,
  }) async {
    final result = await ref
        .read(apiServiceProvider)
        .register(
          email: email,
          password: password,
          fullName: fullName,
          role: role,
          preferredLang: preferredLang,
        );
    _apply(result);
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final result = await ref
        .read(apiServiceProvider)
        .login(email: email, password: password);
    _apply(result);
  }

  /// Re-validates a restored token against the backend.
  /// Returns true when the session is still valid.
  Future<bool> checkSession() async {
    final token = state.token;
    if (token == null) return false;
    try {
      final user = await ref.read(apiServiceProvider).me();
      state = AuthState(user: user, token: token);
      authGate.value = true;
      signedInGate.value = true;
      return true;
    } on DioException {
      await signOut();
      return false;
    }
  }

  void continueAsGuest() {
    ref.read(apiServiceProvider).setAuthToken(null);
    state = const AuthState(isGuest: true);
    authGate.value = true;
    signedInGate.value = false;
  }

  Future<void> signOut() async {
    await ref.read(tokenStoreProvider).clear();
    ref.read(apiServiceProvider).setAuthToken(null);
    state = const AuthState();
    authGate.value = false;
    signedInGate.value = false;
  }
}

final authProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// Human-readable message for any auth/transport failure.
String authErrorMessage(Object error) {
  if (error is DioException) {
    final detail = error.response?.data;
    if (detail is Map && detail['detail'] is String) {
      return detail['detail'] as String;
    }
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
        return 'Cannot reach the SignBridge server. Check the API base URL in Settings.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
  return 'Something went wrong. Please try again.';
}

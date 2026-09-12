import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/api_models.dart';
import '../state/settings_controller.dart';

final apiServiceProvider = Provider<ApiService>(
  (ref) => ApiService(ref.watch(settingsProvider).apiBaseUrl),
);

/// Signals that the caller is signed in as a guest (no account).
class GuestModeException implements Exception {
  const GuestModeException();
  @override
  String toString() => 'Guest mode: not signed in.';
}

class ApiService {
  ApiService(String baseUrl)
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
  final Dio _dio;

  /// Attaches the current bearer token to every request, when signed in.
  void setAuthToken(String? token) {
    _dio.options.headers['Authorization'] =
        (token == null || token.isEmpty) ? null : 'Bearer $token';
  }

  // ------------------------------------------------------------------
  // Authentication
  // ------------------------------------------------------------------
  Future<AuthResult> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    required String preferredLang,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'full_name': fullName,
        'role': role,
        'preferred_lang': preferredLang,
      },
    );
    return AuthResult.fromJson(response.data!);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return AuthResult.fromJson(response.data!);
  }

  Future<UserProfile> me() async {
    final response = await _dio.get<Map<String, dynamic>>('/auth/me');
    return UserProfile.fromJson(response.data!);
  }

  // ------------------------------------------------------------------
  // Translation
  // ------------------------------------------------------------------
  Future<TranslationResult> translateText(String text) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/text-to-isl',
      data: {'text': text},
    );
    return TranslationResult.fromJson(response.data!);
  }

  Future<TranslationResult> translateAudio(File audio) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/speech-to-isl',
      data: FormData.fromMap({
        'audio': await MultipartFile.fromFile(audio.path),
      }),
    );
    return TranslationResult.fromJson(response.data!);
  }

  Future<SkeletalPose> getPose(String endpoint) async {
    final response = await _dio.get<Map<String, dynamic>>(endpoint);
    return SkeletalPose.fromJson(response.data!);
  }
}

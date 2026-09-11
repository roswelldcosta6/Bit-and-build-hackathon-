import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/api_models.dart';
import '../state/settings_controller.dart';

final apiServiceProvider = Provider<ApiService>(
  (ref) => ApiService(ref.watch(settingsProvider).apiBaseUrl),
);

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

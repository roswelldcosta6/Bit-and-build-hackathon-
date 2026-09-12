import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../models/sign_result.dart';

/// Person 2: API service for communicating with the FastAPI backend.
/// Uses dio HTTP client. Provides methods for all backend endpoints.
class ApiService {
  late final Dio _dio;
  String _baseUrl;

  ApiService({String baseUrl = 'http://10.0.2.2:8000'})
      : _baseUrl = baseUrl {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    // Add interceptor for logging in debug mode
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  /// Update the base URL (e.g., after P3 shares deployment URL)
  void setBaseUrl(String url) {
    _baseUrl = url;
    _dio.options.baseUrl = url;
  }

  /// Check backend health
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      debugPrint('Health check failed: ${e.message}');
      return {'status': 'unreachable', 'error': e.message};
    }
  }

  /// Mode B: Send audio bytes to /speech-to-isl
  /// Returns ISLGlossResponse with glosses, clip_ids, animation_sequence
  Future<ISLGlossResponse?> speechToISL({
    required File audioFile,
    String sessionId = 'default',
  }) async {
    try {
      final fileName = p.basename(audioFile.path);
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          audioFile.path,
          filename: fileName,
        ),
        'session_id': sessionId,
      });

      final response = await _dio.post('/speech-to-isl', data: formData);
      return ISLGlossResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('Speech-to-ISL failed: ${e.message}');
      return null;
    }
  }

  /// Mode B: Send text to /text-to-isl
  Future<ISLGlossResponse?> textToISL({
    required String text,
    String? lang,
    String sessionId = 'default',
  }) async {
    try {
      final response = await _dio.post(
        '/text-to-isl',
        queryParameters: {'session_id': sessionId},
        data: {
          'text': text,
          if (lang != null) 'lang': lang,
        },
      );
      return ISLGlossResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('Text-to-ISL failed: ${e.message}');
      return null;
    }
  }

  /// Mode A cloud fallback: Send keypoints to /predict
  Future<PredictResponse?> predictGesture({
    required List<List<double>> keypoints,
  }) async {
    try {
      final response = await _dio.post(
        '/predict',
        data: {'keypoints': keypoints},
      );
      return PredictResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('Gesture prediction failed: ${e.message}');
      return null;
    }
  }

  /// Fetch full ISL vocabulary
  Future<Map<String, dynamic>?> getVocabulary() async {
    try {
      final response = await _dio.get('/vocabulary');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      debugPrint('Vocabulary fetch failed: ${e.message}');
      return null;
    }
  }

  /// Get session history
  Future<List<HistoryItem>> getHistory(String sessionId) async {
    try {
      final response = await _dio.get('/history/$sessionId');
      final data = response.data as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>;
      return items
          .map((item) => HistoryItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      debugPrint('History fetch failed: ${e.message}');
      return [];
    }
  }

  /// Add a history entry (for Mode A on-device translations)
  Future<HistoryItem?> addHistoryEntry({
    required String mode,
    required String inputContent,
    required String outputContent,
    String? detectedLang,
    List<String>? glosses,
    String sessionId = 'default',
  }) async {
    try {
      final response = await _dio.post(
        '/history',
        queryParameters: {'session_id': sessionId},
        data: {
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'mode': mode,
          'input_content': inputContent,
          'output_content': outputContent,
          if (detectedLang != null) 'detected_lang': detectedLang,
          if (glosses != null) 'glosses': glosses,
        },
      );
      return HistoryItem.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('Add history failed: ${e.message}');
      return null;
    }
  }

  /// Get avatar 3D pose data for a specific gloss
  Future<Map<String, dynamic>?> getAvatarPoses(String gloss) async {
    try {
      final response = await _dio.get('/avatar/poses/$gloss');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      debugPrint('Avatar poses failed: ${e.message}');
      return null;
    }
  }

  void dispose() {
    _dio.close();
  }
}

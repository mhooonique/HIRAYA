// lib/core/services/api_service.dart
// Full ApiService with JWT storage, all HTTP verbs, and error handling

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
class ApiService {
  static const _defaultLocalBaseUrl = 'http://localhost/hiraya_api/api/v1/';

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed.endsWith('/') ? trimmed : '$trimmed/';
  }

  static String _resolveBaseUrl() {
    const configured = String.fromEnvironment('HIRAYA_API_BASE_URL', defaultValue: '');
    if (configured.isNotEmpty) {
      return _normalizeBaseUrl(configured);
    }

    return _defaultLocalBaseUrl;
  }

  static const _tokenKey = 'hiraya_jwt';

  final Dio _dio;

  ApiService()
      : _dio = Dio(BaseOptions(
        baseUrl: _resolveBaseUrl(),
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => status != null && status < 500,
        ));

  Future<String?> diagnoseConnection() async {
    try {
      final probe = Dio(BaseOptions(
        baseUrl: _dio.options.baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
        headers: {'Content-Type': 'application/json'},
        validateStatus: (status) => status != null && status < 600,
      ));

      await probe.get('', options: Options(responseType: ResponseType.plain));
      return null;
    } on DioException catch (e) {
      final host = e.requestOptions.uri.host;
      final raw = e.error?.toString();
      final suffix = (raw != null && raw.isNotEmpty) ? ' | $raw' : '';
      return 'API probe failed at $host (${e.type})$suffix';
    } catch (e) {
      return 'API probe failed: $e';
    }
  }

  // ── Token management (shared_preferences → localStorage on web) ─────────────

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<Options> _authOptions() async {
    final token = await getStoredToken();
    return Options(
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
    );
  }

  // ── HTTP Methods ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    bool auth = true,
  }) async {
    final options = auth ? await _authOptions() : Options();
    final res = await _dio.get(
      path,
      queryParameters: queryParams,
      options: options,
    );
    return _parse(res);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final options = auth ? await _authOptions() : Options();
    final res = await _dio.post(path, data: jsonEncode(body), options: options);
    return _parse(res);
  }

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final options = auth ? await _authOptions() : Options();
    final res = await _dio.put(path, data: jsonEncode(body), options: options);
    return _parse(res);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    bool auth = true,
  }) async {
    final options = auth ? await _authOptions() : Options();
    final res = await _dio.delete(path, options: options);
    return _parse(res);
  }

  // ── Response parser ───────────────────────────────────────────────────────────

  Map<String, dynamic> _parse(Response res) {
    if (res.data is Map<String, dynamic>) {
      return res.data as Map<String, dynamic>;
    }
    if (res.data is String) {
      try {
        return jsonDecode(res.data as String) as Map<String, dynamic>;
      } on FormatException {
        throw const FormatException('Non-JSON response received from API');
      }
    }
    return {};
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
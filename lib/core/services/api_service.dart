// lib/core/services/api_service.dart
// Full ApiService with JWT storage, all HTTP verbs, and error handling

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Environment-aware URLs ────────────────────────────────────────────────────
// Override at build time with:
//   flutter run  --dart-define=API_BASE_URL=https://api.hiraya.com/v1/
//   flutter build web --dart-define=API_BASE_URL=https://api.hiraya.com/v1/
// Falls back to local network IP for same-WiFi testing automatically.
class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://fqzjx5pz-80.asse.devtunnels.ms/hiraya_api/api/v1/',
  );

  static const appBaseUrl = String.fromEnvironment(
    'APP_BASE_URL',
    defaultValue: 'https://fqzjx5pz-3000.asse.devtunnels.ms',
  );
}

class ApiService {
  static const _tokenKey = 'hiraya_jwt';

  final Dio _dio;

  ApiService() : _dio = Dio(BaseOptions(
    baseUrl:        AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    // Longer receive timeout to handle base64 KYC document uploads
    receiveTimeout: const Duration(seconds: 60),
    headers:        {'Content-Type': 'application/json'},
    // Treat anything below 500 as a non-throwing response so callers
    // can handle 4xx errors gracefully via res['error'] checks.
    validateStatus: (status) => status != null && status < 500,
  )) {
    // ── Auto-clear token on 401 anywhere in the app ─────────────────────────
    _dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          if (response.statusCode == 401) {
            // Token expired or invalid — clear it so the router
            // redirects to login on the next auth check.
            clearToken();
          }
          handler.next(response);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
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

  // ── HTTP methods ──────────────────────────────────────────────────────────────

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
    if (res.data is String && (res.data as String).isNotEmpty) {
      try {
        return jsonDecode(res.data as String) as Map<String, dynamic>;
      } catch (_) {
        return {'error': 'Invalid server response'};
      }
    }
    return {};
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
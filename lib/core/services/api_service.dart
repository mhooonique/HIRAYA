// lib/core/services/api_service.dart
// Full ApiService with JWT storage, all HTTP verbs, and error handling

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const _baseUrl = 'https://yosef-trilingual-scalably.ngrok-free.dev/hiraya_api/api/v1/';
  static const _tokenKey = 'hiraya_jwt';

  final Dio _dio;
  final FlutterSecureStorage _storage;

  ApiService()
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        )),
        _storage = const FlutterSecureStorage();

  // ── Token management ────────────────────────────────────────────────────────

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getStoredToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
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
      return jsonDecode(res.data as String) as Map<String, dynamic>;
    }
    return {};
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
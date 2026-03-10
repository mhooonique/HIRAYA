import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://localhost/hiraya_api/api/v1';
  static const _storage = FlutterSecureStorage();

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  static Future<void> _attachToken() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  static Future<Response> post(String path, Map<String, dynamic> data,
      {bool auth = false}) async {
    if (auth) await _attachToken();
    return await _dio.post(path, data: data);
  }

  static Future<Response> get(String path, {bool auth = true}) async {
    if (auth) await _attachToken();
    return await _dio.get(path);
  }

  static Future<Response> put(String path, Map<String, dynamic> data) async {
    await _attachToken();
    return await _dio.put(path, data: data);
  }

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }
}
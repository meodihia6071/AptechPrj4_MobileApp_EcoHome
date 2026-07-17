import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_config.dart';
import 'auth_session.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthApi {
  AuthApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> login({
    required String identityNumber,
    required String password,
  }) async {
    late final http.Response response;
    try {
      response = await _post('/Accounts/authenticate', {
        'identityNumber': identityNumber,
        'password': password,
      });
    } on ApiException {
      throw const ApiException('Sai số căn cước hoặc mật khẩu.');
    }
    final account = _jsonObject(response.body);
    AuthSession.save(account);
    return account;
  }

  Future<String> checkAccount(String identityNumber) async {
    final response = await _get('/Accounts/checkAccount/$identityNumber');
    final body = response.body.trim();
    if (body.isEmpty) {
      throw const ApiException('Không tìm thấy email của tài khoản.');
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is String && decoded.trim().isNotEmpty) {
        return decoded.trim();
      }
    } on FormatException {
      // Backend may return the email as plain text instead of a JSON string.
    }

    final email = body.replaceAll('"', '').trim();
    if (email.isEmpty) {
      throw const ApiException('Không tìm thấy email của tài khoản.');
    }
    return email;
  }

  Future<void> requestOtp(String email) async {
    await _get('/Accounts/requestOtp/${Uri.encodeComponent(email)}');
  }

  Future<void> verifyOtp({required String email, required String otp}) async {
    await _post('/Accounts/verifyOtp', {'email': email, 'otp': otp});
  }

  Future<void> setPassword({
    required String identityNumber,
    required String email,
    required String password,
  }) async {
    await _post('/Accounts/setPwd', {
      'identityNumber': identityNumber,
      'email': email,
      'password': password,
    });
  }

  Future<http.Response> _get(String path) async {
    try {
      final response = await _client
          .get(Uri.parse('${ApiConfig.baseUrl}$path'))
          .timeout(const Duration(seconds: 20));
      return _validate(response);
    } catch (error) {
      if (error is ApiException) rethrow;
      throw const ApiException('Không thể kết nối máy chủ. Vui lòng thử lại.');
    }
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}$path'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
      return _validate(response);
    } catch (error) {
      if (error is ApiException) rethrow;
      throw const ApiException('Không thể kết nối máy chủ. Vui lòng thử lại.');
    }
  }

  http.Response _validate(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }
    var message = response.body.trim();
    try {
      final decoded = jsonDecode(message);
      if (decoded is Map && decoded['message'] != null) {
        message = decoded['message'].toString();
      } else if (decoded is String) {
        message = decoded;
      }
    } catch (_) {}
    throw ApiException(message.isEmpty ? 'Yêu cầu không thành công.' : message);
  }

  Map<String, dynamic> _jsonObject(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Dữ liệu máy chủ không hợp lệ.');
    }
    return decoded;
  }
}

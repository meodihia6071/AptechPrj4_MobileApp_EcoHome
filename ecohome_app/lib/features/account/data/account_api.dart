import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_config.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/data/auth_session.dart';
import 'account_profile.dart';

class AccountApi {
  AccountApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<AccountProfile> getCurrentAccount() async {
    final accountId = AuthSession.accountId;
    final token = AuthSession.token;
    if (accountId == null || token == null) {
      throw const ApiException('Phiên đăng nhập không hợp lệ.');
    }

    try {
      final response = await _client
          .get(
            Uri.parse('${ApiConfig.baseUrl}/Accounts/$accountId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          response.statusCode == 401
              ? 'Phiên đăng nhập đã hết hạn.'
              : 'Không thể tải thông tin tài khoản.',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const ApiException('Dữ liệu tài khoản không hợp lệ.');
      }
      return AccountProfile.fromJson(Map<String, dynamic>.from(decoded));
    } catch (error) {
      if (error is ApiException) rethrow;
      throw const ApiException('Không thể kết nối máy chủ. Vui lòng thử lại.');
    }
  }
}

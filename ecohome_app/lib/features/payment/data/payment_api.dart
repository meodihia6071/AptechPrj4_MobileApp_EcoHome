import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_config.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/data/auth_session.dart';
import 'payment_invoice.dart';

class PaymentApi {
  PaymentApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<PaymentInvoice>> getMyInvoices() async {
    final response = await _request(
      () => _client.get(
        Uri.parse('${ApiConfig.baseUrl}/Payments/my-invoices'),
        headers: _headers,
      ),
    );
    final decoded = jsonDecode(response.body);
    final raw = decoded is List
        ? decoded
        : decoded is Map && decoded[r'$values'] is List
        ? decoded[r'$values'] as List
        : const [];
    return raw
        .whereType<Map>()
        .map((item) => PaymentInvoice.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<CheckoutResult> checkout({
    required List<String> paymentIds,
    required PaymentMethod method,
  }) async {
    final response = await _request(
      () => _client.post(
        Uri.parse('${ApiConfig.baseUrl}/Payments/checkout'),
        headers: _headers,
        body: jsonEncode({
          'paymentIds': paymentIds,
          'paymentMethod': method == PaymentMethod.cash ? 0 : 1,
        }),
      ),
    );
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const ApiException('Dữ liệu thanh toán không hợp lệ.');
    }
    return CheckoutResult.fromJson(Map<String, dynamic>.from(decoded));
  }

  Map<String, String> get _headers {
    final token = AuthSession.token;
    if (token == null || token.isEmpty) {
      throw const ApiException('Phiên đăng nhập không hợp lệ.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _request(
    Future<http.Response> Function() action,
  ) async {
    try {
      final response = await action().timeout(const Duration(seconds: 20));
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
      if (response.statusCode == 401) {
        message = 'Phiên đăng nhập đã hết hạn.';
      }
      throw ApiException(
        message.isEmpty ? 'Yêu cầu thanh toán không thành công.' : message,
      );
    } catch (error) {
      if (error is ApiException) rethrow;
      throw const ApiException('Không thể kết nối máy chủ. Vui lòng thử lại.');
    }
  }
}

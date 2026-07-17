import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_config.dart';
import '../../apartment/data/apartment_api.dart';
import '../../apartment/data/apartment_info.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/data/auth_session.dart';
import 'rent_invoice.dart';

class RentInvoiceApi {
  RentInvoiceApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<RentInvoice>> getPendingRentInvoices() async {
    final now = DateTime.now();
    if (now.day > 10) return const [];

    final residentId = AuthSession.residentId;
    final token = AuthSession.token;
    if (residentId == null || token == null) {
      throw const ApiException('Phiên đăng nhập không hợp lệ.');
    }

    final apartments = await ApartmentApi(client: _client).getApartments();
    final rentals = apartments
        .where((item) => item.contractType == ContractType.rental)
        .toList();
    if (rentals.isEmpty) return const [];

    final payments = await _getResidentPayments(residentId, token);
    final usedPayments = <int>{};
    final pending = <RentInvoice>[];

    for (final apartment in rentals) {
      final paymentIndex = _findCurrentRentPayment(
        payments,
        apartment,
        now,
        usedPayments,
        rentals.length == 1,
      );
      if (paymentIndex != null) {
        usedPayments.add(paymentIndex);
        continue;
      }
      pending.add(
        RentInvoice(
          roomNumber: apartment.roomNumber,
          amount: apartment.primaryAmount,
          deadline: DateTime(now.year, now.month, 10),
          daysRemaining: 10 - now.day,
        ),
      );
    }
    return pending;
  }

  Future<List<Map<String, dynamic>>> _getResidentPayments(
    String residentId,
    String token,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/Payments/filter'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'conditions': [
                {'key': 'ResidentId', 'guidValue': residentId},
              ],
              'sortName': 'PaymentDate',
              'sortMethod': 'DESC',
              'page': 0,
              'limit': 100,
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          response.statusCode == 401
              ? 'Phiên đăng nhập đã hết hạn.'
              : 'Không thể tải hóa đơn thanh toán.',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return const [];
      return _asList(decoded['results']);
    } catch (error) {
      if (error is ApiException) rethrow;
      throw const ApiException('Không thể tải hóa đơn thanh toán.');
    }
  }

  int? _findCurrentRentPayment(
    List<Map<String, dynamic>> payments,
    ApartmentInfo apartment,
    DateTime now,
    Set<int> usedPayments,
    bool isOnlyRental,
  ) {
    for (var index = 0; index < payments.length; index++) {
      if (usedPayments.contains(index)) continue;
      final payment = payments[index];
      final paidAt = DateTime.tryParse(
        payment['paymentDate']?.toString() ?? '',
      );
      if (paidAt == null ||
          paidAt.year != now.year ||
          paidAt.month != now.month) {
        continue;
      }
      final amount = double.tryParse(payment['amount']?.toString() ?? '') ?? -1;
      if ((amount - apartment.primaryAmount).abs() > .01) continue;

      final text = '${payment['title'] ?? ''} ${payment['description'] ?? ''}'
          .toLowerCase();
      final mentionsRoom = text.contains(apartment.roomNumber.toLowerCase());
      final mentionsRent = text.contains('thuê') || text.contains('thue');
      if (mentionsRoom || mentionsRent || isOnlyRental) return index;
    }
    return null;
  }

  List<Map<String, dynamic>> _asList(dynamic value) {
    final raw = value is List
        ? value
        : value is Map && value[r'$values'] is List
        ? value[r'$values'] as List
        : const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}

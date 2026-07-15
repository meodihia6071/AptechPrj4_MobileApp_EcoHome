import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_config.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/data/auth_session.dart';
import 'apartment_info.dart';

class ApartmentApi {
  ApartmentApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<ApartmentInfo> getCurrentApartment() async {
    final accountId = AuthSession.accountId;
    if (accountId == null || accountId.isEmpty) {
      throw const ApiException(
        'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.',
      );
    }

    final residentFilter = await _post('/Residents/filter', {
      'conditions': [
        {'key': 'AccountId', 'guidValue': accountId},
      ],
      'sortName': 'ModifiedDate',
      'sortMethod': 'DESC',
      'page': 0,
      'limit': 20,
    });
    final residents = _asList(residentFilter['results']);
    if (residents.isEmpty) {
      throw const ApiException(
        'Tài khoản chưa được liên kết với hồ sơ cư dân.',
      );
    }

    final residentId = residents.first['residentId']?.toString();
    if (residentId == null) {
      throw const ApiException('Không tìm thấy mã cư dân.');
    }
    final resident = await _get('/Residents/$residentId');
    final contractResidents = _asList(resident['contractResidents']);
    if (contractResidents.isEmpty) {
      throw const ApiException('Cư dân chưa có hợp đồng căn hộ.');
    }

    // Backend hiện chưa đánh dấu hợp đồng mặc định; dùng hợp đồng đầu tiên còn hiệu lực.
    final contractId = contractResidents.first['contractId']?.toString();
    if (contractId == null) {
      throw const ApiException('Không tìm thấy hợp đồng căn hộ.');
    }
    final contract = await _get('/Contracts/$contractId');
    final apartment = _asMap(contract['apartment']);
    if (apartment.isEmpty) {
      throw const ApiException('Hợp đồng chưa được liên kết với căn hộ.');
    }
    return _mapInfo(contract, apartment);
  }

  ApartmentInfo _mapInfo(
    Map<String, dynamic> contract,
    Map<String, dynamic> apartment,
  ) {
    final typeIndex = _toInt(contract['type']);
    final type = ContractType.values[typeIndex.clamp(0, 2)];
    final rentPrice = _toDouble(apartment['rentPrice']);
    final buyPrice = _toDouble(apartment['buyPrice']);
    final initialPayment = _toDouble(contract['initialPayment']);
    final loanAmount = _toDouble(contract['loanAmount']);
    final months = _toDouble(contract['installmentMonth']);
    final startDate = DateTime.tryParse(
      contract['startDate']?.toString() ?? '',
    );

    switch (type) {
      case ContractType.cash:
        return ApartmentInfo(
          roomNumber: apartment['roomNumber']?.toString() ?? '--',
          floor: _toInt(apartment['floor']),
          area: _toDouble(apartment['area']),
          contractType: type,
          primaryAmount: buyPrice,
          primaryLabel: 'Đã thanh toán mua căn hộ',
          pictureUrl: apartment['pictureUrl']?.toString(),
        );
      case ContractType.installment:
        return ApartmentInfo(
          roomNumber: apartment['roomNumber']?.toString() ?? '--',
          floor: _toInt(apartment['floor']),
          area: _toDouble(apartment['area']),
          contractType: type,
          primaryAmount: initialPayment,
          primaryLabel: 'Đã thanh toán trước',
          secondaryAmount: months > 0 ? loanAmount / months : loanAmount,
          secondaryLabel: 'Kỳ thanh toán sắp tới',
          nextDueDate: _nextMonthlyDueDate(startDate),
          pictureUrl: apartment['pictureUrl']?.toString(),
        );
      case ContractType.rental:
        return ApartmentInfo(
          roomNumber: apartment['roomNumber']?.toString() ?? '--',
          floor: _toInt(apartment['floor']),
          area: _toDouble(apartment['area']),
          contractType: type,
          primaryAmount: rentPrice,
          primaryLabel: 'Tiền thuê kỳ sắp tới',
          nextDueDate: _nextMonthlyDueDate(startDate),
          pictureUrl: apartment['pictureUrl']?.toString(),
        );
    }
  }

  DateTime? _nextMonthlyDueDate(DateTime? startDate) {
    if (startDate == null) return null;
    final now = DateTime.now();
    var year = now.year;
    var month = now.month;
    final maxDay = DateTime(year, month + 1, 0).day;
    var due = DateTime(year, month, startDate.day.clamp(1, maxDay));
    if (!due.isAfter(now)) {
      month++;
      if (month == 13) {
        month = 1;
        year++;
      }
      due = DateTime(
        year,
        month,
        startDate.day.clamp(1, DateTime(year, month + 1, 0).day),
      );
    }
    return due;
  }

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final response = await _client
          .get(Uri.parse('${ApiConfig.baseUrl}$path'), headers: _headers)
          .timeout(const Duration(seconds: 20));
      return _decode(response);
    } catch (error) {
      if (error is ApiException) rethrow;
      throw const ApiException('Không thể tải thông tin căn hộ.');
    }
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}$path'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
      return _decode(response);
    } catch (error) {
      if (error is ApiException) rethrow;
      throw const ApiException('Không thể tải thông tin căn hộ.');
    }
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (AuthSession.token != null)
      'Authorization': 'Bearer ${AuthSession.token}',
  };

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = response.body.replaceAll('"', '').trim();
      if (response.statusCode == 401) message = 'Phiên đăng nhập đã hết hạn.';
      throw ApiException(message.isEmpty ? 'Không thể tải dữ liệu.' : message);
    }
    final decoded = jsonDecode(response.body);
    return _asMap(decoded);
  }

  Map<String, dynamic> _asMap(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

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

  int _toInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
  double _toDouble(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;
}

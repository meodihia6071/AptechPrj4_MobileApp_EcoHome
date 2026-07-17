import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_config.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/data/auth_session.dart';
import 'apartment_info.dart';

class ApartmentApi {
  ApartmentApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<ApartmentInfo>> getApartments() async {
    final accountId = AuthSession.accountId;
    if (accountId == null || accountId.isEmpty) {
      throw const ApiException(
        'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.',
      );
    }

    final residentId =
        AuthSession.residentId ?? await _findResidentId(accountId);
    final resident = await _get('/Residents/$residentId');
    final contractResidents = _asList(resident['contractResidents']);
    if (contractResidents.isEmpty) {
      throw const ApiException('Cư dân chưa có hợp đồng căn hộ.');
    }

    final seenContracts = <String>{};
    final futures = <Future<ApartmentInfo>>[];
    for (final relation in contractResidents) {
      final contractId = relation['contractId']?.toString();
      if (contractId == null || !seenContracts.add(contractId)) continue;
      futures.add(
        _getApartmentInfo(contractId, _toInt(relation['residentType'])),
      );
    }
    if (futures.isEmpty) {
      throw const ApiException('Không tìm thấy hợp đồng căn hộ.');
    }
    final apartments = await Future.wait(futures);
    apartments.sort((a, b) => a.roomNumber.compareTo(b.roomNumber));
    return apartments;
  }

  Future<String> _findResidentId(String accountId) async {
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
    final residentId = residents.isEmpty
        ? null
        : residents.first['residentId']?.toString();
    if (residentId == null || residentId.isEmpty) {
      throw const ApiException(
        'Tài khoản chưa được liên kết với hồ sơ cư dân.',
      );
    }
    return residentId;
  }

  Future<ApartmentInfo> _getApartmentInfo(
    String contractId,
    int residentType,
  ) async {
    final contract = await _get('/Contracts/$contractId');
    final apartment = _asMap(contract['apartment']);
    if (apartment.isEmpty) {
      throw const ApiException('Hợp đồng chưa được liên kết với căn hộ.');
    }
    return _mapInfo(contract, apartment, residentType);
  }

  ApartmentInfo _mapInfo(
    Map<String, dynamic> contract,
    Map<String, dynamic> apartment,
    int residentType,
  ) {
    final type = _toInt(contract['type']) == 1
        ? ContractType.rental
        : ContractType.cash;
    final rentPrice = _toDouble(apartment['rentPrice']);
    final buyPrice = _toDouble(apartment['buyPrice']);

    switch (type) {
      case ContractType.cash:
        return ApartmentInfo(
          apartmentId: apartment['apartmentId']?.toString() ?? '',
          contractId: contract['contractId']?.toString() ?? '',
          roomNumber: apartment['roomNumber']?.toString() ?? '--',
          floor: _toInt(apartment['floor']),
          area: _toDouble(apartment['area']),
          contractType: type,
          primaryAmount: buyPrice,
          primaryLabel: 'Giá mua căn hộ',
          residentType: residentType,
          pictureUrl: apartment['pictureUrl']?.toString(),
        );
      case ContractType.rental:
        final paymentSchedule = _rentalPaymentSchedule();
        return ApartmentInfo(
          apartmentId: apartment['apartmentId']?.toString() ?? '',
          contractId: contract['contractId']?.toString() ?? '',
          roomNumber: apartment['roomNumber']?.toString() ?? '--',
          floor: _toInt(apartment['floor']),
          area: _toDouble(apartment['area']),
          contractType: type,
          primaryAmount: rentPrice,
          primaryLabel: 'Tiền thuê hàng tháng',
          residentType: residentType,
          nextDueDate: paymentSchedule.deadline,
          paymentCountdownDays: paymentSchedule.countdownDays,
          pictureUrl: apartment['pictureUrl']?.toString(),
        );
    }
  }

  ({DateTime deadline, int? countdownDays}) _rentalPaymentSchedule() {
    final now = DateTime.now();
    if (now.day <= 10) {
      return (
        deadline: DateTime(now.year, now.month, 10),
        countdownDays: 10 - now.day,
      );
    }

    final nextMonth = DateTime(now.year, now.month + 1, 10);
    return (deadline: nextMonth, countdownDays: null);
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

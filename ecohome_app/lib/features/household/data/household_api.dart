import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_config.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/data/auth_session.dart';
import 'household_member.dart';

class HouseholdApi {
  HouseholdApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<HouseholdInfo> getHousehold() async {
    final accountId = AuthSession.accountId;
    final token = AuthSession.token;

    if (accountId == null ||
        accountId.isEmpty ||
        token == null ||
        token.isEmpty) {
      throw const ApiException(
        'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.',
      );
    }

    final currentResidentId =
        AuthSession.residentId ?? await _findResidentIdByAccountId(accountId);

    final resident = await _getObject('/Residents/$currentResidentId');
    final currentRelations = _asList(resident['contractResidents']);

    if (currentRelations.isEmpty) {
      throw const ApiException(
        'Cư dân chưa được liên kết với hợp đồng căn hộ.',
      );
    }

    Map<String, dynamic> selectedRelation = currentRelations.first;

    for (final relation in currentRelations) {
      if (_toInt(relation['residentType']) == 0) {
        selectedRelation = relation;
        break;
      }
    }

    final contractId = selectedRelation['contractId']?.toString() ?? '';

    if (contractId.isEmpty) {
      throw const ApiException('Không tìm thấy hợp đồng căn hộ.');
    }

    final contract = await _getObject('/Contracts/$contractId');
    final relations = _asList(contract['contractResidents']);

    final members = relations
        .map(HouseholdMember.fromContractResident)
        .where((member) => member.residentId.isNotEmpty)
        .toList();

    members.sort((first, second) {
      final roleCompare = first.residentType.compareTo(second.residentType);

      if (roleCompare != 0) {
        return roleCompare;
      }

      return first.name.toLowerCase().compareTo(second.name.toLowerCase());
    });

    return HouseholdInfo(contractId: contractId, members: members);
  }

  Future<void> addMember({
    required String contractId,
    required String identityNumber,
    required int residentType,
  }) async {
    final normalizedIdentity = identityNumber.trim();

    if (!RegExp(r'^\d{12}$').hasMatch(normalizedIdentity)) {
      throw const ApiException('Số căn cước phải gồm đúng 12 chữ số.');
    }

    if (residentType < 1 || residentType > 3) {
      throw const ApiException('Vai trò thành viên không hợp lệ.');
    }

    final accountResult = await _postObject('/Accounts/filter', {
      'conditions': [
        {'key': 'IdentityNumber', 'value': normalizedIdentity},
      ],
      'sortName': 'ModifiedDate',
      'sortMethod': 'DESC',
      'page': 0,
      'limit': 20,
    });

    final accounts = _asList(accountResult['results']);

    if (accounts.isEmpty) {
      throw const ApiException('Không tìm thấy tài khoản có số căn cước này.');
    }

    final accountId = accounts.first['accountId']?.toString() ?? '';

    if (accountId.isEmpty) {
      throw const ApiException('Tài khoản không hợp lệ.');
    }

    final residentId = await _findResidentIdByAccountId(accountId);
    final contract = await _getObject('/Contracts/$contractId');
    final currentMembers = _asList(contract['contractResidents']);

    final alreadyExists = currentMembers.any(
      (relation) => relation['residentId']?.toString() == residentId,
    );

    if (alreadyExists) {
      throw const ApiException('Cư dân này đã có trong hộ gia đình.');
    }

    final now = DateTime.now().toIso8601String();

    await _postAny('/Contracts/addResidentToContract', {
      'contractId': contractId,
      'residentId': residentId,
      'residentType': residentType,
      'createdDate': now,
      'modifiedDate': now,
      'isDeleted': false,
    });
  }

  Future<String> _findResidentIdByAccountId(String accountId) async {
    final residentResult = await _postObject('/Residents/filter', {
      'conditions': [
        {'key': 'AccountId', 'guidValue': accountId},
      ],
      'sortName': 'ModifiedDate',
      'sortMethod': 'DESC',
      'page': 0,
      'limit': 20,
    });

    final residents = _asList(residentResult['results']);
    final residentId = residents.isEmpty
        ? ''
        : residents.first['residentId']?.toString() ?? '';

    if (residentId.isEmpty) {
      throw const ApiException('Tài khoản này chưa có hồ sơ cư dân.');
    }

    return residentId;
  }

  Future<Map<String, dynamic>> _getObject(String path) async {
    final decoded = await _request(
      () => _client.get(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: _headers,
      ),
    );

    if (decoded is! Map) {
      throw const ApiException('Dữ liệu máy chủ không hợp lệ.');
    }

    return Map<String, dynamic>.from(decoded);
  }

  Future<Map<String, dynamic>> _postObject(
    String path,
    Map<String, dynamic> body,
  ) async {
    final decoded = await _request(
      () => _client.post(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: _headers,
        body: jsonEncode(body),
      ),
    );

    if (decoded is! Map) {
      throw const ApiException('Dữ liệu máy chủ không hợp lệ.');
    }

    return Map<String, dynamic>.from(decoded);
  }

  Future<void> _postAny(String path, Map<String, dynamic> body) async {
    await _request(
      () => _client.post(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: _headers,
        body: jsonEncode(body),
      ),
    );
  }

  Future<dynamic> _request(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(_errorMessage(response));
      }

      final body = response.body.trim();

      if (body.isEmpty) {
        return null;
      }

      try {
        return jsonDecode(body);
      } on FormatException {
        return body;
      }
    } catch (error) {
      if (error is ApiException) rethrow;

      throw const ApiException('Không thể kết nối máy chủ.');
    }
  }

  String _errorMessage(http.Response response) {
    if (response.statusCode == 401) {
      return 'Phiên đăng nhập đã hết hạn.';
    }

    final body = response.body.trim();

    if (body.isEmpty) {
      return 'Yêu cầu không thành công.';
    }

    try {
      final decoded = jsonDecode(body);

      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }

      if (decoded is String) {
        return decoded;
      }
    } catch (_) {}

    return body.replaceAll('"', '');
  }

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      if (AuthSession.token != null)
        'Authorization': 'Bearer ${AuthSession.token}',
    };
  }

  List<Map<String, dynamic>> _asList(dynamic value) {
    final rawList = value is List
        ? value
        : value is Map && value[r'$values'] is List
        ? value[r'$values'] as List
        : const [];

    return rawList
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  int _toInt(dynamic value) {
    return int.tryParse(value?.toString() ?? '') ?? -1;
  }
}

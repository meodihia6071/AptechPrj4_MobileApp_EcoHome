import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_config.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/data/auth_session.dart';
import 'incident_item.dart';

class IncidentApi {
  IncidentApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  ResidentIncidentContext? _cachedContext;

  /// Không dùng POST /Incidents/filter nữa.
  ///
  /// Backend có IncidentDL.FilterData riêng nên kết quả lọc có thể
  /// không ổn định. Ta lấy danh sách rồi lọc theo ReportedBy ở Flutter.
  Future<List<IncidentItem>> getMyIncidents() async {
    final context = await _resolveContext();
    final response = await _get('/Incidents');

    final incidents = _asList(response)
        .map(IncidentItem.fromJson)
        .where(
          (incident) =>
              incident.incidentId.isNotEmpty &&
              !incident.isDeleted &&
              incident.reportedBy.toLowerCase() ==
                  context.residentId.toLowerCase(),
        )
        .toList();

    incidents.sort((first, second) {
      final firstDate =
          first.modifiedDate ?? first.createdDate ?? DateTime(1970);

      final secondDate =
          second.modifiedDate ?? second.createdDate ?? DateTime(1970);

      return secondDate.compareTo(firstDate);
    });

    return incidents;
  }

  Future<void> createIncident({
    required String title,
    required String description,
  }) async {
    final context = await _resolveContext();
    final now = DateTime.now().toIso8601String();

    await _post('/Incidents', {
      'apartmentId': context.apartmentId,
      'reportedBy': context.residentId,
      'description': IncidentItem.composeDescription(
        title: title,
        description: description,
      ),
      'resolvedDescription': null,
      'closedDescription': null,
      'cancelDescription': null,
      'status': 0,
      'createdDate': now,
      'modifiedDate': now,
      'isDeleted': false,
    });
  }

  Future<void> cancelIncident(IncidentItem incident) async {
    if (!incident.canCancel) {
      throw const ApiException(
        'Chỉ có thể thu hồi báo cáo đang ở trạng thái mới.',
      );
    }

    await _put(
      '/Incidents/${incident.incidentId}',
      incident.toUpdateJson(
        newStatus: 5,
        newCancelDescription: 'Cư dân đã chủ động thu hồi báo cáo.',
      ),
    );
  }

  Future<ResidentIncidentContext> _resolveContext() async {
    final cached = _cachedContext;

    if (cached != null) {
      return cached;
    }

    final token = AuthSession.token;
    final accountId = AuthSession.accountId;

    if (token == null ||
        token.isEmpty ||
        accountId == null ||
        accountId.isEmpty) {
      throw const ApiException(
        'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.',
      );
    }

    final residentId =
        AuthSession.residentId ?? await _findResidentId(accountId);

    final resident = _asMap(await _get('/Residents/$residentId'));

    final relations = _asList(resident['contractResidents']);

    if (relations.isEmpty) {
      throw const ApiException(
        'Cư dân chưa được liên kết với hợp đồng căn hộ.',
      );
    }

    Map<String, dynamic> selectedRelation = relations.first;

    for (final relation in relations) {
      final residentType =
          int.tryParse(relation['residentType']?.toString() ?? '') ?? -1;

      if (residentType == 0) {
        selectedRelation = relation;
        break;
      }
    }

    final contractId = selectedRelation['contractId']?.toString() ?? '';

    if (contractId.isEmpty) {
      throw const ApiException('Không tìm thấy hợp đồng của cư dân.');
    }

    final contract = _asMap(await _get('/Contracts/$contractId'));

    final apartmentId = contract['apartmentId']?.toString() ?? '';

    if (apartmentId.isEmpty) {
      throw const ApiException('Không tìm thấy căn hộ của cư dân.');
    }

    final result = ResidentIncidentContext(
      residentId: residentId,
      apartmentId: apartmentId,
    );

    _cachedContext = result;
    return result;
  }

  Future<String> _findResidentId(String accountId) async {
    final response = _asMap(
      await _post('/Residents/filter', {
        'conditions': [
          {'key': 'AccountId', 'guidValue': accountId},
        ],
        'sortName': 'ModifiedDate',
        'sortMethod': 'DESC',
        'page': 0,
        'limit': 20,
      }),
    );

    final residents = _asList(response['results']);

    final residentId = residents.isEmpty
        ? ''
        : residents.first['residentId']?.toString() ?? '';

    if (residentId.isEmpty) {
      throw const ApiException(
        'Tài khoản chưa được liên kết với hồ sơ cư dân.',
      );
    }

    return residentId;
  }

  Future<dynamic> _get(String path) {
    return _request(
      () => _client.get(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: _headers,
      ),
    );
  }

  Future<dynamic> _post(String path, dynamic body) {
    return _request(
      () => _client.post(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: _headers,
        body: jsonEncode(body),
      ),
    );
  }

  Future<dynamic> _put(String path, dynamic body) {
    return _request(
      () => _client.put(
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
      if (error is ApiException) {
        rethrow;
      }

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

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (AuthSession.token != null)
      'Authorization': 'Bearer ${AuthSession.token}',
  };

  Map<String, dynamic> _asMap(dynamic value) {
    return value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asList(dynamic value) {
    dynamic raw = value;

    if (value is Map) {
      if (value[r'$values'] is List) {
        raw = value[r'$values'];
      } else if (value['results'] != null) {
        raw = value['results'];

        if (raw is Map && raw[r'$values'] is List) {
          raw = raw[r'$values'];
        }
      }
    }

    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}

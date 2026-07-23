import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_config.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/data/auth_session.dart';
import 'service_item.dart';

class ServiceApi {
  ServiceApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static final Set<String> _registrationLocks = <String>{};

  Future<ServiceScreenData> getServices() async {
    final residentId = await _currentResidentId();

    final responses = await Future.wait([_get('/Services'), _get('/Bookings')]);

    final services = _asList(responses[0])
        .map(ServiceOverview.fromJson)
        .where((service) => service.serviceId.isNotEmpty)
        .toList();

    final servicesById = <String, ServiceOverview>{
      for (final service in services) service.serviceId.toLowerCase(): service,
    };

    final bookingsById = <String, ServiceBooking>{};

    for (final json in _asList(responses[1])) {
      final booking = ServiceBooking.fromJson(json);

      if (booking.bookingId.isEmpty ||
          booking.serviceId.isEmpty ||
          booking.residentId.toLowerCase() != residentId.toLowerCase() ||
          !booking.isActive) {
        continue;
      }

      bookingsById[booking.bookingId.toLowerCase()] = booking;
    }

    final activeBookings = bookingsById.values.toList()
      ..sort((first, second) {
        final firstDate =
            first.modifiedDate ?? first.startDate ?? DateTime(1970);

        final secondDate =
            second.modifiedDate ?? second.startDate ?? DateTime(1970);

        return secondDate.compareTo(firstDate);
      });

    final registered = <RegisteredServiceItem>[];
    final activeServiceIds = <String>{};

    for (final booking in activeBookings) {
      final service = servicesById[booking.serviceId.toLowerCase()];

      if (service == null) {
        continue;
      }

      registered.add(RegisteredServiceItem(service: service, booking: booking));

      activeServiceIds.add(service.serviceId.toLowerCase());
    }

    final available =
        services
            .where(
              (service) =>
                  !activeServiceIds.contains(service.serviceId.toLowerCase()),
            )
            .toList()
          ..sort(
            (first, second) =>
                first.name.toLowerCase().compareTo(second.name.toLowerCase()),
          );

    return ServiceScreenData(registered: registered, available: available);
  }

  Future<void> registerService({
    required ServiceOverview service,
    required ServiceRegistration registration,
  }) async {
    final residentId = await _currentResidentId();
    final lockKey =
        '${residentId.toLowerCase()}:${service.serviceId.toLowerCase()}';

    if (!_registrationLocks.add(lockKey)) {
      throw const ApiException('Yêu cầu đăng ký đang được xử lý.');
    }

    try {
      final data = await getServices();

      final alreadyRegistered = data.registered.any(
        (item) =>
            item.service.serviceId.toLowerCase() ==
            service.serviceId.toLowerCase(),
      );

      if (alreadyRegistered) {
        throw const ApiException('Dịch vụ này đã có đăng ký đang hoạt động.');
      }

      final now = DateTime.now();
      final nowIso = now.toIso8601String();

      final bookingResponse = await _post('/Bookings', {
        'residentId': residentId,
        'serviceId': service.serviceId,
        'apartmentId': registration.apartmentId,
        'startDate': registration.startDate.toIso8601String(),
        'endDate': registration.endDate.toIso8601String(),
        'status': 0,
        'bookingType': registration.bookingType,
        'createdDate': nowIso,
        'modifiedDate': nowIso,
        'isDeleted': false,
      });

      final bookingId = _extractGuid(bookingResponse);

      if (bookingId.isEmpty) {
        throw const ApiException('Backend không trả về mã đăng ký dịch vụ.');
      }
    } finally {
      _registrationLocks.remove(lockKey);
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    if (bookingId.trim().isEmpty) {
      throw const ApiException('Không tìm thấy mã đăng ký dịch vụ.');
    }

    await _post('/Bookings/delete', [bookingId]);
  }

  Future<String> _currentResidentId() async {
    final sessionResidentId = AuthSession.residentId;

    if (sessionResidentId != null && sessionResidentId.isNotEmpty) {
      return sessionResidentId;
    }

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

  String _extractGuid(dynamic value) {
    if (value is String) {
      return value.replaceAll('"', '').trim();
    }

    if (value is Map) {
      for (final key in const ['bookingId', 'id', 'value']) {
        final result = value[key]?.toString().replaceAll('"', '').trim() ?? '';

        if (result.isNotEmpty) {
          return result;
        }
      }
    }

    return value?.toString().replaceAll('"', '').trim() ?? '';
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

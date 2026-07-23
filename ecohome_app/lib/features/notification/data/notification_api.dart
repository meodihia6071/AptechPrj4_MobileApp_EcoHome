import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_config.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/data/auth_session.dart';
import 'notification_item.dart';

class NotificationApi {
  NotificationApi({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<AppNotificationItem>>
      getMyNotifications() async {
    final residentId = await _currentResidentId();
    final response = await _get('/Notifications');

    final notifications = _asList(response)
        .map(AppNotificationItem.fromJson)
        .where((notification) {
      if (notification.notificationId.isEmpty ||
          notification.isDeleted) {
        return false;
      }

      // ReceiveEnum:
      // 0 = All, 1 = Resident, 2 = Staff.
      final isForResidents =
          notification.receiveEnum == 0 ||
          notification.receiveEnum == 1;

      if (!isForResidents) {
        return false;
      }

      final targetResident =
          notification.residentId?.toLowerCase();

      return targetResident == null ||
          targetResident.isEmpty ||
          targetResident == residentId.toLowerCase();
    }).toList();

    notifications.sort((first, second) {
      final firstDate =
          first.createdDate ??
          first.modifiedDate ??
          DateTime(1970);

      final secondDate =
          second.createdDate ??
          second.modifiedDate ??
          DateTime(1970);

      return secondDate.compareTo(firstDate);
    });

    return notifications;
  }

  Future<AppNotificationItem> markAsRead(
    AppNotificationItem notification,
  ) async {
    if (!notification.isUnread) {
      return notification;
    }

    await _put(
      '/Notifications/${notification.notificationId}',
      notification.toUpdateJson(newStatus: 0),
    );

    return notification.copyWith(
      status: 0,
      modifiedDate: DateTime.now(),
    );
  }

  Future<List<AppNotificationItem>> markAllAsRead(
    List<AppNotificationItem> notifications,
  ) async {
    final result = <AppNotificationItem>[];

    // Chạy tuần tự để tránh gửi quá nhiều PUT cùng lúc.
    for (final notification in notifications) {
      if (notification.isUnread) {
        result.add(await markAsRead(notification));
      } else {
        result.add(notification);
      }
    }

    return result;
  }

  Future<String> _currentResidentId() async {
    final residentId = AuthSession.residentId;

    if (residentId != null && residentId.isNotEmpty) {
      return residentId;
    }

    final accountId = AuthSession.accountId;
    final token = AuthSession.token;

    if (accountId == null ||
        accountId.isEmpty ||
        token == null ||
        token.isEmpty) {
      throw const ApiException(
        'Phiên đăng nhập không hợp lệ.',
      );
    }

    final response = _asMap(
      await _post(
        '/Residents/filter',
        {
          'conditions': [
            {
              'key': 'AccountId',
              'guidValue': accountId,
            },
          ],
          'sortName': 'ModifiedDate',
          'sortMethod': 'DESC',
          'page': 0,
          'limit': 20,
        },
      ),
    );

    final residents = _asList(response['results']);

    final result = residents.isEmpty
        ? ''
        : residents.first['residentId']?.toString() ?? '';

    if (result.isEmpty) {
      throw const ApiException(
        'Không tìm thấy hồ sơ cư dân.',
      );
    }

    return result;
  }

  Future<dynamic> _get(String path) {
    return _request(
      () => _client.get(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: _headers,
      ),
    );
  }

  Future<dynamic> _post(
    String path,
    dynamic body,
  ) {
    return _request(
      () => _client.post(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: _headers,
        body: jsonEncode(body),
      ),
    );
  }

  Future<dynamic> _put(
    String path,
    dynamic body,
  ) {
    return _request(
      () => _client.put(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: _headers,
        body: jsonEncode(body),
      ),
    );
  }

  Future<dynamic> _request(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request().timeout(
        const Duration(seconds: 20),
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
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

      throw const ApiException(
        'Không thể kết nối máy chủ.',
      );
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

      if (decoded is Map &&
          decoded['message'] != null) {
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
          'Authorization':
              'Bearer ${AuthSession.token}',
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

        if (raw is Map &&
            raw[r'$values'] is List) {
          raw = raw[r'$values'];
        }
      }
    }

    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map>()
        .map(
          (item) =>
              Map<String, dynamic>.from(item),
        )
        .toList();
  }
}

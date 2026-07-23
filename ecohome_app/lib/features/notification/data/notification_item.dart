enum AppNotificationType {
  management,
  incident,
  payment,
}

class AppNotificationItem {
  const AppNotificationItem({
    required this.notificationId,
    required this.title,
    required this.description,
    required this.receiveEnum,
    required this.status,
    required this.createdDate,
    required this.modifiedDate,
    required this.isDeleted,
    this.residentId,
    this.paymentId,
  });

  final String notificationId;
  final String title;
  final String description;
  final int receiveEnum;
  final String? residentId;
  final String? paymentId;
  final int status;
  final DateTime? createdDate;
  final DateTime? modifiedDate;
  final bool isDeleted;

  bool get isUnread => status == 1;

  AppNotificationType get type {
    final normalized =
        '$title $description'.toLowerCase();

    if (paymentId != null ||
        normalized.contains('thanh toán') ||
        normalized.contains('hóa đơn') ||
        normalized.contains('hoá đơn') ||
        normalized.contains('tiền nhà') ||
        normalized.contains('tiền điện') ||
        normalized.contains('tiền nước') ||
        normalized.contains('tiền dịch vụ') ||
        normalized.contains('đóng tiền') ||
        normalized.contains('phí dịch vụ')) {
      return AppNotificationType.payment;
    }

    if (normalized.contains('sự cố') ||
        normalized.contains('báo cáo') ||
        normalized.contains('đang xử lý') ||
        normalized.contains('đã khắc phục') ||
        normalized.contains('đã hoàn thành') ||
        normalized.contains('thu hồi')) {
      return AppNotificationType.incident;
    }

    return AppNotificationType.management;
  }

  AppNotificationItem copyWith({
    int? status,
    DateTime? modifiedDate,
  }) {
    return AppNotificationItem(
      notificationId: notificationId,
      title: title,
      description: description,
      receiveEnum: receiveEnum,
      residentId: residentId,
      paymentId: paymentId,
      status: status ?? this.status,
      createdDate: createdDate,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      isDeleted: isDeleted,
    );
  }

  Map<String, dynamic> toUpdateJson({
    required int newStatus,
  }) {
    return {
      'notificationId': notificationId,
      'title': title,
      'description': description,
      'receiveEnum': receiveEnum,
      'residentId': residentId,
      'paymentId': paymentId,
      'status': newStatus,
      'createdDate':
          (createdDate ?? DateTime.now()).toIso8601String(),
      'modifiedDate': DateTime.now().toIso8601String(),
      'isDeleted': false,
    };
  }

  factory AppNotificationItem.fromJson(
    Map<String, dynamic> json,
  ) {
    return AppNotificationItem(
      notificationId:
          json['notificationId']?.toString() ?? '',
      title: _text(
        json['title'],
        'Thông báo EcoHome',
      ),
      description: _text(
        json['description'],
        'Bạn có một thông báo mới.',
      ),
      receiveEnum:
          int.tryParse(
            json['receiveEnum']?.toString() ?? '',
          ) ??
          0,
      residentId: _nullableText(json['residentId']),
      paymentId: _nullableText(json['paymentId']),
      status:
          int.tryParse(
            json['status']?.toString() ?? '',
          ) ??
          0,
      createdDate: DateTime.tryParse(
        json['createdDate']?.toString() ?? '',
      ),
      modifiedDate: DateTime.tryParse(
        json['modifiedDate']?.toString() ?? '',
      ),
      isDeleted: _toBool(json['isDeleted']),
    );
  }

  static String _text(
    dynamic value,
    String fallback,
  ) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String? _nullableText(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    return value?.toString().toLowerCase() == 'true' ||
        value?.toString() == '1';
  }
}

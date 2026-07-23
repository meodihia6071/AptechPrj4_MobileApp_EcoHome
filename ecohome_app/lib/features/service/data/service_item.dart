class ServiceOverview {
  const ServiceOverview({
    required this.serviceId,
    required this.name,
    required this.description,
    required this.dailyPrice,
    required this.monthlyPrice,
  });

  final String serviceId;
  final String name;
  final String description;
  final double dailyPrice;
  final double monthlyPrice;

  factory ServiceOverview.fromJson(
    Map<String, dynamic> json,
  ) {
    return ServiceOverview(
      serviceId: json['serviceId']?.toString() ?? '',
      name: _text(json['name'], 'Dịch vụ'),
      description: _text(
        json['description'],
        'Chưa có mô tả dịch vụ.',
      ),
      dailyPrice:
          double.tryParse(json['price']?.toString() ?? '') ?? 0,
      monthlyPrice:
          double.tryParse(json['monthlyPrice']?.toString() ?? '') ?? 0,
    );
  }

  static String _text(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}

class ServiceBooking {
  const ServiceBooking({
    required this.bookingId,
    required this.residentId,
    required this.serviceId,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.bookingType,
    required this.modifiedDate,
    required this.isDeleted,
  });

  final String bookingId;
  final String residentId;
  final String serviceId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int status;
  final int bookingType;
  final DateTime? modifiedDate;
  final bool isDeleted;

  bool get isActive =>
      !isDeleted && (status == 0 || status == 1);

  bool get isPending => status == 0;
  bool get isUsing => status == 1;
  bool get isClosed => status == 2;
  bool get isMonthly => bookingType == 1;

  String get statusLabel {
    switch (status) {
      case 0:
        return 'Đang chờ xác nhận';
      case 1:
        return 'Đang sử dụng';
      case 2:
        return 'Đã hoàn thành';
      default:
        return 'Không xác định';
    }
  }

  String get bookingTypeLabel {
    return isMonthly ? 'Gói theo tháng' : 'Gói theo ngày';
  }

  factory ServiceBooking.fromJson(
    Map<String, dynamic> json,
  ) {
    return ServiceBooking(
      bookingId: json['bookingId']?.toString() ?? '',
      residentId: json['residentId']?.toString() ?? '',
      serviceId: json['serviceId']?.toString() ?? '',
      startDate: DateTime.tryParse(
        json['startDate']?.toString() ?? '',
      ),
      endDate: DateTime.tryParse(
        json['endDate']?.toString() ?? '',
      ),
      status:
          int.tryParse(json['status']?.toString() ?? '') ?? 0,
      bookingType:
          int.tryParse(json['bookingType']?.toString() ?? '') ?? 0,
      modifiedDate: DateTime.tryParse(
        json['modifiedDate']?.toString() ?? '',
      ),
      isDeleted: _toBool(json['isDeleted']),
    );
  }

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    return value?.toString().toLowerCase() == 'true' ||
        value?.toString() == '1';
  }
}

class RegisteredServiceItem {
  const RegisteredServiceItem({
    required this.service,
    required this.booking,
  });

  final ServiceOverview service;
  final ServiceBooking booking;
}

class ServiceScreenData {
  const ServiceScreenData({
    required this.registered,
    required this.available,
  });

  final List<RegisteredServiceItem> registered;
  final List<ServiceOverview> available;

  static const empty = ServiceScreenData(
    registered: [],
    available: [],
  );
}

class ServiceRegistration {
  const ServiceRegistration({
    required this.bookingType,
    required this.startDate,
    required this.endDate,
    required this.amount,
    required this.transferContent,
  });

  final int bookingType;
  final DateTime startDate;
  final DateTime endDate;
  final double amount;
  final String transferContent;
}

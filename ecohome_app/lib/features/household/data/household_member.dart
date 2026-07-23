class HouseholdInfo {
  const HouseholdInfo({required this.contractId, required this.members});

  final String contractId;
  final List<HouseholdMember> members;
}

class HouseholdMember {
  const HouseholdMember({
    required this.residentId,
    required this.name,
    required this.phone,
    required this.email,
    required this.residentType,
  });

  final String residentId;
  final String name;
  final String phone;
  final String email;
  final int residentType;

  bool get isOwner => residentType == 0;

  String get roleLabel {
    switch (residentType) {
      case 0:
        return 'Chủ hộ';
      case 1:
        return 'Vợ / Chồng';
      case 2:
        return 'Con cái';
      case 3:
        return 'Người thuê';
      default:
        return 'Thành viên';
    }
  }

  factory HouseholdMember.fromContractResident(Map<String, dynamic> relation) {
    final resident = _toMap(relation['resident']);
    final account = _toMap(resident['account']);

    return HouseholdMember(
      residentId: resident['residentId']?.toString() ?? '',
      name: _text(account['fullName'], 'Chưa cập nhật tên'),
      phone: _text(account['phoneNumber'], '--'),
      email: _text(account['email'], '--'),
      residentType:
          int.tryParse(relation['residentType']?.toString() ?? '') ?? -1,
    );
  }

  static Map<String, dynamic> _toMap(dynamic value) {
    return value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};
  }

  static String _text(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}

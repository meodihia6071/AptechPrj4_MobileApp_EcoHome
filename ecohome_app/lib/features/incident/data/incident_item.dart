class IncidentItem {
  const IncidentItem({
    required this.incidentId,
    required this.apartmentId,
    required this.reportedBy,
    required this.rawDescription,
    required this.status,
    required this.createdDate,
    required this.modifiedDate,
    required this.isDeleted,
    this.resolvedDescription,
    this.closedDescription,
    this.cancelDescription,
  });

  static const String _titlePrefix = 'Tiêu đề: ';
  static const String _descriptionPrefix = 'Mô tả: ';

  final String incidentId;
  final String apartmentId;
  final String reportedBy;
  final String rawDescription;
  final String? resolvedDescription;
  final String? closedDescription;
  final String? cancelDescription;
  final int status;
  final DateTime? createdDate;
  final DateTime? modifiedDate;
  final bool isDeleted;

  String get title {
    final lines = rawDescription.split('\n');

    if (lines.isNotEmpty && lines.first.startsWith(_titlePrefix)) {
      final value = lines.first.substring(_titlePrefix.length).trim();

      if (value.isNotEmpty) {
        return value;
      }
    }

    return 'Báo cáo sự cố';
  }

  String get description {
    final marker = '\n$_descriptionPrefix';
    final markerIndex = rawDescription.indexOf(marker);

    if (markerIndex >= 0) {
      final value = rawDescription
          .substring(markerIndex + marker.length)
          .trim();

      if (value.isNotEmpty) {
        return value;
      }
    }

    return rawDescription.trim();
  }

  bool get canCancel => status == 0;

  static String composeDescription({
    required String title,
    required String description,
  }) {
    return '$_titlePrefix${title.trim()}\n'
        '$_descriptionPrefix${description.trim()}';
  }

  factory IncidentItem.fromJson(Map<String, dynamic> json) {
    return IncidentItem(
      incidentId: json['incidentId']?.toString() ?? '',
      apartmentId: json['apartmentId']?.toString() ?? '',
      reportedBy: json['reportedBy']?.toString() ?? '',
      rawDescription: json['description']?.toString() ?? '',
      resolvedDescription: _nullableText(json['resolvedDescription']),
      closedDescription: _nullableText(json['closedDescription']),
      cancelDescription: _nullableText(json['cancelDescription']),
      status: int.tryParse(json['status']?.toString() ?? '') ?? 0,
      createdDate: DateTime.tryParse(json['createdDate']?.toString() ?? ''),
      modifiedDate: DateTime.tryParse(json['modifiedDate']?.toString() ?? ''),
      isDeleted: _toBool(json['isDeleted']),
    );
  }

  Map<String, dynamic> toUpdateJson({
    required int newStatus,
    required String? newCancelDescription,
  }) {
    return {
      'incidentId': incidentId,
      'apartmentId': apartmentId,
      'reportedBy': reportedBy,
      'description': rawDescription,
      'resolvedDescription': resolvedDescription,
      'closedDescription': closedDescription,
      'cancelDescription': newCancelDescription ?? cancelDescription,
      'status': newStatus,
      'createdDate': (createdDate ?? DateTime.now()).toIso8601String(),
      'modifiedDate': DateTime.now().toIso8601String(),
      'isDeleted': false,
    };
  }

  static String? _nullableText(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    return value?.toString().toLowerCase() == 'true';
  }
}

class ResidentIncidentContext {
  const ResidentIncidentContext({
    required this.residentId,
    required this.apartmentId,
  });

  final String residentId;
  final String apartmentId;
}

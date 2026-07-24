import 'package:flutter/material.dart';
import 'package:ecohome_app/core/constants/app_colors.dart';
import 'package:ecohome_app/shared/widgets/app_header.dart';
import 'package:ecohome_app/shared/widgets/incident_card.dart';

import '../../../auth/data/auth_api.dart';
import '../../data/incident_api.dart';
import '../../data/incident_item.dart';

class IncidentScreen extends StatefulWidget {
  const IncidentScreen({super.key});

  @override
  State<IncidentScreen> createState() => _IncidentScreenState();
}

class _IncidentScreenState extends State<IncidentScreen> {
  final IncidentApi _api = IncidentApi();

  int _activeFilterIndex = 0;
  bool _isSubmitting = false;
  late Future<List<IncidentItem>> _incidentsFuture;

  @override
  void initState() {
    super.initState();
    _incidentsFuture = _api.getMyIncidents();
  }

  void _reload() {
    setState(() {
      _incidentsFuture = _api.getMyIncidents();
    });
  }

  Future<void> _refresh() async {
    final future = _api.getMyIncidents();

    setState(() {
      _incidentsFuture = future;
    });

    await future;
  }

  Future<void> _showCreateIncidentForm() async {
    final draft = await showModalBottomSheet<_IncidentDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.primary.withValues(alpha: 0.18),
      builder: (context) => const _CreateIncidentSheet(),
    );

    if (draft == null || !mounted) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _api.createIncident(
        title: draft.title,
        description: draft.description,
      );

      final refreshed = _api.getMyIncidents();

      setState(() {
        _activeFilterIndex = 0;
        _incidentsFuture = refreshed;
      });

      await refreshed;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gửi báo cáo sự cố thành công.'),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _showCancelConfirmation(
    IncidentItem incident,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.primary.withValues(alpha: 0.18),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.undo_rounded,
                      color: Color(0xFFBE123C),
                      size: 29,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Thu hồi báo cáo?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Báo cáo ${_displayId(incident.incidentId)} '
                    'sẽ được chuyển sang trạng thái đã thu hồi.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            incident.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.secondary,
                            side: const BorderSide(
                              color: Color(0xFFCBD5E1),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Giữ báo cáo',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              Navigator.pop(context, true),
                          icon: const Icon(
                            Icons.undo_rounded,
                            size: 18,
                          ),
                          label: const Text(
                            'Thu hồi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFFBE123C),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _api.cancelIncident(incident);

      final refreshed = _api.getMyIncidents();

      setState(() {
        _incidentsFuture = refreshed;
      });

      await refreshed;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã thu hồi báo cáo sự cố.'),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showIncidentDetail(IncidentItem incident) {
    final status = _statusView(incident.status);

    showDialog<void>(
      context: context,
      barrierColor: AppColors.primary.withValues(alpha: 0.18),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 24,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 540,
            maxHeight:
                MediaQuery.of(context).size.height * 0.88,
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    18,
                    14,
                    18,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: 0.08,
                    ),
                    border: const Border(
                      bottom: BorderSide(
                        color: Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Chi tiết báo cáo',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              incident.title,
                              style: const TextStyle(
                                fontSize: 18,
                                height: 1.25,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.secondary,
                        ),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      18,
                      20,
                      22,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _InfoChip(
                              icon: Icons.tag_rounded,
                              label: _displayId(
                                incident.incidentId,
                              ),
                            ),
                            _InfoChip(
                              icon: Icons.schedule_rounded,
                              label: _formatFullDate(
                                incident.createdDate,
                              ),
                            ),
                            _StatusChip(
                              label: status.label,
                              backgroundColor:
                                  status.backgroundColor,
                              textColor: status.textColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _DetailSection(
                          icon: Icons.notes_rounded,
                          title: 'Mô tả sự cố',
                          content: incident.description,
                          backgroundColor:
                              const Color(0xFFF8FAFC),
                          iconBackgroundColor:
                              AppColors.primary.withValues(
                            alpha: 0.10,
                          ),
                          iconColor: AppColors.primary,
                        ),
                        if (incident.resolvedDescription != null) ...[
                          const SizedBox(height: 12),
                          _DetailSection(
                            icon: Icons.build_circle_outlined,
                            title: 'Hướng xử lý',
                            content:
                                incident.resolvedDescription!,
                            backgroundColor:
                                const Color(0xFFEFF6FF),
                            iconBackgroundColor:
                                const Color(0xFFDBEAFE),
                            iconColor:
                                const Color(0xFF1D4ED8),
                          ),
                        ],
                        if (incident.closedDescription != null) ...[
                          const SizedBox(height: 12),
                          _DetailSection(
                            icon: Icons.verified_outlined,
                            title: 'Kết quả hoàn thành',
                            content:
                                incident.closedDescription!,
                            backgroundColor:
                                const Color(0xFFF0FDF4),
                            iconBackgroundColor:
                                const Color(0xFFDCFCE7),
                            iconColor:
                                const Color(0xFF15803D),
                          ),
                        ],
                        if (incident.cancelDescription != null) ...[
                          const SizedBox(height: 12),
                          _DetailSection(
                            icon: Icons.undo_rounded,
                            title: 'Lý do thu hồi',
                            content:
                                incident.cancelDescription!,
                            backgroundColor:
                                const Color(0xFFFFF1F2),
                            iconBackgroundColor:
                                const Color(0xFFFFE4E6),
                            iconColor:
                                const Color(0xFFBE123C),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                Navigator.pop(context),
                            icon: const Icon(
                              Icons.check_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'Đã hiểu',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppHeader(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Danh sách báo cáo',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Quản lý các sự cố bạn đã gửi',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : _showCreateIncidentForm,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.add, size: 18),
                  label: Text(
                    _isSubmitting ? 'Đang gửi' : 'Tạo mới',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildFilterChip(0, 'Tất cả'),
                const SizedBox(width: 10),
                _buildFilterChip(1, 'Đang xử lý'),
                const SizedBox(width: 10),
                _buildFilterChip(2, 'Đã hoàn thành'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<IncidentItem>>(
              future: _incidentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  final error = snapshot.error;
                  final message = error is ApiException
                      ? error.message
                      : 'Không thể tải danh sách báo cáo.';

                  return _ErrorView(
                    message: message,
                    onRetry: _reload,
                  );
                }

                final incidents = _filterIncidents(
                  snapshot.data ?? const [],
                );

                if (incidents.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(
                          height: 320,
                          child: Center(
                            child: Text(
                              'Chưa có báo cáo phù hợp.',
                              style: TextStyle(
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    itemCount: incidents.length + 1,
                    itemBuilder: (context, index) {
                      if (index == incidents.length) {
                        return const SizedBox(height: 20);
                      }

                      final incident = incidents[index];
                      final status =
                          _statusView(incident.status);

                      return IncidentCard(
                        statusLabel: status.label,
                        statusColor: status.backgroundColor,
                        textColor: status.textColor,
                        id: _displayId(incident.incidentId),
                        time: _formatRelativeDate(
                          incident.createdDate,
                        ),
                        title: incident.title,
                        desc: incident.description,
                        bottomLeftWidget:
                            _statusHint(incident.status),
                        actionWidget: incident.canCancel
                            ? _IncidentActionButton(
                                icon: Icons.undo_rounded,
                                label: 'Thu hồi',
                                foregroundColor:
                                    const Color(0xFFBE123C),
                                backgroundColor:
                                    const Color(0xFFFFF1F2),
                                borderColor:
                                    const Color(0xFFFFCDD5),
                                onPressed: _isSubmitting
                                    ? null
                                    : () =>
                                        _showCancelConfirmation(
                                          incident,
                                        ),
                              )
                            : _IncidentActionButton(
                                icon:
                                    Icons.visibility_outlined,
                                label: 'Chi tiết',
                                foregroundColor:
                                    AppColors.primary,
                                backgroundColor:
                                    AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                borderColor:
                                    AppColors.primary.withValues(
                                  alpha: 0.18,
                                ),
                                onPressed: () =>
                                    _showIncidentDetail(
                                  incident,
                                ),
                              ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<IncidentItem> _filterIncidents(
    List<IncidentItem> incidents,
  ) {
    switch (_activeFilterIndex) {
      case 1:
        return incidents
            .where(
              (incident) =>
                  incident.status == 0 ||
                  incident.status == 1 ||
                  incident.status == 4,
            )
            .toList();
      case 2:
        return incidents
            .where(
              (incident) =>
                  incident.status == 2 ||
                  incident.status == 3,
            )
            .toList();
      default:
        return incidents;
    }
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _activeFilterIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilterIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : const Color(0xFFE2E8F0)
                  .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : AppColors.secondary,
            fontWeight: isSelected
                ? FontWeight.bold
                : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  static _IncidentStatusView _statusView(int status) {
    switch (status) {
      case 0:
        return const _IncidentStatusView(
          label: 'Mới (Open)',
          backgroundColor: Color(0xFFFEE2E2),
          textColor: Colors.red,
        );
      case 1:
        return const _IncidentStatusView(
          label: 'Đang xử lý',
          backgroundColor: Color(0xFFFEF3C7),
          textColor: Color(0xFFB45309),
        );
      case 2:
        return const _IncidentStatusView(
          label: 'Đã khắc phục',
          backgroundColor: Color(0xFFDBEAFE),
          textColor: Color(0xFF1D4ED8),
        );
      case 3:
        return const _IncidentStatusView(
          label: 'Đã hoàn thành',
          backgroundColor: Color(0xFFDCFCE7),
          textColor: Colors.green,
        );
      case 4:
        return const _IncidentStatusView(
          label: 'Mở lại',
          backgroundColor: Color(0xFFF3E8FF),
          textColor: Color(0xFF7E22CE),
        );
      case 5:
        return const _IncidentStatusView(
          label: 'Đã thu hồi',
          backgroundColor: Color(0xFFE2E8F0),
          textColor: AppColors.secondary,
        );
      default:
        return const _IncidentStatusView(
          label: 'Không xác định',
          backgroundColor: Color(0xFFE2E8F0),
          textColor: AppColors.secondary,
        );
    }
  }

  static Widget _statusHint(int status) {
    String? text;
    IconData icon = Icons.info_outline;

    switch (status) {
      case 1:
        text = 'Ban quản lý đang xử lý';
        icon = Icons.build_circle_outlined;
        break;
      case 2:
        text = 'Đã có hướng khắc phục';
        icon = Icons.task_alt;
        break;
      case 3:
        text = 'Sự cố đã hoàn tất';
        icon = Icons.verified_outlined;
        break;
      case 4:
        text = 'Sự cố đã được mở lại';
        icon = Icons.replay;
        break;
      case 5:
        text = 'Báo cáo đã được thu hồi';
        icon = Icons.cancel_outlined;
        break;
    }

    if (text == null) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.primary,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  static String _displayId(String id) {
    final normalized =
        id.replaceAll('-', '').toUpperCase();

    if (normalized.isEmpty) {
      return '#INC';
    }

    final shortId = normalized.length > 8
        ? normalized.substring(0, 8)
        : normalized;

    return '#INC-$shortId';
  }

  static String _formatRelativeDate(DateTime? date) {
    if (date == null) {
      return '--';
    }

    final local = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final value =
        DateTime(local.year, local.month, local.day);
    final difference = today.difference(value).inDays;
    final time =
        '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';

    if (difference == 0) {
      return 'Hôm nay, $time';
    }

    if (difference == 1) {
      return 'Hôm qua, $time';
    }

    return '${_twoDigits(local.day)}/'
        '${_twoDigits(local.month)}/'
        '${local.year}';
  }

  static String _formatFullDate(DateTime? date) {
    if (date == null) {
      return '--';
    }

    final local = date.toLocal();

    return '${_twoDigits(local.day)}/'
        '${_twoDigits(local.month)}/'
        '${local.year} '
        '${_twoDigits(local.hour)}:'
        '${_twoDigits(local.minute)}';
  }

  static String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }
}

class _IncidentDraft {
  const _IncidentDraft({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}

class _CreateIncidentSheet extends StatefulWidget {
  const _CreateIncidentSheet();

  @override
  State<_CreateIncidentSheet> createState() =>
      _CreateIncidentSheetState();
}

class _CreateIncidentSheetState
    extends State<_CreateIncidentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.pop(
      context,
      _IncidentDraft(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: AppColors.secondary,
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        color: AppColors.primary,
        size: 21,
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      counterStyle: const TextStyle(
        color: AppColors.secondary,
        fontSize: 11,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight =
        MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        top: 24,
        left: 12,
        right: 12,
        bottom: keyboardHeight,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(26),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 620,
            maxHeight:
                MediaQuery.of(context).size.height * 0.90,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  0,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.report_problem_outlined,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tạo báo cáo sự cố',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Mô tả rõ vấn đề để ban quản lý hỗ trợ nhanh hơn.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.secondary,
                      ),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    24,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tiêu đề sự cố',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _titleController,
                          maxLength: 120,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(
                            hintText:
                                'Ví dụ: Rò rỉ nước sảnh tầng 5',
                            icon: Icons.title_rounded,
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';

                            if (text.isEmpty) {
                              return 'Vui lòng nhập tiêu đề.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Mô tả chi tiết',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          minLines: 4,
                          maxLines: 6,
                          maxLength: 1000,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: _inputDecoration(
                            hintText:
                                'Nhập vị trí, thời điểm và tình trạng sự cố...',
                            icon: Icons.notes_rounded,
                          ).copyWith(
                            alignLabelWithHint: true,
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';

                            if (text.isEmpty) {
                              return 'Vui lòng nhập mô tả sự cố.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Báo cáo sẽ được gửi trực tiếp đến ban quản lý và hiển thị trong danh sách của bạn.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      AppColors.secondary,
                                  side: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Hủy',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: _submit,
                                icon: const Icon(
                                  Icons.send_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Gửi ban quản lý',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding:
                                      const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncidentActionButton extends StatelessWidget {
  const _IncidentActionButton({
    required this.icon,
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onPressed == null
          ? const Color(0xFFF1F5F9)
          : backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: onPressed == null
                  ? const Color(0xFFE2E8F0)
                  : borderColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: onPressed == null
                    ? const Color(0xFF94A3B8)
                    : foregroundColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: onPressed == null
                      ? const Color(0xFF94A3B8)
                      : foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 1),
          Icon(
            icon,
            size: 15,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 7,
            color: textColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.title,
    required this.content,
    required this.backgroundColor,
    required this.iconBackgroundColor,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final String content;
  final Color backgroundColor;
  final Color iconBackgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0)
              .withValues(alpha: 0.75),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 19,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IncidentStatusView {
  const _IncidentStatusView({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.secondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

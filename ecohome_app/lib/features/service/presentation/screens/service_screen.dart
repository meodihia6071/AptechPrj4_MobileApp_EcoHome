import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ecohome_app/core/constants/app_colors.dart';
import 'package:ecohome_app/core/constants/vietqr_config.dart';
import 'package:ecohome_app/shared/widgets/app_header.dart';
import 'package:ecohome_app/shared/widgets/service_card.dart';

import '../../../auth/data/auth_api.dart';
import '../../data/service_api.dart';
import '../../data/service_item.dart';

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key});

  @override
  State<ServiceScreen> createState() =>
      _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  final ServiceApi _api = ServiceApi();

  int _activeTabIndex = 0;
  bool _isSubmitting = false;
  late Future<ServiceScreenData> _servicesFuture;

  @override
  void initState() {
    super.initState();
    _servicesFuture = _api.getServices();
  }

  void _reload() {
    setState(() {
      _servicesFuture = _api.getServices();
    });
  }

  Future<void> _refresh() async {
    final future = _api.getServices();

    setState(() {
      _servicesFuture = future;
    });

    await future;
  }

  Future<void> _openRegistration(
    ServiceOverview service,
  ) async {
    final registration =
        await showModalBottomSheet<ServiceRegistration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor:
          AppColors.primary.withValues(alpha: 0.20),
      builder: (context) => _RegistrationSheet(
        service: service,
      ),
    );

    if (registration == null || !mounted) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _api.registerAndSubmitPayment(
        service: service,
        registration: registration,
      );

      final refreshed = _api.getServices();

      setState(() {
        _activeTabIndex = 0;
        _servicesFuture = refreshed;
      });

      await refreshed;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã gửi đăng ký. Dịch vụ đang chờ xác nhận.',
          ),
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

  Future<void> _confirmCancel(
    RegisteredServiceItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor:
          AppColors.primary.withValues(alpha: 0.18),
      builder: (context) => _CancelServiceDialog(
        item: item,
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _api.cancelBooking(
        item.booking.bookingId,
      );

      final refreshed = _api.getServices();

      setState(() {
        _servicesFuture = refreshed;
      });

      await refreshed;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã hủy đăng ký dịch vụ.'),
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

  void _showDetail(
    ServiceOverview service, {
    ServiceBooking? booking,
  }) {
    showDialog<void>(
      context: context,
      barrierColor:
          AppColors.primary.withValues(alpha: 0.18),
      builder: (context) => _ServiceDetailDialog(
        service: service,
        booking: booking,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const AppHeader(),
          const SizedBox(height: 22),
          const Padding(
            padding:
                EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Quản lý dịch vụ',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Đăng ký và theo dõi các dịch vụ tiện ích của bạn.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          Expanded(
            child: FutureBuilder<ServiceScreenData>(
              future: _servicesFuture,
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
                      : 'Không thể tải danh sách dịch vụ.';

                  return _ErrorView(
                    message: message,
                    onRetry: _reload,
                  );
                }

                final data =
                    snapshot.data ?? ServiceScreenData.empty;

                final itemCount = _activeTabIndex == 0
                    ? data.registered.length
                    : data.available.length;

                return Column(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      child: _ServiceTabBar(
                        activeIndex: _activeTabIndex,
                        registeredCount:
                            data.registered.length,
                        availableCount:
                            data.available.length,
                        onChanged: (index) {
                          setState(() {
                            _activeTabIndex = index;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 17),
                    Expanded(
                      child: itemCount == 0
                          ? _EmptyServiceList(
                              isRegisteredTab:
                                  _activeTabIndex == 0,
                              onRefresh: _refresh,
                            )
                          : RefreshIndicator(
                              onRefresh: _refresh,
                              child: ListView.separated(
                                key: PageStorageKey(
                                  'service-booking-list-'
                                  '$_activeTabIndex',
                                ),
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  24,
                                ),
                                itemCount: itemCount,
                                separatorBuilder:
                                    (context, index) =>
                                        const SizedBox(
                                  height: 15,
                                ),
                                itemBuilder:
                                    (context, index) {
                                  if (_activeTabIndex == 0) {
                                    final item =
                                        data.registered[index];

                                    return KeyedSubtree(
                                      key: ValueKey(
                                        'booking-'
                                        '${item.booking.bookingId}',
                                      ),
                                      child:
                                          _buildRegisteredCard(
                                        item,
                                      ),
                                    );
                                  }

                                  final service =
                                      data.available[index];

                                  return KeyedSubtree(
                                    key: ValueKey(
                                      'available-service-'
                                      '${service.serviceId}',
                                    ),
                                    child:
                                        _buildAvailableCard(
                                      service,
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableCard(
    ServiceOverview service,
  ) {
    return ServiceCard(
      icon: _iconFor(service.name),
      title: service.name,
      subtitle: service.description,
      statusText: 'Sẵn sàng đăng ký',
      statusBackgroundColor:
          AppColors.primary.withValues(alpha: 0.08),
      statusTextColor: AppColors.primary,
      firstLabel: 'Giá theo ngày',
      firstValue: _formatPrice(service.dailyPrice),
      secondLabel: 'Giá theo tháng',
      secondValue:
          _formatPrice(service.monthlyPrice),
      primaryActionText: 'Đăng ký',
      primaryActionIcon: Icons.add_rounded,
      onPrimaryPressed: _isSubmitting
          ? null
          : () => _openRegistration(service),
      onDetailPressed: () =>
          _showDetail(service),
    );
  }

  Widget _buildRegisteredCard(
    RegisteredServiceItem item,
  ) {
    final service = item.service;
    final booking = item.booking;
    final statusStyle =
        _bookingStatusStyle(booking);

    return ServiceCard(
      icon: _iconFor(service.name),
      title: service.name,
      subtitle:
          '${booking.bookingTypeLabel} • '
          '${_shortBookingId(booking.bookingId)}',
      statusText: booking.statusLabel,
      statusBackgroundColor:
          statusStyle.backgroundColor,
      statusTextColor: statusStyle.textColor,
      firstLabel: 'Thời gian sử dụng',
      firstValue: _formatDateRange(
        booking.startDate,
        booking.endDate,
      ),
      secondLabel: 'Phí đăng ký',
      secondValue: _formatPrice(
        booking.isMonthly
            ? service.monthlyPrice
            : service.dailyPrice,
      ),
      primaryActionText: booking.isPending
          ? 'Hủy yêu cầu'
          : 'Hủy đăng ký',
      primaryActionIcon: Icons.undo_rounded,
      primaryActionForegroundColor:
          const Color(0xFFBE123C),
      primaryActionBackgroundColor:
          const Color(0xFFFFF1F2),
      primaryActionBorderColor:
          const Color(0xFFFFCDD5),
      onPrimaryPressed: _isSubmitting
          ? null
          : () => _confirmCancel(item),
      onDetailPressed: () => _showDetail(
        service,
        booking: booking,
      ),
    );
  }

  static String _shortBookingId(String bookingId) {
    final normalized =
        bookingId.replaceAll('-', '').toUpperCase();

    if (normalized.isEmpty) {
      return 'BOOKING';
    }

    final shortId = normalized.length > 8
        ? normalized.substring(0, 8)
        : normalized;

    return '#$shortId';
  }

  static _StatusStyle _bookingStatusStyle(
    ServiceBooking booking,
  ) {
    if (booking.isPending) {
      return const _StatusStyle(
        backgroundColor: Color(0xFFFEF3C7),
        textColor: Color(0xFFB45309),
      );
    }

    if (booking.isUsing) {
      return const _StatusStyle(
        backgroundColor: Color(0xFFDCFCE7),
        textColor: Color(0xFF15803D),
      );
    }

    return const _StatusStyle(
      backgroundColor: Color(0xFFE2E8F0),
      textColor: AppColors.secondary,
    );
  }

  static IconData _iconFor(String name) {
    final normalized = name.toLowerCase();

    if (normalized.contains('dọn') ||
        normalized.contains('vệ sinh')) {
      return Icons.cleaning_services_rounded;
    }

    if (normalized.contains('xe') ||
        normalized.contains('ô tô') ||
        normalized.contains('đỗ')) {
      return Icons.directions_car_rounded;
    }

    if (normalized.contains('giặt')) {
      return Icons.local_laundry_service_rounded;
    }

    if (normalized.contains('internet') ||
        normalized.contains('wifi')) {
      return Icons.wifi_rounded;
    }

    if (normalized.contains('điện') ||
        normalized.contains('sửa')) {
      return Icons.home_repair_service_rounded;
    }

    return Icons.miscellaneous_services_rounded;
  }

  static String _formatDate(DateTime? date) {
    if (date == null) {
      return '--';
    }

    final local = date.toLocal();

    return '${_twoDigits(local.day)}/'
        '${_twoDigits(local.month)}/'
        '${local.year}';
  }

  static String _formatDateRange(
    DateTime? start,
    DateTime? end,
  ) {
    if (start == null && end == null) {
      return '--';
    }

    if (start == null) {
      return _formatDate(end);
    }

    if (end == null ||
        (start.year == end.year &&
            start.month == end.month &&
            start.day == end.day)) {
      return _formatDate(start);
    }

    return '${_formatDate(start)} - '
        '${_formatDate(end)}';
  }

  static String _formatPrice(double value) {
    if (value <= 0) {
      return 'Miễn phí';
    }

    final number = value.round().toString();
    final buffer = StringBuffer();

    for (var index = 0;
        index < number.length;
        index++) {
      final remaining = number.length - index;

      buffer.write(number[index]);

      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }

    return '${buffer}đ';
  }

  static String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }
}

class _ServiceTabBar extends StatelessWidget {
  const _ServiceTabBar({
    required this.activeIndex,
    required this.registeredCount,
    required this.availableCount,
    required this.onChanged,
  });

  final int activeIndex;
  final int registeredCount;
  final int availableCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _ServiceTabItem(
            label: 'Đã đăng ký',
            count: registeredCount,
            selected: activeIndex == 0,
            onTap: () => onChanged(0),
          ),
          _ServiceTabItem(
            label: 'Chưa đăng ký',
            count: availableCount,
            selected: activeIndex == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _ServiceTabItem extends StatelessWidget {
  const _ServiceTabItem({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected
            ? Colors.white
            : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 11,
              horizontal: 8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary
                            .withValues(alpha: 0.07),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: selected
                          ? AppColors.primary
                          : AppColors.secondary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(
                            alpha: 0.10,
                          )
                        : const Color(0xFFE2E8F0),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: selected
                          ? AppColors.primary
                          : AppColors.secondary,
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
}

class _EmptyServiceList extends StatelessWidget {
  const _EmptyServiceList({
    required this.isRegisteredTab,
    required this.onRefresh,
  });

  final bool isRegisteredTab;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          28,
          55,
          28,
          24,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.borderGray,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: 0.08,
                    ),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Icon(
                    isRegisteredTab
                        ? Icons
                            .calendar_month_outlined
                        : Icons
                            .task_alt_rounded,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  isRegisteredTab
                      ? 'Bạn chưa đăng ký dịch vụ nào'
                      : 'Bạn đã đăng ký tất cả dịch vụ',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isRegisteredTab
                      ? 'Chuyển sang tab Chưa đăng ký để xem các dịch vụ hiện có.'
                      : 'Kéo xuống để cập nhật danh sách mới nhất.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
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


class _RegistrationSheet extends StatefulWidget {
  const _RegistrationSheet({
    required this.service,
  });

  final ServiceOverview service;

  @override
  State<_RegistrationSheet> createState() =>
      _RegistrationSheetState();
}

class _RegistrationSheetState
    extends State<_RegistrationSheet> {
  int _step = 0;
  int _bookingType = 0;
  DateTime _startDate = DateTime.now();

  double get _amount {
    return _bookingType == 1
        ? widget.service.monthlyPrice
        : widget.service.dailyPrice;
  }

  DateTime get _endDate {
    if (_bookingType == 0) {
      return DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
      );
    }

    final nextMonth = _startDate.month + 1;
    final targetYear =
        _startDate.year + ((nextMonth - 1) ~/ 12);
    final targetMonth = ((nextMonth - 1) % 12) + 1;
    final lastDay =
        DateTime(targetYear, targetMonth + 1, 0).day;
    final targetDay =
        math.min(_startDate.day, lastDay);

    return DateTime(
      targetYear,
      targetMonth,
      targetDay,
    ).subtract(const Duration(days: 1));
  }

  String get _transferContent {
    final serviceCode = widget.service.serviceId
        .replaceAll('-', '')
        .toUpperCase();

    final shortCode = serviceCode.length > 8
        ? serviceCode.substring(0, 8)
        : serviceCode;

    final timeCode =
        DateTime.now().millisecondsSinceEpoch % 1000000;

    return 'ECOHOME $shortCode $timeCode';
  }

  bool get _canUseDaily =>
      widget.service.dailyPrice >= 0;

  bool get _canUseMonthly =>
      widget.service.monthlyPrice > 0;

  @override
  void initState() {
    super.initState();

    if (widget.service.dailyPrice <= 0 &&
        widget.service.monthlyPrice > 0) {
      _bookingType = 1;
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                Theme.of(context).colorScheme.copyWith(
                      primary: AppColors.primary,
                      secondary: AppColors.tertiary,
                    ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  void _continueToPayment() {
    if (_amount > 0 && !VietQrConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chưa cấu hình tài khoản nhận tiền VietQR.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _step = 1;
    });
  }

  void _complete() {
    Navigator.pop(
      context,
      ServiceRegistration(
        bookingType: _bookingType,
        startDate: _startDate,
        endDate: _endDate,
        amount: _amount,
        transferContent: _transferContent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight =
        MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        top: 22,
        left: 10,
        right: 10,
        bottom: keyboardHeight,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 640,
            maxHeight:
                MediaQuery.of(context).size.height * 0.92,
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
                  borderRadius:
                      BorderRadius.circular(20),
                ),
              ),
              _RegistrationHeader(
                service: widget.service,
                step: _step,
                onClose: () => Navigator.pop(context),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    18,
                    20,
                    24,
                  ),
                  child: _step == 0
                      ? _buildPlanStep()
                      : _buildPaymentStep(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn gói dịch vụ',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 11),
        Row(
          children: [
            Expanded(
              child: _PlanOption(
                icon: Icons.today_outlined,
                title: 'Theo ngày',
                subtitle: 'Sử dụng trong một ngày',
                price: _ServiceScreenState._formatPrice(
                  widget.service.dailyPrice,
                ),
                selected: _bookingType == 0,
                enabled: _canUseDaily,
                onTap: () {
                  setState(() {
                    _bookingType = 0;
                  });
                },
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: _PlanOption(
                icon: Icons.calendar_month_outlined,
                title: 'Theo tháng',
                subtitle: 'Sử dụng trong một tháng',
                price: _ServiceScreenState._formatPrice(
                  widget.service.monthlyPrice,
                ),
                selected: _bookingType == 1,
                enabled: _canUseMonthly,
                onTap: () {
                  setState(() {
                    _bookingType = 1;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 17),
        const Text(
          'Ngày bắt đầu',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: _pickStartDate,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: AppColors.borderGray,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: 0.09,
                      ),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.event_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thời gian đăng ký',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _ServiceScreenState
                              ._formatDateRange(
                            _startDate,
                            _endDate,
                          ),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.secondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _PaymentSummary(
          serviceName: widget.service.name,
          planName: _bookingType == 1
              ? 'Gói theo tháng'
              : 'Gói theo ngày',
          amount: _amount,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _continueToPayment,
            icon: const Icon(
              Icons.qr_code_2_rounded,
              size: 19,
            ),
            label: Text(
              _amount > 0
                  ? 'Tiếp tục thanh toán'
                  : 'Tiếp tục đăng ký',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStep() {
    final qrUrl = _amount > 0
        ? VietQrConfig.buildQrUrl(
            amount: _amount,
            transferContent: _transferContent,
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Material(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _step = 0;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 19,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Xác nhận thanh toán',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        if (qrUrl != null)
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.borderGray,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha: 0.06,
                    ),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Image.network(
                qrUrl,
                width: 260,
                height: 300,
                fit: BoxFit.contain,
                errorBuilder:
                    (context, error, stackTrace) {
                  return const SizedBox(
                    width: 260,
                    height: 260,
                    child: Center(
                      child: Text(
                        'Không tải được mã VietQR.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          )
        else
          Center(
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(
                  alpha: 0.08,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 55,
                color: AppColors.primary,
              ),
            ),
          ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: AppColors.borderGray,
            ),
          ),
          child: Column(
            children: [
              if (_amount > 0) ...[
                _PaymentInfoRow(
                  label: 'Ngân hàng',
                  value: VietQrConfig.bankId,
                ),
                _PaymentInfoRow(
                  label: 'Số tài khoản',
                  value: VietQrConfig.accountNumber,
                ),
                _PaymentInfoRow(
                  label: 'Chủ tài khoản',
                  value: VietQrConfig.accountName,
                ),
              ],
              _PaymentInfoRow(
                label: 'Số tiền',
                value: _ServiceScreenState._formatPrice(
                  _amount,
                ),
                valueColor: AppColors.primary,
              ),
              if (_amount > 0)
                _PaymentInfoRow(
                  label: 'Nội dung',
                  value: _transferContent,
                ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Color(0xFFB45309),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _amount > 0
                      ? 'Sau khi chuyển khoản, bấm "Tôi đã thanh toán". Dịch vụ sẽ chuyển sang trạng thái chờ xác nhận.'
                      : 'Dịch vụ miễn phí sẽ được gửi sang trạng thái chờ xác nhận.',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _complete,
            icon: Icon(
              _amount > 0
                  ? Icons.check_rounded
                  : Icons.send_rounded,
              size: 19,
            ),
            label: Text(
              _amount > 0
                  ? 'Tôi đã thanh toán'
                  : 'Xác nhận đăng ký',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RegistrationHeader extends StatelessWidget {
  const _RegistrationHeader({
    required this.service,
    required this.step,
    required this.onClose,
  });

  final ServiceOverview service;
  final int step;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        0,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              step == 0
                  ? Icons
                      .miscellaneous_services_rounded
                  : Icons.qr_code_2_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  step == 0
                      ? 'Đăng ký dịch vụ'
                      : 'Thanh toán VietQR',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  service.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
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
    );
  }
}

class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String price;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = enabled
        ? (selected
            ? AppColors.primary
            : AppColors.textDark)
        : const Color(0xFF94A3B8);

    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.07)
          : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.borderGray,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: foreground,
                    size: 21,
                  ),
                  const Spacer(),
                  Icon(
                    selected
                        ? Icons
                            .radio_button_checked_rounded
                        : Icons
                            .radio_button_off_rounded,
                    color: selected
                        ? AppColors.primary
                        : const Color(0xFFCBD5E1),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: foreground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.35,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 11),
              Text(
                enabled ? price : 'Không áp dụng',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: enabled
                      ? AppColors.primary
                      : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({
    required this.serviceName,
    required this.planName,
    required this.amount,
  });

  final String serviceName;
  final String planName;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(
          alpha: 0.06,
        ),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          _PaymentInfoRow(
            label: 'Dịch vụ',
            value: serviceName,
          ),
          _PaymentInfoRow(
            label: 'Gói đăng ký',
            value: planName,
          ),
          const Divider(
            height: 18,
            color: AppColors.borderGray,
          ),
          _PaymentInfoRow(
            label: 'Tổng thanh toán',
            value: _ServiceScreenState._formatPrice(
              amount,
            ),
            valueColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _PaymentInfoRow extends StatelessWidget {
  const _PaymentInfoRow({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textDark,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondary,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _ServiceDetailDialog extends StatelessWidget {
  const _ServiceDetailDialog({
    required this.service,
    this.booking,
  });

  final ServiceOverview service;
  final ServiceBooking? booking;

  @override
  Widget build(BuildContext context) {
    final currentBooking = booking;

    return Dialog(
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
                color: AppColors.primary.withValues(
                  alpha: 0.08,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                      child: Icon(
                        _ServiceScreenState._iconFor(
                          service.name,
                        ),
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
                            'Chi tiết dịch vụ',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight:
                                  FontWeight.w600,
                              color:
                                  AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            service.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor:
                            AppColors.secondary,
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
                      _ServiceDetailSection(
                        icon: Icons.notes_rounded,
                        title: 'Mô tả dịch vụ',
                        content: service.description,
                        backgroundColor:
                            const Color(0xFFF8FAFC),
                        iconBackgroundColor:
                            AppColors.primary.withValues(
                          alpha: 0.10,
                        ),
                        iconColor: AppColors.primary,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _PriceTile(
                              label: 'Theo ngày',
                              value: _ServiceScreenState
                                  ._formatPrice(
                                service.dailyPrice,
                              ),
                              icon:
                                  Icons.today_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _PriceTile(
                              label: 'Theo tháng',
                              value: _ServiceScreenState
                                  ._formatPrice(
                                service.monthlyPrice,
                              ),
                              icon: Icons
                                  .calendar_month_outlined,
                            ),
                          ),
                        ],
                      ),
                      if (currentBooking != null) ...[
                        const SizedBox(height: 12),
                        _ServiceDetailSection(
                          icon:
                              Icons.event_available_outlined,
                          title: 'Thông tin đăng ký',
                          content:
                              '${currentBooking.bookingTypeLabel}\n'
                              '${_ServiceScreenState._formatDateRange(currentBooking.startDate, currentBooking.endDate)}\n'
                              '${currentBooking.statusLabel}',
                          backgroundColor:
                              const Color(0xFFEFF6FF),
                          iconBackgroundColor:
                              const Color(0xFFDBEAFE),
                          iconColor:
                              const Color(0xFF1D4ED8),
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
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                AppColors.primary,
                            foregroundColor:
                                Colors.white,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                14,
                              ),
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
    );
  }
}

class _CancelServiceDialog extends StatelessWidget {
  const _CancelServiceDialog({
    required this.item,
  });

  final RegisteredServiceItem item;

  ServiceOverview get service => item.service;
  ServiceBooking get booking => item.booking;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 440,
        ),
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
                    borderRadius:
                        BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.undo_rounded,
                    color: Color(0xFFBE123C),
                    size: 29,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hủy đăng ký dịch vụ?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  booking.isPending
                      ? 'Yêu cầu đang chờ xác nhận sẽ được thu hồi.'
                      : 'Dịch vụ đang sử dụng sẽ được hủy khỏi danh sách của bạn.',
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
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius:
                        BorderRadius.circular(15),
                    border: Border.all(
                      color: AppColors.borderGray,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.primary
                              .withValues(alpha: 0.09),
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _ServiceScreenState._iconFor(
                            service.name,
                          ),
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          service.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w700,
                            color:
                                AppColors.textDark,
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
                            Navigator.pop(
                          context,
                          false,
                        ),
                        style:
                            OutlinedButton.styleFrom(
                          foregroundColor:
                              AppColors.secondary,
                          side: const BorderSide(
                            color:
                                Color(0xFFCBD5E1),
                          ),
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Giữ dịch vụ',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            Navigator.pop(
                          context,
                          true,
                        ),
                        icon: const Icon(
                          Icons.undo_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'Xác nhận hủy',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFBE123C),
                          foregroundColor:
                              Colors.white,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
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
    );
  }
}

class _ServiceDetailSection extends StatelessWidget {
  const _ServiceDetailSection({
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
          color: AppColors.borderGray.withValues(
            alpha: 0.75,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius:
                  BorderRadius.circular(11),
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

class _PriceTile extends StatelessWidget {
  const _PriceTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(
          alpha: 0.06,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.primary.withValues(
            alpha: 0.13,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.backgroundColor,
    required this.textColor,
  });

  final Color backgroundColor;
  final Color textColor;
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
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.borderGray,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 29,
                  color: Color(0xFFBE123C),
                ),
              ),
              const SizedBox(height: 13),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 18,
                ),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(13),
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

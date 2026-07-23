import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ecohome_app/core/constants/app_colors.dart';
import 'package:ecohome_app/features/auth/data/auth_api.dart';
import 'package:ecohome_app/features/auth/data/auth_session.dart';
import 'package:ecohome_app/features/notification/data/notification_api.dart';
import 'package:ecohome_app/features/notification/data/notification_item.dart';

class AppHeader extends StatefulWidget {
  const AppHeader({super.key});

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  final NotificationApi _api = NotificationApi();
  final LayerLink _notificationLink = LayerLink();

  OverlayEntry? _notificationOverlay;
  Timer? _refreshTimer;

  List<AppNotificationItem> _notifications = const [];
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _errorMessage;

  int get _unreadCount {
    return _notifications
        .where((notification) => notification.isUnread)
        .length;
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadNotifications(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _removeNotificationOverlay();
    super.dispose();
  }

  Future<void> _loadNotifications({
    bool silent = false,
  }) async {
    if (!silent && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final notifications =
          await _api.getMyNotifications();

      if (!mounted) return;

      setState(() {
        _notifications = notifications;
        _isLoading = false;
        _errorMessage = null;
      });

      _notificationOverlay?.markNeedsBuild();
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });

      _notificationOverlay?.markNeedsBuild();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải thông báo.';
      });

      _notificationOverlay?.markNeedsBuild();
    }
  }

  void _toggleNotifications() {
    if (_notificationOverlay != null) {
      _removeNotificationOverlay();
      return;
    }

    _showNotificationOverlay();
    _loadNotifications(silent: true);
  }

  void _showNotificationOverlay() {
    final overlay = Overlay.of(context);

    _notificationOverlay = OverlayEntry(
      builder: (overlayContext) {
        final screenWidth =
            MediaQuery.of(overlayContext).size.width;

        final panelWidth = math.min(
          390.0,
          screenWidth - 24,
        );

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeNotificationOverlay,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _notificationLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 8),
              child: Material(
                color: Colors.transparent,
                child: _NotificationDropdown(
                  width: panelWidth,
                  notifications: _notifications,
                  unreadCount: _unreadCount,
                  isLoading: _isLoading,
                  isUpdating: _isUpdating,
                  errorMessage: _errorMessage,
                  onRefresh: () =>
                      _loadNotifications(),
                  onMarkAllRead: _markAllAsRead,
                  onNotificationTap:
                      _openNotification,
                  onClose:
                      _removeNotificationOverlay,
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_notificationOverlay!);
  }

  void _removeNotificationOverlay() {
    _notificationOverlay?.remove();
    _notificationOverlay = null;
  }

  Future<void> _openNotification(
    AppNotificationItem notification,
  ) async {
    var selectedNotification = notification;

    if (notification.isUnread) {
      try {
        selectedNotification =
            await _api.markAsRead(notification);

        if (!mounted) return;

        setState(() {
          _notifications = _notifications
              .map(
                (item) =>
                    item.notificationId ==
                            selectedNotification
                                .notificationId
                        ? selectedNotification
                        : item,
              )
              .toList();
        });

        _notificationOverlay?.markNeedsBuild();
      } on ApiException catch (error) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
        return;
      }
    }

    if (!mounted) return;

    _removeNotificationOverlay();

    await showDialog<void>(
      context: context,
      barrierColor:
          AppColors.primary.withValues(alpha: 0.18),
      builder: (context) =>
          _NotificationDetailDialog(
        notification: selectedNotification,
      ),
    );
  }

  Future<void> _markAllAsRead() async {
    if (_unreadCount == 0 || _isUpdating) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });
    _notificationOverlay?.markNeedsBuild();

    try {
      final notifications =
          await _api.markAllAsRead(_notifications);

      if (!mounted) return;

      setState(() {
        _notifications = notifications;
        _isUpdating = false;
      });

      _notificationOverlay?.markNeedsBuild();
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _isUpdating = false;
      });
      _notificationOverlay?.markNeedsBuild();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName =
        AuthSession.fullName?.trim();

    return Padding(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: 0.10,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    fullName == null ||
                            fullName.isEmpty
                        ? 'EcoHome Resident'
                        : fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CompositedTransformTarget(
            link: _notificationLink,
            child: _NotificationBell(
              unreadCount: _unreadCount,
              onPressed: _toggleNotifications,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({
    required this.unreadCount,
    required this.onPressed,
  });

  final int unreadCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.primary.withValues(
            alpha: 0.08,
          ),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.notifications_none_rounded,
                size: 26,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            right: -2,
            top: -3,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 19,
                minHeight: 19,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFBE123C),
                borderRadius:
                    BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: Text(
                unreadCount > 99
                    ? '99+'
                    : unreadCount.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationDropdown extends StatelessWidget {
  const _NotificationDropdown({
    required this.width,
    required this.notifications,
    required this.unreadCount,
    required this.isLoading,
    required this.isUpdating,
    required this.errorMessage,
    required this.onRefresh,
    required this.onMarkAllRead,
    required this.onNotificationTap,
    required this.onClose,
  });

  final double width;
  final List<AppNotificationItem> notifications;
  final int unreadCount;
  final bool isLoading;
  final bool isUpdating;
  final String? errorMessage;
  final VoidCallback onRefresh;
  final VoidCallback onMarkAllRead;
  final ValueChanged<AppNotificationItem>
      onNotificationTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: const BoxConstraints(
        maxHeight: 500,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A)
                .withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              16,
              14,
              10,
              14,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(
                alpha: 0.07,
              ),
              border: const Border(
                bottom: BorderSide(
                  color: Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông báo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        unreadCount == 0
                            ? 'Không có thông báo chưa đọc'
                            : '$unreadCount thông báo chưa đọc',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Làm mới',
                  onPressed: onRefresh,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng',
                  onPressed: onClose,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          if (unreadCount > 0)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: isUpdating
                    ? null
                    : onMarkAllRead,
                icon: isUpdating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.done_all_rounded,
                        size: 17,
                      ),
                label: const Text(
                  'Đánh dấu tất cả đã đọc',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Flexible(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading && notifications.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage != null &&
        notifications.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFBE123C),
                  size: 34,
                ),
                const SizedBox(height: 10),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onRefresh,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (notifications.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  color: AppColors.primary,
                  size: 38,
                ),
                SizedBox(height: 10),
                Text(
                  'Chưa có thông báo',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Thông báo từ ban quản lý, sự cố và thanh toán sẽ xuất hiện tại đây.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(
        10,
        4,
        10,
        12,
      ),
      itemCount: notifications.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final notification = notifications[index];

        return _NotificationTile(
          key: ValueKey(
            notification.notificationId,
          ),
          notification: notification,
          onTap: () =>
              onNotificationTap(notification),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final AppNotificationItem notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style =
        _NotificationVisual.from(notification.type);

    return Material(
      color: notification.isUnread
          ? style.backgroundColor
          : Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: style.iconBackgroundColor,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  style.icon,
                  color: style.iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.3,
                              fontWeight:
                                  notification.isUnread
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                              color:
                                  AppColors.textDark,
                            ),
                          ),
                        ),
                        if (notification.isUnread) ...[
                          const SizedBox(width: 7),
                          Container(
                            width: 8,
                            height: 8,
                            margin:
                                const EdgeInsets.only(
                              top: 4,
                            ),
                            decoration:
                                const BoxDecoration(
                              color:
                                  AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.8,
                        height: 1.4,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                style.iconBackgroundColor,
                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),
                          ),
                          child: Text(
                            style.label,
                            style: TextStyle(
                              fontSize: 9.8,
                              fontWeight:
                                  FontWeight.w700,
                              color: style.iconColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatRelativeTime(
                            notification.createdDate,
                          ),
                          style: const TextStyle(
                            fontSize: 10.5,
                            color:
                                AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationDetailDialog
    extends StatelessWidget {
  const _NotificationDetailDialog({
    required this.notification,
  });

  final AppNotificationItem notification;

  @override
  Widget build(BuildContext context) {
    final style =
        _NotificationVisual.from(notification.type);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 480,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  17,
                  12,
                  17,
                ),
                color: AppColors.primary.withValues(
                  alpha: 0.07,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color:
                            style.iconBackgroundColor,
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      child: Icon(
                        style.icon,
                        color: style.iconColor,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            style.label,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight:
                                  FontWeight.w700,
                              color: style.iconColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            notification.title,
                            style: const TextStyle(
                              fontSize: 17,
                              height: 1.25,
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
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  20,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius:
                            BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        notification.description,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.55,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatFullDate(
                            notification.createdDate,
                          ),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color:
                                AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationVisual {
  const _NotificationVisual({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Color backgroundColor;

  factory _NotificationVisual.from(
    AppNotificationType type,
  ) {
    switch (type) {
      case AppNotificationType.incident:
        return const _NotificationVisual(
          icon: Icons.report_problem_outlined,
          label: 'Báo cáo sự cố',
          iconColor: Color(0xFFB45309),
          iconBackgroundColor: Color(0xFFFEF3C7),
          backgroundColor: Color(0xFFFFFBEB),
        );
      case AppNotificationType.payment:
        return const _NotificationVisual(
          icon: Icons.payments_outlined,
          label: 'Thanh toán',
          iconColor: Color(0xFF15803D),
          iconBackgroundColor: Color(0xFFDCFCE7),
          backgroundColor: Color(0xFFF0FDF4),
        );
      case AppNotificationType.management:
        return _NotificationVisual(
          icon: Icons.campaign_outlined,
          label: 'Ban quản lý',
          iconColor: AppColors.primary,
          iconBackgroundColor:
              AppColors.primary.withValues(
            alpha: 0.10,
          ),
          backgroundColor:
              AppColors.primary.withValues(
            alpha: 0.045,
          ),
        );
    }
  }
}

String _formatRelativeTime(DateTime? date) {
  if (date == null) {
    return '--';
  }

  final local = date.toLocal();
  final now = DateTime.now();
  final difference = now.difference(local);

  if (difference.isNegative) {
    return 'Vừa xong';
  }

  if (difference.inMinutes < 1) {
    return 'Vừa xong';
  }

  if (difference.inMinutes < 60) {
    return '${difference.inMinutes} phút trước';
  }

  if (difference.inHours < 24) {
    return '${difference.inHours} giờ trước';
  }

  if (difference.inDays < 7) {
    return '${difference.inDays} ngày trước';
  }

  return '${_twoDigits(local.day)}/'
      '${_twoDigits(local.month)}/'
      '${local.year}';
}

String _formatFullDate(DateTime? date) {
  if (date == null) {
    return '--';
  }

  final local = date.toLocal();

  return '${_twoDigits(local.day)}/'
      '${_twoDigits(local.month)}/'
      '${local.year} lúc '
      '${_twoDigits(local.hour)}:'
      '${_twoDigits(local.minute)}';
}

String _twoDigits(int value) {
  return value.toString().padLeft(2, '0');
}

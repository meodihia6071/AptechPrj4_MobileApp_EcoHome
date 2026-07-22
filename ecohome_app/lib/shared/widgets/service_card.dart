import 'package:flutter/material.dart';
import 'package:ecohome_app/core/constants/app_colors.dart';

class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.statusText,
    required this.statusBackgroundColor,
    required this.statusTextColor,
    required this.firstLabel,
    required this.firstValue,
    required this.secondLabel,
    required this.secondValue,
    required this.primaryActionText,
    required this.onPrimaryPressed,
    required this.onDetailPressed,
    this.primaryActionIcon = Icons.add_rounded,
    this.primaryActionForegroundColor = AppColors.primary,
    this.primaryActionBackgroundColor = const Color(0xFFEFF6FF),
    this.primaryActionBorderColor = const Color(0xFFBFDBFE),
  });

  final IconData icon;
  final String title;
  final String subtitle;

  final String statusText;
  final Color statusBackgroundColor;
  final Color statusTextColor;

  final String firstLabel;
  final String firstValue;
  final String secondLabel;
  final String secondValue;

  final String primaryActionText;
  final IconData primaryActionIcon;
  final Color primaryActionForegroundColor;
  final Color primaryActionBackgroundColor;
  final Color primaryActionBorderColor;

  final VoidCallback? onPrimaryPressed;
  final VoidCallback onDetailPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.borderGray,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 5,
              decoration: const BoxDecoration(
                color: AppColors.primary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                15,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(
                            alpha: 0.09,
                          ),
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        child: Icon(
                          icon,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.25,
                                fontWeight:
                                    FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.4,
                                color:
                                    AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: statusBackgroundColor,
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 7,
                            color: statusTextColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight:
                                  FontWeight.w700,
                              color: statusTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _InfoColumn(
                            label: firstLabel,
                            value: firstValue,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 38,
                          color: AppColors.borderGray,
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: _InfoColumn(
                            label: secondLabel,
                            value: secondValue,
                            alignEnd: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _ServiceActionButton(
                          icon:
                              Icons.visibility_outlined,
                          label: 'Chi tiết',
                          foregroundColor:
                              AppColors.primary,
                          backgroundColor:
                              AppColors.primary.withValues(
                            alpha: 0.07,
                          ),
                          borderColor:
                              AppColors.primary.withValues(
                            alpha: 0.16,
                          ),
                          onPressed:
                              onDetailPressed,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ServiceActionButton(
                          icon: primaryActionIcon,
                          label: primaryActionText,
                          foregroundColor:
                              primaryActionForegroundColor,
                          backgroundColor:
                              primaryActionBackgroundColor,
                          borderColor:
                              primaryActionBorderColor,
                          onPressed:
                              onPrimaryPressed,
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
    );
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          textAlign:
              alignEnd ? TextAlign.right : TextAlign.left,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign:
              alignEnd ? TextAlign.right : TextAlign.left,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}

class _ServiceActionButton extends StatelessWidget {
  const _ServiceActionButton({
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
    final disabled = onPressed == null;

    return Material(
      color: disabled
          ? const Color(0xFFF1F5F9)
          : backgroundColor,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: disabled
                  ? AppColors.borderGray
                  : borderColor,
            ),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: disabled
                    ? const Color(0xFF94A3B8)
                    : foregroundColor,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: disabled
                        ? const Color(0xFF94A3B8)
                        : foregroundColor,
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

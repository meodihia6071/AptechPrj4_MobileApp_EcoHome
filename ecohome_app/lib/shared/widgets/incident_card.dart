import 'package:flutter/material.dart';
import 'package:ecohome_app/core/constants/app_colors.dart';

class IncidentCard extends StatelessWidget {
  final String statusLabel;
  final Color statusColor;
  final Color textColor;
  final String id;
  final String time;
  final String title;
  final String desc;
  final Widget? bottomLeftWidget;
  final Widget actionWidget;

  const IncidentCard({
    super.key,
    required this.statusLabel,
    required this.statusColor,
    required this.textColor,
    required this.id,
    required this.time,
    required this.title,
    required this.desc,
    this.bottomLeftWidget,
    required this.actionWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                id,
                style: const TextStyle(fontSize: 12, color: Colors.black26),
              ),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.secondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              bottomLeftWidget ?? const SizedBox.shrink(),
              actionWidget,
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:ecohome_app/core/constants/app_colors.dart';

class MemberCard extends StatelessWidget {
  final String name;
  final String role; 
  final String? phone;
  final String? email;
  final bool isOwner; 

  const MemberCard({
    super.key,
    required this.name,
    required this.role,
    this.phone,
    this.email,
    this.isOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOwner) {
      // --- GIAO DIỆN RIÊNG CHO CHỦ HỘ 
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: const Border(left: BorderSide(color: AppColors.primary, width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 35,
              backgroundColor: Color(0xFFE2E8F0),
              child: Icon(Icons.person_rounded, size: 40, color: AppColors.secondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, color: AppColors.primary, size: 18),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(phone ?? '', style: const TextStyle(fontSize: 13, color: AppColors.secondary)),
                  Text(email ?? '', style: const TextStyle(fontSize: 13, color: AppColors.secondary)),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // --- GIAO DIỆN CHO THÀNH VIÊN KHÁC 
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 26,
              backgroundColor: Color(0xFFF1F5F9),
              child: Icon(Icons.person_rounded, size: 28, color: AppColors.secondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  Text(role, style: const TextStyle(fontSize: 13, color: AppColors.secondary)),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert, color: AppColors.secondary),
            ),
          ],
        ),
      );
    }
  }
}
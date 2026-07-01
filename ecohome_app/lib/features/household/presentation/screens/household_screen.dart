import 'package:flutter/material.dart';
import 'package:ecohome_app/core/constants/app_colors.dart';
import 'package:ecohome_app/shared/widgets/app_header.dart';
import 'package:ecohome_app/shared/widgets/member_card.dart';

class HouseholdScreen extends StatelessWidget {
  const HouseholdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeader(),
            const SizedBox(height: 24),
            
            // Tiêu đề trang
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hộ gia đình', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  SizedBox(height: 4),
                  Text('Quản lý thông tin các thành viên trong căn hộ của bạn.', style: TextStyle(fontSize: 14, color: AppColors.secondary)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- MỤC CHỦ HỘ ---
                    const Text('CHỦ HỘ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.secondary, letterSpacing: 1.2)),
                    const SizedBox(height: 12),
                    const MemberCard(
                      isOwner: true,
                      name: 'Nguyễn Văn An',
                      phone: '090 123 4567',
                      email: 'an.nguyen@example.com',
                      role: 'Chủ hộ',
                    ),
                    
                    const SizedBox(height: 32),

                    // --- MỤC THÀNH VIÊN KHÁC ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('THÀNH VIÊN KHÁC (2)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.secondary, letterSpacing: 1.2)),
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Thêm mới', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: const [
                          MemberCard(name: 'Trần Thị Bích', role: 'Vợ / Chồng'),
                          MemberCard(name: 'Nguyễn Trần Bảo', role: 'Con cái'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
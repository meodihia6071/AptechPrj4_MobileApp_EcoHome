import 'package:flutter/material.dart';
import 'package:ecohome_app/core/constants/app_colors.dart';
import 'package:ecohome_app/shared/widgets/app_header.dart';
import 'package:ecohome_app/features/household/presentation/screens/household_screen.dart';
import 'package:ecohome_app/features/apartment/presentation/screens/apartment_detail_screen.dart';

class HomeDashboardBody extends StatelessWidget {
  final Function(int)? onTabChanged;

  const HomeDashboardBody({super.key, this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Xin chào, Nguyễn Văn A',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Căn hộ A-1205 • Tòa tháp Sapphire',
                    style: TextStyle(fontSize: 14, color: AppColors.secondary),
                  ),
                  const SizedBox(height: 24),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.4,
                    children: [
                      _buildMenuCard(
                        context,
                        'Căn hộ',
                        'Thông tin',
                        Icons.apartment_rounded,
                        const Color(0xFFE0E7FF),
                        AppColors.primary,
                      ),
                      _buildMenuCard(
                        context,
                        'Hộ gia đình',
                        'Thành viên',
                        Icons.groups_rounded,
                        const Color(0xFFDCFCE7),
                        AppColors.tertiary,
                      ),
                      _buildMenuCard(
                        context,
                        'Báo cáo sự cố',
                        'Gửi yêu cầu',
                        Icons.report_problem_rounded,
                        const Color(0xFFFFE4E6),
                        Colors.redAccent,
                      ),
                      _buildMenuCard(
                        context,
                        'Dịch vụ',
                        'Tiện ích',
                        Icons.widgets_rounded,
                        const Color(0xFFF1F5F9),
                        const Color(0xFF1E293B),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Hóa đơn cần thanh toán',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text(
                                'Xem tất cả',
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBFA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFEE2E2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.receipt_long_rounded,
                                  color: Colors.redAccent,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Phí quản lý tháng 10',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Hạn chót: Hôm nay',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Text(
                                '1.250.000đ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    String subTitle,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    return GestureDetector(
      onTap: () {
        if (title == 'Căn hộ') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ApartmentDetailScreen(),
            ),
          );
        } else if (title == 'Hộ gia đình') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HouseholdScreen()),
          );
        } else if (title == 'Báo cáo sự cố') {
          onTabChanged?.call(1);
        } else if (title == 'Dịch vụ') {
          onTabChanged?.call(2);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              subTitle,
              style: const TextStyle(fontSize: 11, color: AppColors.secondary),
            ),
          ],
        ),
      ),
    );
  }
}

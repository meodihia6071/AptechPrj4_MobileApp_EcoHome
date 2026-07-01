import 'package:flutter/material.dart';
import 'package:ecohome_app/core/constants/app_colors.dart';
import 'package:ecohome_app/shared/widgets/app_header.dart';
import 'package:ecohome_app/shared/widgets/service_card.dart';

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  int _activeTabIndex = 0; // 0: Đã đăng ký, 1: Chưa đăng ký

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppHeader(),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'Quản lý dịch vụ',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Custom Tab Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9), // Nền xám nhạt
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildTabOption(0, 'Đã đăng ký'),
                  _buildTabOption(1, 'Chưa đăng ký'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Danh sách dịch vụ
          Expanded(
            child: _activeTabIndex == 0
                ? ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    children: [
                      ServiceCard(
                        icon: Icons.cleaning_services_rounded,
                        title: 'Dọn dẹp định kỳ',
                        subtitle: 'Gói hàng tuần',
                        statusText: 'Đang hoạt động',
                        nextPaymentDate: '15/11/2023',
                        fee: '500.000đ',
                        onDetailPressed: () {},
                        onCancelPressed: () {},
                      ),
                      ServiceCard(
                        icon: Icons.directions_car_rounded,
                        title: 'Gửi ô tô tháng',
                        subtitle: 'Biển số: 30A-123.45',
                        statusText: 'Đang hoạt động',
                        nextPaymentDate: '01/12/2023',
                        fee: '1.500.000đ',
                        onDetailPressed: () {},
                        onCancelPressed: () {},
                      ),
                    ],
                  )
                : const Center(
                    child: Text(
                      'Bạn chưa có dịch vụ nào mới',
                      style: TextStyle(color: AppColors.secondary),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabOption(int index, String title) {
    bool isActive = _activeTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              color: isActive ? AppColors.primary : AppColors.secondary,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
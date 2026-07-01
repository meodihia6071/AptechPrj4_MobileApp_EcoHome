import 'package:flutter/material.dart';
import 'package:ecohome_app/core/constants/app_colors.dart';
import 'package:ecohome_app/shared/widgets/custom_bottom_nav_item.dart';
import 'package:ecohome_app/features/home/presentation/screens/home_dashboard_body.dart';
import 'package:ecohome_app/features/incident/presentation/screens/incident_screen.dart';
import 'package:ecohome_app/features/service/presentation/screens/service_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final GlobalKey<NavigatorState> _homeNavigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      Navigator(
        key: _homeNavigatorKey,
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const HomeDashboardBody(),
          );
        },
      ),
      const IncidentScreen(),
      const ServiceScreen(),
      const Center(child: Text('Màn hình Tài khoản (Đang phát triển)')),
    ];

    return Scaffold(
      backgroundColor: AppColors.neutralBg,
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            CustomBottomNavItem(
              icon: Icons.home_rounded,
              label: 'Trang chủ',
              isSelected: _selectedIndex == 0,
              onTap: () {
                if (_selectedIndex == 0) {
                  if (_homeNavigatorKey.currentState?.canPop() ?? false) {
                    _homeNavigatorKey.currentState?.popUntil(
                      (route) => route.isFirst,
                    );
                  }
                } else {
                  setState(() {
                    _selectedIndex = 0;
                  });
                }
              },
            ),
            CustomBottomNavItem(
              icon: Icons.report_problem_rounded,
              label: 'Báo cáo',
              isSelected: _selectedIndex == 1,
              onTap: () => setState(() => _selectedIndex = 1),
            ),
            CustomBottomNavItem(
              icon: Icons.widgets_rounded,
              label: 'Dịch vụ',
              isSelected: _selectedIndex == 2,
              onTap: () => setState(() => _selectedIndex = 2),
            ),
            CustomBottomNavItem(
              icon: Icons.person_rounded,
              label: 'Tài khoản',
              isSelected: _selectedIndex == 3,
              onTap: () => setState(() => _selectedIndex = 3),
            ),
          ],
        ),
      ),
    );
  }
}

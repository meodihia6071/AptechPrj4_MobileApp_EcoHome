import 'package:flutter/material.dart';
import 'package:ecohome_app/core/constants/app_colors.dart';
import 'package:ecohome_app/shared/widgets/app_header.dart';
import 'package:ecohome_app/features/household/presentation/screens/household_screen.dart';
import 'package:ecohome_app/features/apartment/presentation/screens/apartment_detail_screen.dart';
import 'package:ecohome_app/features/auth/data/auth_session.dart';
import 'package:ecohome_app/features/home/data/rent_invoice.dart';
import 'package:ecohome_app/features/home/data/rent_invoice_api.dart';
import 'package:intl/intl.dart';

class HomeDashboardBody extends StatefulWidget {
  final Function(int)? onTabChanged;

  const HomeDashboardBody({super.key, this.onTabChanged});

  @override
  State<HomeDashboardBody> createState() => _HomeDashboardBodyState();
}

class _HomeDashboardBodyState extends State<HomeDashboardBody> {
  final _invoiceApi = RentInvoiceApi();
  late Future<List<RentInvoice>> _invoices;

  @override
  void initState() {
    super.initState();
    _invoices = _invoiceApi.getPendingRentInvoices();
  }

  void _reloadInvoices() =>
      setState(() => _invoices = _invoiceApi.getPendingRentInvoices());

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
                  Text(
                    'Xin chào, ${AuthSession.fullName ?? 'Cư dân'}',
                    style: const TextStyle(
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

                  _RentInvoicesSection(
                    invoices: _invoices,
                    onRetry: _reloadInvoices,
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
          widget.onTabChanged?.call(1);
        } else if (title == 'Dịch vụ') {
          widget.onTabChanged?.call(2);
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

class _RentInvoicesSection extends StatelessWidget {
  const _RentInvoicesSection({required this.invoices, required this.onRetry});

  final Future<List<RentInvoice>> invoices;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Hóa đơn cần thanh toán',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<RentInvoice>>(
          future: invoices,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.hasError) {
              return Row(
                children: [
                  const Expanded(child: Text('Không thể tải hóa đơn.')),
                  IconButton(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              );
            }
            final items = snapshot.data ?? const [];
            if (items.isEmpty) {
              return const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green),
                  SizedBox(width: 10),
                  Expanded(child: Text('Không có tiền thuê cần thanh toán.')),
                ],
              );
            }
            return Column(
              children: items
                  .map(
                    (invoice) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RentInvoiceCard(invoice: invoice),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    ),
  );
}

class _RentInvoiceCard extends StatelessWidget {
  const _RentInvoiceCard({required this.invoice});

  final RentInvoice invoice;

  @override
  Widget build(BuildContext context) {
    final deadline = DateFormat('dd/MM/yyyy').format(invoice.deadline);
    final remaining = invoice.daysRemaining == 0
        ? 'Hạn chót hôm nay'
        : 'Còn ${invoice.daysRemaining} ngày';
    return Container(
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tiền thuê phòng ${invoice.roomNumber}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '$remaining • Hạn $deadline',
                  style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                ),
              ],
            ),
          ),
          Text(
            '${NumberFormat('#,##0', 'vi_VN').format(invoice.amount)} đ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

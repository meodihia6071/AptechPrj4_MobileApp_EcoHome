import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../apartment/presentation/screens/apartment_detail_screen.dart';
import '../../../auth/data/auth_session.dart';
import '../../../household/presentation/screens/household_screen.dart';
import '../../../payment/data/payment_api.dart';
import '../../../payment/data/payment_invoice.dart';
import '../../../payment/presentation/screens/payment_checkout_screen.dart';

class HomeDashboardBody extends StatefulWidget {
  const HomeDashboardBody({super.key, this.onTabChanged});

  final Function(int)? onTabChanged;

  @override
  State<HomeDashboardBody> createState() => _HomeDashboardBodyState();
}

class _HomeDashboardBodyState extends State<HomeDashboardBody> {
  final _invoiceApi = PaymentApi();
  late Future<List<PaymentInvoice>> _invoices;

  @override
  void initState() {
    super.initState();
    _invoices = _invoiceApi.getMyInvoices();
  }

  void _reloadInvoices() =>
      setState(() => _invoices = _invoiceApi.getMyInvoices());

  Future<void> _openCheckout(List<PaymentInvoice> invoices) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentCheckoutScreen(invoices: invoices),
      ),
    );
    if (changed == true) _reloadInvoices();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _reloadInvoices();
                await _invoices;
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
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
                      'Chào mừng bạn trở lại EcoHome',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.secondary,
                      ),
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
                        _menuCard(
                          title: 'Căn hộ',
                          subtitle: 'Thông tin',
                          icon: Icons.apartment_rounded,
                          background: const Color(0xFFE0E7FF),
                          iconColor: AppColors.primary,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ApartmentDetailScreen(),
                            ),
                          ),
                        ),
                        _menuCard(
                          title: 'Hộ gia đình',
                          subtitle: 'Thành viên',
                          icon: Icons.groups_rounded,
                          background: const Color(0xFFDCFCE7),
                          iconColor: AppColors.tertiary,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HouseholdScreen(),
                            ),
                          ),
                        ),
                        _menuCard(
                          title: 'Báo cáo sự cố',
                          subtitle: 'Gửi yêu cầu',
                          icon: Icons.report_problem_rounded,
                          background: const Color(0xFFFFE4E6),
                          iconColor: Colors.redAccent,
                          onTap: () => widget.onTabChanged?.call(1),
                        ),
                        _menuCard(
                          title: 'Dịch vụ',
                          subtitle: 'Tiện ích',
                          icon: Icons.widgets_rounded,
                          background: const Color(0xFFF1F5F9),
                          iconColor: const Color(0xFF1E293B),
                          onTap: () => widget.onTabChanged?.call(2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _PaymentInvoicesSection(
                      invoices: _invoices,
                      onRetry: _reloadInvoices,
                      onCheckout: _openCheckout,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color background,
    required Color iconColor,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .02),
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
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.secondary),
          ),
        ],
      ),
    ),
  );
}

class _PaymentInvoicesSection extends StatelessWidget {
  const _PaymentInvoicesSection({
    required this.invoices,
    required this.onRetry,
    required this.onCheckout,
  });

  final Future<List<PaymentInvoice>> invoices;
  final VoidCallback onRetry;
  final ValueChanged<List<PaymentInvoice>> onCheckout;

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
          'HÓA ĐƠN CỦA BẠN',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<PaymentInvoice>>(
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
            final items = (snapshot.data ?? const <PaymentInvoice>[])
                .where((item) => item.isOutstanding)
                .toList();
            if (items.isEmpty) {
              return const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green),
                  SizedBox(width: 10),
                  Expanded(child: Text('Không có hóa đơn cần thanh toán.')),
                ],
              );
            }
            final payable = items.where((item) => item.canCheckout).toList();
            final total = items.fold<double>(
              0,
              (sum, item) => sum + item.amount,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${items.length} khoản chưa hoàn tất'),
                    Text(
                      _money(total),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...items.map(
                  (invoice) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PaymentInvoiceCard(invoice: invoice),
                  ),
                ),
                if (payable.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () => onCheckout(payable),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.payment_rounded),
                      label: Text('Thanh toán ${payable.length} hóa đơn'),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    ),
  );
}

class _PaymentInvoiceCard extends StatelessWidget {
  const _PaymentInvoiceCard({required this.invoice});

  final PaymentInvoice invoice;

  @override
  Widget build(BuildContext context) {
    final deadline = DateFormat('dd/MM/yyyy').format(invoice.deadline);
    final isOverdue = invoice.status == PaymentInvoiceStatus.overdue;
    final color = isOverdue ? Colors.redAccent : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOverdue ? const Color(0xFFFFFBFA) : const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue ? const Color(0xFFFEE2E2) : AppColors.borderGray,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isOverdue
                  ? const Color(0xFFFEE2E2)
                  : const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              invoice.type == PaymentInvoiceType.rent
                  ? Icons.apartment_rounded
                  : Icons.cleaning_services_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${invoice.roomNumber == null ? '' : 'Căn ${invoice.roomNumber} • '}Hạn $deadline',
                  style: TextStyle(fontSize: 12, color: color),
                ),
                const SizedBox(height: 3),
                _StatusLabel(status: invoice.status),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _money(invoice.amount),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status});

  final PaymentInvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      PaymentInvoiceStatus.awaitingBankTransfer => (
        'Chờ xác nhận chuyển khoản',
        Colors.orange,
      ),
      PaymentInvoiceStatus.awaitingCashConfirmation => (
        'Chờ thanh toán tại Ban quản lý',
        Colors.orange,
      ),
      PaymentInvoiceStatus.overdue => ('Quá hạn', Colors.redAccent),
      _ => ('Chưa thanh toán', AppColors.primary),
    };
    return Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
    );
  }
}

String _money(double value) =>
    '${NumberFormat('#,##0', 'vi_VN').format(value)} đ';

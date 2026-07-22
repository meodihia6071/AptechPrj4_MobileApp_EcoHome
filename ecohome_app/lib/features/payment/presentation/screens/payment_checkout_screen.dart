import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/data/auth_api.dart';
import '../../data/payment_api.dart';
import '../../data/payment_invoice.dart';

class PaymentCheckoutScreen extends StatefulWidget {
  const PaymentCheckoutScreen({
    required this.invoices,
    super.key,
    this.roomNumber,
  });

  final List<PaymentInvoice> invoices;
  final String? roomNumber;

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  final _api = PaymentApi();
  final _selectedIds = <String>{};
  PaymentMethod _method = PaymentMethod.bankTransfer;
  bool _loading = false;
  CheckoutResult? _result;

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(
      widget.invoices
          .where((item) => item.canCheckout)
          .map((item) => item.paymentId),
    );
  }

  List<PaymentInvoice> get _selected => widget.invoices
      .where((item) => _selectedIds.contains(item.paymentId))
      .toList();

  double get _total => _selected.fold(0, (sum, item) => sum + item.amount);

  Future<void> _checkout() async {
    if (_selectedIds.isEmpty || _loading) return;
    setState(() => _loading = true);
    try {
      final result = await _api.checkout(
        paymentIds: _selectedIds.toList(),
        method: _method,
      );
      if (mounted) setState(() => _result = result);
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return _PaymentResultView(
        result: _result!,
        method: _method,
        onDone: () => Navigator.pop(context, true),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.neutralBg,
      appBar: AppBar(
        title: Text(
          widget.roomNumber == null
              ? 'Thanh toán hóa đơn'
              : 'Thanh toán căn ${widget.roomNumber}',
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'CHỌN HÓA ĐƠN',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...widget.invoices.map(_invoiceTile),
                  const SizedBox(height: 22),
                  const Text(
                    'PHƯƠNG THỨC THANH TOÁN',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _methodTile(
                    method: PaymentMethod.bankTransfer,
                    icon: Icons.account_balance_rounded,
                    title: 'Chuyển khoản ngân hàng',
                    subtitle: 'Thanh toán bằng mã QR hoặc thông tin tài khoản',
                  ),
                  const SizedBox(height: 10),
                  _methodTile(
                    method: PaymentMethod.cash,
                    icon: Icons.payments_outlined,
                    title: 'Tiền mặt tại Ban quản lý',
                    subtitle:
                        'Đăng ký trước và đến Ban quản lý để hoàn tất thanh toán',
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.borderGray)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_selectedIds.length} hóa đơn đã chọn'),
                      Text(
                        _money(_total),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _selectedIds.isEmpty || _loading
                          ? null
                          : _checkout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _method == PaymentMethod.cash
                                  ? 'Đăng ký thanh toán tiền mặt'
                                  : 'Tiếp tục chuyển khoản',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _invoiceTile(PaymentInvoice invoice) {
    final selected = _selectedIds.contains(invoice.paymentId);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      child: CheckboxListTile(
        value: selected,
        onChanged: invoice.canCheckout
            ? (value) => setState(() {
                if (value == true) {
                  _selectedIds.add(invoice.paymentId);
                } else {
                  _selectedIds.remove(invoice.paymentId);
                }
              })
            : null,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppColors.primary,
        title: Text(
          invoice.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${invoice.type == PaymentInvoiceType.rent ? 'Tiền phòng' : 'Dịch vụ'}'
          '${invoice.roomNumber == null ? '' : ' • Căn ${invoice.roomNumber}'}'
          '\nHạn ${DateFormat('dd/MM/yyyy').format(invoice.deadline)}',
        ),
        secondary: Text(
          _money(invoice.amount),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _methodTile({
    required PaymentMethod method,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _method == method;
    return InkWell(
      onTap: () => setState(() => _method = method),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderGray,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primary : AppColors.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentResultView extends StatelessWidget {
  const _PaymentResultView({
    required this.result,
    required this.method,
    required this.onDone,
  });

  final CheckoutResult result;
  final PaymentMethod method;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final bank = result.bankTransfer;
    final isCash = method == PaymentMethod.cash;
    return Scaffold(
      backgroundColor: AppColors.neutralBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Kết quả đăng ký'),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 72,
              color: Colors.green,
            ),
            const SizedBox(height: 14),
            Text(
              isCash
                  ? 'Đã đăng ký thanh toán tiền mặt'
                  : 'Đã tạo yêu cầu chuyển khoản',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isCash
                  ? 'Vui lòng đến Ban quản lý tòa nhà để thanh toán. Hóa đơn chỉ được ghi nhận đã thanh toán sau khi Ban quản lý xác nhận.'
                  : 'Vui lòng chuyển đúng số tiền và nội dung bên dưới. Hóa đơn đang chờ Ban quản lý xác nhận.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.secondary, height: 1.4),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderGray),
              ),
              child: Column(
                children: [
                  _detail('Tổng tiền', _money(result.totalAmount)),
                  const Divider(height: 24),
                  _copyableDetail(
                    context,
                    'Mã thanh toán',
                    result.referenceCode,
                  ),
                  if (isCash) ...[
                    const Divider(height: 24),
                    _detail('Địa điểm', 'Ban quản lý tòa nhà EcoHome'),
                    const Divider(height: 24),
                    _detail('Thời gian', '08:00–17:30, thứ Hai đến thứ Bảy'),
                  ] else ...[
                    if (bank?.qrCodeUrl?.isNotEmpty == true) ...[
                      const SizedBox(height: 18),
                      Image.network(
                        bank!.qrCodeUrl!,
                        height: 220,
                        errorBuilder: (_, _, _) => const Text(
                          'Không thể tải mã QR. Vui lòng dùng thông tin tài khoản.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const Divider(height: 24),
                    _detail('Ngân hàng', bank?.bankName ?? '—'),
                    const Divider(height: 24),
                    _copyableDetail(
                      context,
                      'Số tài khoản',
                      bank?.accountNumber ?? '—',
                    ),
                    const Divider(height: 24),
                    _detail('Chủ tài khoản', bank?.accountName ?? '—'),
                    const Divider(height: 24),
                    _copyableDetail(
                      context,
                      'Nội dung chuyển khoản',
                      bank?.transferContent ?? result.referenceCode,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Hoàn tất'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _detail(String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(label, style: const TextStyle(color: AppColors.secondary)),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    ],
  );

  static Widget _copyableDetail(
    BuildContext context,
    String label,
    String value,
  ) => Row(
    children: [
      Expanded(child: _detail(label, value)),
      IconButton(
        tooltip: 'Sao chép',
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: value));
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Đã sao chép')));
          }
        },
        icon: const Icon(Icons.copy_rounded, size: 19),
      ),
    ],
  );
}

String _money(double value) =>
    '${NumberFormat('#,##0', 'vi_VN').format(value)} đ';

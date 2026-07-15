import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/apartment_api.dart';
import '../../data/apartment_info.dart';

class ApartmentDetailScreen extends StatefulWidget {
  const ApartmentDetailScreen({super.key});

  @override
  State<ApartmentDetailScreen> createState() => _ApartmentDetailScreenState();
}

class _ApartmentDetailScreenState extends State<ApartmentDetailScreen> {
  final _api = ApartmentApi();
  late Future<ApartmentInfo> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.getCurrentApartment();
  }

  void _reload() => setState(() => _future = _api.getCurrentApartment());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralBg,
      appBar: AppBar(
        title: const Text('Thông tin căn hộ'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SafeArea(
        child: FutureBuilder<ApartmentInfo>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorView(
                message: snapshot.error.toString(),
                onRetry: _reload,
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                _reload();
                await _future;
              },
              child: _ApartmentContent(info: snapshot.requireData),
            );
          },
        ),
      ),
    );
  }
}

class _ApartmentContent extends StatelessWidget {
  const _ApartmentContent({required this.info});

  final ApartmentInfo info;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CĂN HỘ CỦA BẠN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  _TypeBadge(type: info.contractType),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                info.roomNumber,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _InfoTile(
                      icon: Icons.layers_outlined,
                      label: 'Tầng',
                      value: '${info.floor}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoTile(
                      icon: Icons.square_foot_rounded,
                      label: 'Diện tích',
                      value: '${_number(info.area)} m²',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'THÔNG TIN THANH TOÁN',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 18),
              _PaymentRow(
                label: info.primaryLabel,
                amount: _money(info.primaryAmount),
                dueDate: info.secondaryAmount == null ? info.nextDueDate : null,
              ),
              if (info.secondaryAmount != null) ...[
                const Divider(height: 32),
                _PaymentRow(
                  label: info.secondaryLabel!,
                  amount: _money(info.secondaryAmount!),
                  dueDate: info.nextDueDate,
                  highlighted: true,
                ),
              ],
            ],
          ),
        ),
        if (info.contractType == ContractType.installment) ...[
          const SizedBox(height: 12),
          const Text(
            'Kỳ trả góp được tính từ số tiền vay chia cho số tháng trong hợp đồng.',
            style: TextStyle(fontSize: 12, color: AppColors.secondary),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  static BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: .04),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static String _number(double value) =>
      NumberFormat('#,##0.##', 'vi_VN').format(value);
  static String _money(double value) =>
      '${NumberFormat('#,##0', 'vi_VN').format(value)} đ';
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.neutralBg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.secondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.label,
    required this.amount,
    this.dueDate,
    this.highlighted = false,
  });
  final String label;
  final String amount;
  final DateTime? dueDate;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: highlighted
              ? const Color(0xFFFFE4E6)
              : const Color(0xFFE0E7FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          highlighted ? Icons.schedule_rounded : Icons.payments_outlined,
          color: highlighted ? Colors.redAccent : AppColors.primary,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.secondary),
            ),
            if (dueDate != null)
              Text(
                'Hạn thanh toán: ${DateFormat('dd/MM/yyyy').format(dueDate!)}',
                style: const TextStyle(fontSize: 12, color: Colors.redAccent),
              ),
          ],
        ),
      ),
      Text(
        amount,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
    ],
  );
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final ContractType type;

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      ContractType.cash => 'Đã mua',
      ContractType.installment => 'Mua trả góp',
      ContractType.rental => 'Đang thuê',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.apartment_outlined,
            size: 56,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    ),
  );
}

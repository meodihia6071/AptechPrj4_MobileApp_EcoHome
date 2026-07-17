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
  late Future<List<ApartmentInfo>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.getApartments();
  }

  void _reload() => setState(() => _future = _api.getApartments());

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
        child: FutureBuilder<List<ApartmentInfo>>(
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
              child: _ApartmentContent(apartments: snapshot.requireData),
            );
          },
        ),
      ),
    );
  }
}

class _ApartmentContent extends StatefulWidget {
  const _ApartmentContent({required this.apartments});

  final List<ApartmentInfo> apartments;

  @override
  State<_ApartmentContent> createState() => _ApartmentContentState();
}

class _ApartmentContentState extends State<_ApartmentContent> {
  int _selectedIndex = 0;

  ApartmentInfo get info => widget.apartments[_selectedIndex];

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        if (widget.apartments.length > 1) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CĂN HỘ CỦA BẠN',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '${widget.apartments.length} căn hộ',
                style: const TextStyle(color: AppColors.secondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.apartments.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final apartment = widget.apartments[index];
                return _ApartmentSelector(
                  info: apartment,
                  selected: index == _selectedIndex,
                  onTap: () => setState(() => _selectedIndex = index),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
        ],
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
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.end,
                    children: [
                      _ResidentTypeBadge(type: info.residentType),
                      _TypeBadge(type: info.contractType),
                    ],
                  ),
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
        if (info.contractType == ContractType.rental) ...[
          const SizedBox(height: 16),
          _RentalPaymentNotice(info: info),
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

class _ApartmentSelector extends StatelessWidget {
  const _ApartmentSelector({
    required this.info,
    required this.selected,
    required this.onTap,
  });

  final ApartmentInfo info;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 142,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            info.roomNumber,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: selected ? AppColors.primary : AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${info.contractType == ContractType.rental ? 'Đang thuê' : 'Đã mua'} • Tầng ${info.floor}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.secondary),
          ),
        ],
      ),
    ),
  );
}

class _ResidentTypeBadge extends StatelessWidget {
  const _ResidentTypeBadge({required this.type});

  final int type;

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      0 => 'Chủ hộ',
      1 => 'Vợ/Chồng',
      2 => 'Con cái',
      3 => 'Người thuê',
      _ => 'Thành viên',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF047857),
        ),
      ),
    );
  }
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

class _RentalPaymentNotice extends StatelessWidget {
  const _RentalPaymentNotice({required this.info});

  final ApartmentInfo info;

  @override
  Widget build(BuildContext context) {
    final days = info.paymentCountdownDays;
    final isPaymentPeriod = days != null;
    final countdownText = days == 0
        ? 'Hôm nay là hạn cuối thanh toán'
        : 'Còn $days ngày đến hạn thanh toán';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPaymentPeriod
            ? const Color(0xFFFFF1F2)
            : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPaymentPeriod
              ? const Color(0xFFFDA4AF)
              : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPaymentPeriod
                ? Icons.timer_outlined
                : Icons.calendar_month_outlined,
            color: isPaymentPeriod ? Colors.redAccent : AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPaymentPeriod ? countdownText : 'Chưa đến kỳ thanh toán',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPaymentPeriod
                        ? Colors.redAccent
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Thời gian đóng tiền thuê: từ ngày 01 đến hết ngày 10 hằng tháng.',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
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

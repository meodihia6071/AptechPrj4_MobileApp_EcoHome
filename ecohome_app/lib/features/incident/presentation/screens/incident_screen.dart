import 'package:flutter/material.dart';
import 'package:ecohome_app/core/constants/app_colors.dart';
import 'package:ecohome_app/shared/widgets/app_header.dart';
import 'package:ecohome_app/shared/widgets/incident_card.dart';

class IncidentScreen extends StatefulWidget {
  const IncidentScreen({super.key});

  @override
  State<IncidentScreen> createState() => _IncidentScreenState();
}

class _IncidentScreenState extends State<IncidentScreen> {
  int _activeFilterIndex = 0;

  void _showCancelConfirmation(String incidentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Xác nhận thu hồi', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Bạn có chắc chắn muốn thu hồi báo cáo sự cố $incidentId không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy bỏ', style: TextStyle(color: AppColors.secondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã thu hồi báo cáo $incidentId thành công')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Xác nhận thu hồi'),
          ),
        ],
      ),
    );
  }

  void _showCreateIncidentForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20, left: 20, right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tạo báo cáo sự cố mới', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Tiêu đề sự cố', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'Ví dụ: Rò rỉ nước sảnh tầng 5',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Mô tả chi tiết', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Nhập nội dung sự cố bạn gặp phải...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gửi báo cáo sự cố thành công!')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: const Text('Gửi ban quản lý'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppHeader(),
          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Danh sách báo cáo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    SizedBox(height: 4),
                    Text('Quản lý các sự cố bạn đã gửi', style: TextStyle(fontSize: 13, color: AppColors.secondary)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showCreateIncidentForm,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tạo mới'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                _buildFilterChip(0, 'Tất cả'),
                const SizedBox(width: 10),
                _buildFilterChip(1, 'Đang xử lý'),
                const SizedBox(width: 10),
                _buildFilterChip(2, 'Đã hoàn thành'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              children: [
                IncidentCard(
                  statusLabel: 'Mới (Open)',
                  statusColor: const Color(0xFFFEE2E2),
                  textColor: Colors.red,
                  id: '#INC-20231025-01',
                  time: 'Hôm nay, 09:30',
                  title: 'Rò rỉ nước ống nước nhà vệ sinh',
                  desc: 'Nước liên tục nhỏ giọt từ ống nối dưới bồn rửa mặt, gây ướt sàn nhà vệ sinh. Cần thợ kiểm tra...',
                  actionWidget: TextButton.icon(
                    onPressed: () => _showCancelConfirmation('#INC-20231025-01'),
                    icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.redAccent),
                    label: const Text('Thu hồi', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                ),
                IncidentCard(
                  statusLabel: 'Đang xử lý',
                  statusColor: const Color(0xFFFEF3C7),
                  textColor: Colors.amber[800]!,
                  id: '#INC-20231024-03',
                  time: 'Hôm qua, 14:15',
                  title: 'Hỏng đèn hành lang tầng 8',
                  desc: 'Đèn chiếu sáng khu vực trước thang máy bị cháy, rất tối vào ban đêm.',
                  bottomLeftWidget: const Row(
                    children: [
                      Icon(Icons.directions_walk, size: 16, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text('Kỹ thuật viên đang di chuyển', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  actionWidget: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Chi tiết', style: TextStyle(color: AppColors.textDark, fontSize: 13)),
                  ),
                ),
                IncidentCard(
                  statusLabel: 'Đã xử lý',
                  statusColor: const Color(0xFFDCFCE7),
                  textColor: Colors.green,
                  id: '#INC-20231020-05',
                  time: '20/10/2023',
                  title: 'Tiếng ồn từ căn hộ phía trên',
                  desc: 'Đã liên hệ ban quản lý nhắc nhở căn hộ tầng trên về việc sửa chữa ngoài giờ quy định.',
                  actionWidget: TextButton(
                    onPressed: () {},
                    child: const Text('Đánh giá', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    bool isSelected = _activeFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeFilterIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0).withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.secondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:ecohome_app/core/constants/app_colors.dart';
import 'package:ecohome_app/shared/widgets/app_header.dart';
import 'package:ecohome_app/shared/widgets/member_card.dart';

import '../../../auth/data/auth_api.dart';
import '../../data/household_api.dart';
import '../../data/household_member.dart';

class HouseholdScreen extends StatefulWidget {
  const HouseholdScreen({super.key});

  @override
  State<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends State<HouseholdScreen> {
  final HouseholdApi _api = HouseholdApi();

  late Future<HouseholdInfo> _householdFuture;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _householdFuture = _api.getHousehold();
  }

  void _reload() {
    setState(() {
      _householdFuture = _api.getHousehold();
    });
  }

  Future<void> _refresh() async {
    final future = _api.getHousehold();

    setState(() {
      _householdFuture = future;
    });

    await future;
  }

  Future<void> _openAddMember(HouseholdInfo household) async {
    final input = await showDialog<_AddMemberInput>(
      context: context,
      builder: (context) => const _AddMemberDialog(),
    );

    if (input == null || !mounted) {
      return;
    }

    setState(() {
      _isAdding = true;
    });

    try {
      await _api.addMember(
        contractId: household.contractId,
        identityNumber: input.identityNumber,
        residentType: input.residentType,
      );

      final refreshed = _api.getHousehold();

      setState(() {
        _householdFuture = refreshed;
      });

      await refreshed;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm thành viên vào hộ gia đình.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }

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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hộ gia đình',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Quản lý thông tin các thành viên trong căn hộ của bạn.',
                    style: TextStyle(fontSize: 14, color: AppColors.secondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<HouseholdInfo>(
                future: _householdFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    final error = snapshot.error;
                    final message = error is ApiException
                        ? error.message
                        : 'Không thể tải thông tin hộ gia đình.';

                    return _ErrorView(message: message, onRetry: _reload);
                  }

                  final household = snapshot.data!;

                  return _HouseholdContent(
                    household: household,
                    isAdding: _isAdding,
                    onRefresh: _refresh,
                    onAddPressed: () => _openAddMember(household),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HouseholdContent extends StatelessWidget {
  const _HouseholdContent({
    required this.household,
    required this.isAdding,
    required this.onRefresh,
    required this.onAddPressed,
  });

  final HouseholdInfo household;
  final bool isAdding;
  final Future<void> Function() onRefresh;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    HouseholdMember? owner;

    for (final member in household.members) {
      if (member.isOwner) {
        owner = member;
        break;
      }
    }

    final otherMembers = owner == null
        ? household.members
        : household.members
              .where((member) => member.residentId != owner!.residentId)
              .toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CHỦ HỘ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            if (owner != null)
              MemberCard(
                isOwner: true,
                name: owner.name,
                phone: owner.phone,
                email: owner.email,
                role: owner.roleLabel,
              )
            else
              const _EmptyOwner(),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'THÀNH VIÊN KHÁC (${otherMembers.length})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                    letterSpacing: 1.2,
                  ),
                ),
                TextButton.icon(
                  onPressed: isAdding ? null : onAddPressed,
                  icon: isAdding
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add, size: 18),
                  label: Text(
                    isAdding ? 'Đang thêm...' : 'Thêm mới',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: otherMembers.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'Chưa có thành viên khác.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.secondary),
                      ),
                    )
                  : Column(
                      children: otherMembers
                          .map(
                            (member) => MemberCard(
                              name: member.name,
                              role: member.roleLabel,
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _AddMemberInput {
  const _AddMemberInput({
    required this.identityNumber,
    required this.residentType,
  });

  final String identityNumber;
  final int residentType;
}

class _AddMemberDialog extends StatefulWidget {
  const _AddMemberDialog();

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _identityController = TextEditingController();

  int _residentType = 1;

  @override
  void dispose() {
    _identityController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.pop(
      context,
      _AddMemberInput(
        identityNumber: _identityController.text.trim(),
        residentType: _residentType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm thành viên'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _identityController,
                keyboardType: TextInputType.number,
                maxLength: 12,
                decoration: const InputDecoration(
                  labelText: 'Số căn cước',
                  hintText: 'Nhập 12 chữ số',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final identity = value?.trim() ?? '';

                  if (!RegExp(r'^\d{12}$').hasMatch(identity)) {
                    return 'Số căn cước phải gồm đúng 12 chữ số.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _residentType,
                decoration: const InputDecoration(
                  labelText: 'Vai trò',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Vợ / Chồng')),
                  DropdownMenuItem(value: 2, child: Text('Con cái')),
                  DropdownMenuItem(value: 3, child: Text('Người thuê')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _residentType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              const Text(
                'Người được thêm phải có sẵn tài khoản và hồ sơ cư dân.',
                style: TextStyle(fontSize: 12, color: AppColors.secondary),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Thêm')),
      ],
    );
  }
}

class _EmptyOwner extends StatelessWidget {
  const _EmptyOwner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'Chưa xác định chủ hộ.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.secondary),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
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
}

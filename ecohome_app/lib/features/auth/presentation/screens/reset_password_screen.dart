import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/auth_api.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identityController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _api = AuthApi();

  int _step = 0;
  int _secondsLeft = 0;
  bool _loading = false;
  bool _hidePassword = true;
  bool _hideConfirm = true;
  bool _accountExists = false;
  String _email = '';
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _identityController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool error = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await action();
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) {
        _showMessage('Đã xảy ra lỗi. Vui lòng kiểm tra kết nối và thử lại.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitIdentity() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await _run(() async {
      final identity = _identityController.text.trim();
      final email = await _api.checkAccount(identity);
      if (!mounted) return;
      setState(() {
        _email = email;
        _accountExists = true;
      });
    });
  }

  Future<void> _startResetPassword() async {
    if (!_accountExists || _email.isEmpty) return;
    await _run(() async {
      await _api.requestOtp(_email);
      if (!mounted) return;
      setState(() => _step = 1);
      _startTimer();
    });
  }

  Future<void> _verifyOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await _run(() async {
      await _api.verifyOtp(email: _email, otp: _otpController.text.trim());
      if (mounted) setState(() => _step = 2);
    });
  }

  Future<void> _setPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await _run(() async {
      await _api.setPassword(
        identityNumber: _identityController.text.trim(),
        email: _email,
        password: _passwordController.text,
      );
      if (!mounted) return;
      _showMessage('Đặt mật khẩu thành công.', error: false);
      Navigator.pop(context);
    });
  }

  Future<void> _resendOtp() async {
    if (_secondsLeft > 0) return;
    await _run(() async {
      await _api.requestOtp(_email);
      if (mounted) {
        _showMessage('Đã gửi lại mã OTP.', error: false);
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 5 * 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _secondsLeft <= 1) {
        timer.cancel();
        if (mounted) setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  String get _timeLabel {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ĐẶT LẠI MẬT KHẨU'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đăng nhập'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 560),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8EDF3)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StepHeader(currentStep: _step),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: KeyedSubtree(
                        key: ValueKey(_step),
                        child: _stepContent(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepContent() {
    if (_step == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _identityController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
            decoration: _decoration('Số căn cước phải là 12 chữ số'),
            validator: _identityValidator,
            onChanged: (_) {
              if (_accountExists) {
                setState(() {
                  _accountExists = false;
                  _email = '';
                });
              }
            },
            onFieldSubmitted: (_) => _submitIdentity(),
          ),
          const SizedBox(height: 16),
          _button(
            _accountExists ? 'Kiểm tra lại' : 'Kiểm tra tài khoản',
            _submitIdentity,
          ),
          if (_accountExists) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Tài khoản đã tồn tại',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bạn có thể tiếp tục để nhận mã OTP qua email và đặt lại mật khẩu.',
                  ),
                  const SizedBox(height: 14),
                  _button('Đặt lại mật khẩu', _startResetPassword),
                ],
              ),
            ),
          ],
        ],
      );
    }
    if (_step == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Mã OTP sẽ được gửi qua Email: $_email',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          const Text('Xin hãy nhập mã để đặt lại mật khẩu.'),
          const SizedBox(height: 20),
          TextFormField(
            controller: _otpController,
            autofocus: true,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            style: const TextStyle(fontSize: 22, letterSpacing: 12),
            decoration: _decoration('000000'),
            validator: (value) =>
                value?.length == 6 ? null : 'Vui lòng nhập đủ 6 số OTP',
            onFieldSubmitted: (_) => _verifyOtp(),
          ),
          const SizedBox(height: 16),
          _button('Xác thực', _verifyOtp),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('OTP còn hiệu lực: $_timeLabel'),
              const SizedBox(width: 12),
              TextButton(
                onPressed: _secondsLeft == 0 ? _resendOtp : null,
                child: const Text('Lấy lại mã OTP'),
              ),
            ],
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _passwordController,
          obscureText: _hidePassword,
          decoration: _decoration('Nhập mật khẩu mới').copyWith(
            suffixIcon: IconButton(
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
              icon: Icon(
                _hidePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
          validator: _passwordValidator,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmController,
          obscureText: _hideConfirm,
          decoration: _decoration('Nhập lại mật khẩu').copyWith(
            suffixIcon: IconButton(
              onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
              icon: Icon(
                _hideConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
          validator: (value) => value == _passwordController.text
              ? null
              : 'Mật khẩu nhập lại không khớp',
          onFieldSubmitted: (_) => _setPassword(),
        ),
        const SizedBox(height: 18),
        _button('Đặt mật khẩu', _setPassword),
      ],
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
  );

  Widget _button(String label, VoidCallback onPressed) => SizedBox(
    height: 48,
    child: ElevatedButton(
      onPressed: _loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          : Text(label),
    ),
  );

  String? _identityValidator(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập số căn cước';
    if (!RegExp(r'^\d{12}$').hasMatch(value)) {
      return 'Số căn cước phải gồm đúng 12 chữ số';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu mới';
    if (value.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
    return null;
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const labels = ['Điền số căn cước', 'Xác thực', 'Đặt lại mật khẩu'];
    return Row(
      children: List.generate(labels.length, (index) {
        final done = index < currentStep;
        final active = index == currentStep;
        return Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: done || active
                    ? AppColors.primary
                    : const Color(0xFFE9ECEF),
                child: done
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          color: active ? Colors.white : Colors.grey,
                        ),
                      ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  labels[index],
                  style: TextStyle(
                    fontSize: 12,
                    color: active ? AppColors.textDark : Colors.grey,
                  ),
                ),
              ),
              if (index < labels.length - 1) const SizedBox(width: 5),
            ],
          ),
        );
      }),
    );
  }
}

class VietQrConfig {
  VietQrConfig._();

  // SỬA 3 GIÁ TRỊ NÀY THÀNH TÀI KHOẢN NHẬN TIỀN THẬT.
  static const String bankId = 'MB';
  static const String accountNumber = '0919098606';
  static const String accountName = 'NGUYEN HA KHOA';

  static const String template = 'compact2';

  static bool get isConfigured {
    return accountNumber != 'NHAP_SO_TAI_KHOAN' &&
        accountName != 'NHAP_TEN_CHU_TAI_KHOAN' &&
        accountNumber.trim().isNotEmpty &&
        accountName.trim().isNotEmpty;
  }

  static String buildQrUrl({
    required num amount,
    required String transferContent,
  }) {
    return Uri.https(
      'img.vietqr.io',
      '/image/$bankId-$accountNumber-$template.png',
      {
        'amount': amount.round().toString(),
        'addInfo': transferContent,
        'accountName': accountName,
      },
    ).toString();
  }
}

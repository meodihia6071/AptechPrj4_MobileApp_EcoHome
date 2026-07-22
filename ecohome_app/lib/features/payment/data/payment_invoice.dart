enum PaymentInvoiceType { rent, service }

enum PaymentInvoiceStatus {
  pending,
  awaitingBankTransfer,
  awaitingCashConfirmation,
  paid,
  overdue,
  cancelled,
}

class PaymentInvoice {
  const PaymentInvoice({
    required this.paymentId,
    required this.title,
    required this.amount,
    required this.deadline,
    required this.type,
    required this.status,
    required this.isLatePayment,
    this.description,
    this.roomNumber,
    this.paymentDate,
  });

  factory PaymentInvoice.fromJson(Map<String, dynamic> json) {
    return PaymentInvoice(
      paymentId: json['paymentId']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Hóa đơn',
      description: json['description']?.toString(),
      roomNumber: json['roomNumber']?.toString(),
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
      deadline:
          DateTime.tryParse(json['deadline']?.toString() ?? '') ??
          DateTime.now(),
      type: _parseType(json['type']),
      status: _parseStatus(json['status']),
      paymentDate: DateTime.tryParse(json['paymentDate']?.toString() ?? ''),
      isLatePayment: json['isLatePayment'] == true,
    );
  }

  final String paymentId;
  final String title;
  final String? description;
  final String? roomNumber;
  final double amount;
  final DateTime deadline;
  final PaymentInvoiceType type;
  final PaymentInvoiceStatus status;
  final DateTime? paymentDate;
  final bool isLatePayment;

  bool get canCheckout =>
      status == PaymentInvoiceStatus.pending ||
      status == PaymentInvoiceStatus.overdue;

  bool get isOutstanding =>
      status != PaymentInvoiceStatus.paid &&
      status != PaymentInvoiceStatus.cancelled;

  static PaymentInvoiceType _parseType(dynamic value) {
    final normalized = value.toString().toLowerCase();
    return normalized == 'service' || normalized == '1'
        ? PaymentInvoiceType.service
        : PaymentInvoiceType.rent;
  }

  static PaymentInvoiceStatus _parseStatus(dynamic value) {
    return switch (value.toString().toLowerCase()) {
      'awaitingbanktransfer' ||
      '1' => PaymentInvoiceStatus.awaitingBankTransfer,
      'awaitingcashconfirmation' ||
      '2' => PaymentInvoiceStatus.awaitingCashConfirmation,
      'paid' || '3' => PaymentInvoiceStatus.paid,
      'overdue' || '4' => PaymentInvoiceStatus.overdue,
      'cancelled' || '5' => PaymentInvoiceStatus.cancelled,
      _ => PaymentInvoiceStatus.pending,
    };
  }
}

enum PaymentMethod { cash, bankTransfer }

class BankTransferInfo {
  const BankTransferInfo({
    required this.transferContent,
    this.bankName,
    this.accountNumber,
    this.accountName,
    this.qrCodeUrl,
  });

  factory BankTransferInfo.fromJson(Map<String, dynamic> json) {
    return BankTransferInfo(
      bankName: json['bankName']?.toString(),
      accountNumber: json['accountNumber']?.toString(),
      accountName: json['accountName']?.toString(),
      transferContent: json['transferContent']?.toString() ?? '',
      qrCodeUrl: json['qrCodeUrl']?.toString(),
    );
  }

  final String? bankName;
  final String? accountNumber;
  final String? accountName;
  final String transferContent;
  final String? qrCodeUrl;
}

class CheckoutResult {
  const CheckoutResult({
    required this.transactionId,
    required this.referenceCode,
    required this.totalAmount,
    required this.status,
    this.bankTransfer,
  });

  factory CheckoutResult.fromJson(Map<String, dynamic> json) {
    final bank = json['bankTransfer'];
    return CheckoutResult(
      transactionId: json['transactionId']?.toString() ?? '',
      referenceCode: json['referenceCode']?.toString() ?? '',
      totalAmount: double.tryParse(json['totalAmount']?.toString() ?? '') ?? 0,
      status: PaymentInvoice._parseStatus(json['status']),
      bankTransfer: bank is Map
          ? BankTransferInfo.fromJson(Map<String, dynamic>.from(bank))
          : null,
    );
  }

  final String transactionId;
  final String referenceCode;
  final double totalAmount;
  final PaymentInvoiceStatus status;
  final BankTransferInfo? bankTransfer;
}

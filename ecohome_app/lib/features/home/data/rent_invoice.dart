class RentInvoice {
  const RentInvoice({
    required this.roomNumber,
    required this.amount,
    required this.deadline,
    required this.daysRemaining,
  });

  final String roomNumber;
  final double amount;
  final DateTime deadline;
  final int daysRemaining;
}

enum ContractType { cash, installment, rental }

class ApartmentInfo {
  const ApartmentInfo({
    required this.roomNumber,
    required this.floor,
    required this.area,
    required this.contractType,
    required this.primaryAmount,
    required this.primaryLabel,
    this.secondaryAmount,
    this.secondaryLabel,
    this.nextDueDate,
    this.pictureUrl,
  });

  final String roomNumber;
  final int floor;
  final double area;
  final ContractType contractType;
  final double primaryAmount;
  final String primaryLabel;
  final double? secondaryAmount;
  final String? secondaryLabel;
  final DateTime? nextDueDate;
  final String? pictureUrl;
}

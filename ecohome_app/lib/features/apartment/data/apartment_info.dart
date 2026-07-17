enum ContractType { cash, rental }

class ApartmentInfo {
  const ApartmentInfo({
    required this.apartmentId,
    required this.contractId,
    required this.roomNumber,
    required this.floor,
    required this.area,
    required this.contractType,
    required this.primaryAmount,
    required this.primaryLabel,
    required this.residentType,
    this.secondaryAmount,
    this.secondaryLabel,
    this.nextDueDate,
    this.paymentCountdownDays,
    this.pictureUrl,
  });

  final String apartmentId;
  final String contractId;
  final String roomNumber;
  final int floor;
  final double area;
  final ContractType contractType;
  final double primaryAmount;
  final String primaryLabel;
  final int residentType;
  final double? secondaryAmount;
  final String? secondaryLabel;
  final DateTime? nextDueDate;
  final int? paymentCountdownDays;
  final String? pictureUrl;
}

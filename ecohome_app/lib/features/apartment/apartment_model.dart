class ApartmentModel {
  final String roomName;
  final int floor;
  final int area;
  final int rentAmount;
  final String rentDueDate;
  final int purchasePaid;
  final int installmentPaid;
  final int installmentDue;

  ApartmentModel({
    required this.roomName,
    required this.floor,
    required this.area,
    required this.rentAmount,
    required this.rentDueDate,
    required this.purchasePaid,
    required this.installmentPaid,
    required this.installmentDue,
  });

  factory ApartmentModel.fromMap(Map<String, dynamic> data) {
    return ApartmentModel(
      roomName: data['roomName'] ?? '',
      floor: data['floor'] ?? 0,
      area: data['area'] ?? 0,
      rentAmount: data['rentAmount'] ?? 0,
      rentDueDate: data['rentDueDate'] ?? '',
      purchasePaid: data['purchasePaid'] ?? 0,
      installmentPaid: data['installmentPaid'] ?? 0,
      installmentDue: data['installmentDue'] ?? 0,
    );
  }
}
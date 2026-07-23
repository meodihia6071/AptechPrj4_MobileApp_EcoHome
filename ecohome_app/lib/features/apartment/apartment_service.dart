import 'package:cloud_firestore/cloud_firestore.dart';
import 'apartment_model.dart';

class ApartmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<ApartmentModel> getApartment() {
    return _firestore
        .collection('apartments')
        .doc('A1205')
        .snapshots()
        .map((snapshot) {
      return ApartmentModel.fromMap(snapshot.data()!);
    });
  }
}
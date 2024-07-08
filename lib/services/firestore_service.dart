import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<int> countReservationsForMedico(String medicoId, String day) async {
    final snapshot = await _db
        .collection('reservas')
        .doc(medicoId)
        .collection('reservas_diarias')
        .doc(day)
        .collection('reservas_por_dia')
        .get();
    return snapshot.size;
  }

  Future<void> addItemForDay(
      String medicoId, String day, Map<String, dynamic> data) async {
    await _db
        .collection('reservas')
        .doc(medicoId)
        .collection('reservas_diarias')
        .doc(day)
        .collection('reservas_por_dia')
        .add(data);
  }

  Future<void> addItem(String collection, Map<String, dynamic> data) async {
    await _db.collection(collection).add(data);
  }

  Future<void> updateItem(
      String collection, String id, Map<String, dynamic> data) async {
    await _db.collection(collection).doc(id).update(data);
  }

  Future<void> deleteItem(String collection, String id) async {
    await _db.collection(collection).doc(id).delete();
  }

  Stream<QuerySnapshot> getItems(String collection) {
    return _db.collection(collection).snapshots();
  }
}

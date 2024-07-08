import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DataProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getItems(String collection) {
    return _firestore.collection(collection).snapshots();
  }

  Future<void> addReservation(Map<String, dynamic> reservation) async {
    await _firestore.collection('reservas').add(reservation);
  }

  Future<int> countReservationsForMedico(String medicoId, String date) async {
    final querySnapshot = await _firestore
        .collection('reservas')
        .where('medicoId', isEqualTo: medicoId)
        .where('date', isEqualTo: date)
        .get();
    return querySnapshot.docs.length;
  }

  Future<void> deleteItem(String collection, String docId) async {
    await _firestore.collection(collection).doc(docId).delete();
  }

  Future<void> updateReservation(
      String collection, String reservaId, Map<String, dynamic> newData) async {
    await _firestore.collection(collection).doc(reservaId).update(newData);
  }
}

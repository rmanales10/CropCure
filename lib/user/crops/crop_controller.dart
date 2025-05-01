import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class CropController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? get currentUser => _auth.currentUser;

  RxList<Map<String, dynamic>> plantDetails = <Map<String, dynamic>>[].obs;
  Future<void> fetchPlantDetails() async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('plant')
        .where('user_id', isEqualTo: currentUser!.uid)
        .get();
    plantDetails.value = querySnapshot.docs
        .map((doc) => {
              'id': doc['id'],
              'user_id': doc['user_id'],
              'name': doc['name'],
              'diseases': doc['diseases'],
              'image': doc['image']!,
            })
        .toList();
  }

  RxMap<String, dynamic> plantDet = <String, dynamic>{}.obs;
  Future<void> fetchPlantDet({required String id}) async {
    try {
      DocumentSnapshot documentSnapshot =
          await _firestore.collection('plant').doc(id).get();
      if (documentSnapshot.exists) {
        plantDet.value = documentSnapshot.data() as Map<String, dynamic>;
      }
    } catch (e) {
      log('Errroe $e');
    }
  }

  Future<void> deletePlant(String id) async {
    await _firestore.collection('plant').doc(id).delete();
  }
}

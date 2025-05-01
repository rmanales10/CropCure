import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  User? get currentUser => _auth.currentUser;

  var userInfo = {}.obs;
  Future<void> fetchUserInfo() async {
    try {
      DocumentSnapshot documentSnapshot =
          await _firestore.collection('users').doc(currentUser!.uid).get();
      if (documentSnapshot.exists) {
        userInfo.value = documentSnapshot.data() as Map;
      }
    } catch (e) {
      log('Error $e');
    }
  }

  Future<void> editName(String name) async {
    await _firestore.collection('users').doc(currentUser!.uid).set({
      'fullname': name,
    }, SetOptions(merge: true));
  }

  Future<void> storeImage(String base64image) async {
    await _firestore.collection('users').doc(currentUser!.uid).set({
      'base64image': base64image,
    }, SetOptions(merge: true));
  }
}

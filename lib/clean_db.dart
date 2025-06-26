import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> cleanLikesWithoutVestiti() async {
  final _db = FirebaseFirestore.instance;
  final likesSnapshot = await _db.collection('likes').get();
  for (var likeDoc in likesSnapshot.docs) {
    final clothingId = likeDoc['clothingId'];
    final clothingDoc = await _db.collection('vestiti').doc(clothingId).get();
    if (!clothingDoc.exists) {
      print('Cancello like orfano: ${likeDoc.id}');
      await likeDoc.reference.delete();
    }
  }
}

Future<void> cleanVestitiWithoutUser() async {
  final _db = FirebaseFirestore.instance;
  final vestitiSnapshot = await _db.collection('vestiti').get();
  for (var vestitoDoc in vestitiSnapshot.docs) {
    final userId = vestitoDoc['userId'];
    final userDoc = await _db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      print('Cancello vestito orfano: ${vestitoDoc.id}');
      await vestitoDoc.reference.delete();
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await cleanLikesWithoutVestiti();
  await cleanVestitiWithoutUser();
  print('Pulizia completata.');
}

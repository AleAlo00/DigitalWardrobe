import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClothingService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> addClothing({
    required String marca,
    required String categoria,
    required String taglia,
    required String colore,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('vestiti').add({
      'userId': user.uid,
      'marca': marca,
      'categoria': categoria,
      'taglia': taglia,
      'colore': colore,
      'creato_il': Timestamp.now(),
      'preferito': false,
    });
  }

  Future<List<Map<String, dynamic>>> getClothes() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _db
        .collection('vestiti')
        .where('userId', isEqualTo: user.uid)
        .orderBy('creato_il', descending: true)
        .get();

    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }
}

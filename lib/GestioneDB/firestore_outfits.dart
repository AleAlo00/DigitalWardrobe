import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OutfitService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> addOutfit({
    required String nome,
    required Map<String, String> categoriaVestitoIdMap,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final data = <String, dynamic>{'userId': user.uid, 'nome': nome};

    // Inserisco i vestiti per categoria (solo se non null)
    categoriaVestitoIdMap.forEach((key, value) {
      if (value.isNotEmpty) data[key] = value;
    });

    await _db.collection('outfits').add(data);
  }

  Future<List<Map<String, dynamic>>> getOutfits() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _db
        .collection('outfits')
        .where('userId', isEqualTo: user.uid)
        .get();

    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  Future<Map<String, dynamic>?> getOutfitById(String id) async {
    final doc = await _db.collection('outfits').doc(id).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  Future<void> updateOutfit(String id, Map<String, dynamic> data) async {
    await _db.collection('outfits').doc(id).update(data);
  }

  Future<void> deleteOutfit(String id) async {
    await _db.collection('outfits').doc(id).delete();
  }
}

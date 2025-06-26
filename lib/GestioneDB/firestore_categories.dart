import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryService {
  final _db = FirebaseFirestore.instance;

  Future<void> addCategory(String title, int order) async {
    await _db.collection('categorie').add({'title': title, 'order': order});
  }

  Future<List<String>> getCategories() async {
    final snapshot = await _db.collection('categorie').orderBy('order').get();
    return snapshot.docs.map((doc) => doc['title'] as String).toList();
  }

  Future<void> addDefaultCategoriesIfEmpty() async {
    final snapshot = await _db.collection('categorie').limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final defaultCategories = [
      'Calzini',
      'Intimo',
      'Scarpe',
      'Pantaloni',
      'Magliette',
      'Felpe',
      'Giacche',
      'Cappelli e Sciarpe',
    ];

    await Future.wait(
      defaultCategories.asMap().entries.map(
        (entry) => addCategory(entry.value, entry.key),
      ),
    );
  }
}

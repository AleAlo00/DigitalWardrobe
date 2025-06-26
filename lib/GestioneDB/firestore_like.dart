import 'package:cloud_firestore/cloud_firestore.dart';

class LikeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Aggiunge o rimuove un like su un vestito da parte di un utente
  Future<void> setLikeOnClothing({
    required String currentUserId,
    required String clothingId,
    required bool liked,
  }) async {
    final docRef = _db.collection('likes').doc('${currentUserId}_$clothingId');

    if (liked) {
      await docRef.set({
        'userId': currentUserId,
        'vestitoId': clothingId, // campo aggiornato a 'vestitoId'
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.delete();
    }
  }

  /// Recupera tutti i vestiti che l'utente ha contrassegnato con "like"
  Future<List<Map<String, dynamic>>> getClothesILiked(String userId) async {
    final likesSnapshot = await FirebaseFirestore.instance
        .collection('likes')
        .where('userId', isEqualTo: userId)
        .get();

    List<Map<String, dynamic>> likedClothes = [];

    for (var doc in likesSnapshot.docs) {
      final data = doc.data();
      final vestitoId = data['vestitoId'];

      // Recupera il vestito
      final vestitoSnapshot = await FirebaseFirestore.instance
          .collection('vestiti')
          .doc(vestitoId)
          .get();

      if (vestitoSnapshot.exists) {
        final vestitoData = vestitoSnapshot.data()!;
        final ownerId = vestitoData['userId'];

        // Recupera il nome dell'owner
        final ownerSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(ownerId)
            .get();

        String ownerName = 'Sconosciuto';
        if (ownerSnapshot.exists) {
          ownerName = ownerSnapshot.data()?['userName'] ?? 'Sconosciuto';
        }

        likedClothes.add({
          ...vestitoData,
          'id': vestitoSnapshot.id,
          'ownerId': ownerId,
          'ownerName': ownerName, // <-- Aggiunto qui
        });
      }
    }

    return likedClothes;
  }

  Future<int> countLikesForVestito(String vestitoId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('likes')
        .where('vestitoId', isEqualTo: vestitoId)
        .get();

    return snapshot.docs.length;
  }

  Future<List<String>> getUsernamesWhoLikedVestito(String vestitoId) async {
    final likeSnapshot = await FirebaseFirestore.instance
        .collection('likes')
        .where('vestitoId', isEqualTo: vestitoId)
        .get();

    final userIds = likeSnapshot.docs
        .map((doc) => doc['userId'] as String)
        .toList();

    List<String> usernames = [];

    for (final uid in userIds) {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userSnapshot.exists) {
        final username = userSnapshot.data()?['userName'];
        if (username != null) {
          usernames.add(username);
        }
      }
    }

    return usernames;
  }

  /// Recupera i vestiti appartenenti agli amici che l'utente ha contrassegnato come preferiti (like)
  Future<List<Map<String, dynamic>>> getExternalFavoriteClothes(
    String userId,
  ) async {
    try {
      // Step 1: Recupera gli ID degli amici accettati
      final friendsSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('amici')
          .where('accettata', isEqualTo: true)
          .get();

      final friendIds = friendsSnapshot.docs.map((doc) => doc.id).toList();

      if (friendIds.isEmpty) {
        print('Nessun amico accettato trovato per l\'utente $userId');
        return [];
      }

      // Step 2: Recupera tutti i vestiti liked dagli amici
      final likesSnapshot = await _db
          .collection('likes')
          .where('userId', whereIn: friendIds)
          .get();

      final likedClothingIdsByFriends = <String>{};
      for (var doc in likesSnapshot.docs) {
        if (doc.data().containsKey('vestitoId')) {
          likedClothingIdsByFriends.add(doc['vestitoId'] as String);
        } else {
          print('Documento likes senza campo vestitoId: ${doc.id}');
        }
      }

      if (likedClothingIdsByFriends.isEmpty) {
        print('Nessun vestito liked dagli amici di $userId');
        return [];
      }

      // Step 3: Recupera i dati dei vestiti liked dagli amici
      List<Map<String, dynamic>> likedFriendsClothes = [];
      const int batchSize = 10;

      final likedClothingIdsList = likedClothingIdsByFriends.toList();

      for (var i = 0; i < likedClothingIdsList.length; i += batchSize) {
        final batchIds = likedClothingIdsList.skip(i).take(batchSize).toList();

        final clothesSnapshot = await _db
            .collection('vestiti')
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();

        likedFriendsClothes.addAll(
          clothesSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'userId': data['userId'],
              'marca': data['marca'],
              'categoria': data['categoria'],
              'taglia': data['taglia'],
              'colore': data['colore'],
            };
          }).toList(),
        );
      }

      return likedFriendsClothes;
    } catch (e) {
      print("Errore durante il recupero dei vestiti amici preferiti: $e");
      return [];
    }
  }
}

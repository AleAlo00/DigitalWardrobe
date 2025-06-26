import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Invia richiesta di amicizia usando il codice invito del destinatario
  Future<String?> sendFriendRequestByCode(
    String codiceInvitoDestinatario,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return 'Utente non autenticato';

    // Trova utente destinatario dal codice invito
    final snapshot = await _db
        .collection('users')
        .where('codiceInvito', isEqualTo: codiceInvitoDestinatario)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return 'Codice invito non valido';

    final receiverId = snapshot.docs.first.id;
    if (receiverId == user.uid) return 'Non puoi invitare te stesso';

    // Controlla se già inviata richiesta
    final check = await _db
        .collection('friend_requests')
        .where('from', isEqualTo: user.uid)
        .where('to', isEqualTo: receiverId)
        .get();

    if (check.docs.isNotEmpty) return 'Hai già inviato la richiesta';

    final fromName =
        (await _db.collection('users').doc(user.uid).get())
            .data()?['userName'] ??
        'Utente';

    // Aggiunge richiesta di amicizia
    await _db.collection('friend_requests').add({
      'from': user.uid,
      'fromName': fromName,
      'to': receiverId,
      'timestamp': Timestamp.now(),
    });

    return null;
  }

  Future<void> rejectFriendRequest(String senderUid) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userId = user.uid;

    final requests = await _db
        .collection('friend_requests')
        .where('from', isEqualTo: senderUid)
        .where('to', isEqualTo: userId)
        .get();

    for (final doc in requests.docs) {
      await doc.reference.delete();
    }
  }

  // Recupera le richieste di amicizia ricevute
  Future<List<Map<String, dynamic>>> getReceivedFriendRequests() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _db
        .collection('friend_requests')
        .where('to', isEqualTo: user.uid)
        .get();

    List<Map<String, dynamic>> results = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final senderUid = data['from'];
      String senderName = data['fromName'] ?? await _getUserName(senderUid);
      results.add({'uid': senderUid, 'userName': senderName});
    }

    return results;
  }

  // Corregge le richieste senza campo fromName
  Future<void> fixMissingFromNames() async {
    final snapshot = await _db.collection('friend_requests').get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (!data.containsKey('fromName')) {
        final fromUid = data['from'];
        final name = await _getUserName(fromUid);
        await doc.reference.update({'fromName': name});
      }
    }
  }

  // Accetta richiesta di amicizia
  Future<void> acceptFriendRequest(String senderUid) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final userId = user.uid;

    // Aggiunge relazione bidirezionale nella collection 'amicizie'
    await _db.collection('amicizie').add({'user1': userId, 'user2': senderUid});

    // Aggiorna campo 'friends' in entrambi i documenti utenti
    await _addFriendToUser(userId, senderUid);
    await _addFriendToUser(senderUid, userId);

    // Elimina richiesta
    await _deleteFriendRequest(senderUid, userId);
  }

  // Rifiuta richiesta di amicizia
  Future<void> refuseFriendRequest(String senderUid) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _deleteFriendRequest(senderUid, user.uid);
  }

  // Recupera lista amici dell'utente corrente dalla collection 'amicizie'
  Future<List<Map<String, dynamic>>> getFriends() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final userId = user.uid;

    final snapshot1 = await _db
        .collection('amicizie')
        .where('user1', isEqualTo: userId)
        .get();

    final snapshot2 = await _db
        .collection('amicizie')
        .where('user2', isEqualTo: userId)
        .get();

    final friendIds = <String>{};

    for (final doc in snapshot1.docs) {
      friendIds.add(doc['user2']);
    }
    for (final doc in snapshot2.docs) {
      friendIds.add(doc['user1']);
    }

    List<Map<String, dynamic>> friends = [];

    for (final id in friendIds) {
      final userName = await _getUserName(id);
      friends.add({'uid': id, 'userName': userName});
    }

    return friends;
  }

  // Recupera amici accettati salvati nel campo 'friends' del documento utente
  Future<List<Map<String, dynamic>>> getAcceptedFriends() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final data = userDoc.data();
    final List<dynamic> friendsUids = data?['friends'] ?? [];

    List<Map<String, dynamic>> friends = [];

    for (final uid in friendsUids) {
      final friendDoc = await _db.collection('users').doc(uid).get();
      if (friendDoc.exists) {
        final friendData = friendDoc.data();
        friends.add({
          'uid': uid,
          'userName': friendData?['userName'] ?? 'Utente',
          'email': friendData?['email'] ?? '',
        });
      }
    }

    return friends;
  }

  // Metodo privato per aggiungere un amico al campo 'friends' del documento utente
  Future<void> _addFriendToUser(String userId, String friendId) async {
    final ref = _db.collection('users').doc(userId);
    await ref.update({
      'friends': FieldValue.arrayUnion([friendId]),
    });
  }

  // Metodo privato per recuperare userName dato uid
  Future<String> _getUserName(String uid) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    return userDoc.data()?['userName'] ?? 'Utente';
  }

  // Metodo privato per cancellare richieste di amicizia da senderUid a userId
  Future<void> _deleteFriendRequest(String senderUid, String userId) async {
    final query = await _db
        .collection('friend_requests')
        .where('from', isEqualTo: senderUid)
        .where('to', isEqualTo: userId)
        .get();

    for (final doc in query.docs) {
      await doc.reference.delete();
    }
  }
}

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

class UserService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> saveUserData({
    required String name,
    required bool isDarkMode,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _db.collection('users').doc(user.uid);
    final doc = await docRef.get();

    String codiceInvito = '';
    final data = doc.data();
    if (data == null || !data.containsKey('codiceInvito')) {
      codiceInvito = _generateInviteCode();
    } else {
      codiceInvito = data['codiceInvito'] ?? '';
    }

    await docRef.set({
      'userName': name,
      'email': user.email,
      'isDarkMode': isDarkMode,
      'codiceInvito': codiceInvito,
    }, SetOptions(merge: true));
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<String> getInviteCode() async {
    final user = _auth.currentUser;
    if (user == null) return '';

    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.data()?['codiceInvito'] ?? '';
  }

  Future<void> shareInviteCode() async {
    final code = await getInviteCode();
    if (code.isNotEmpty) {
      await Share.share(
        'Unisciti a me su Digital Wardrobe! Usa il codice invito: $code',
      );
    }
  }

  Future<void> ensureInviteCodeExists() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _db.collection('users').doc(user.uid);
    final doc = await docRef.get();

    final data = doc.data();
    if (data == null ||
        !data.containsKey('codiceInvito') ||
        (data['codiceInvito'] as String).isEmpty) {
      final code = _generateInviteCode();
      await docRef.set({'codiceInvito': code}, SetOptions(merge: true));
    }
  }

  Future<Map<String, dynamic>> getUserData() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.exists ? doc.data() ?? {} : {};
  }

  Future<String> getUserName() async {
    final data = await getUserData();
    return data['userName'] ?? 'User';
  }

  Future<bool> getSavedTheme() async {
    final data = await getUserData();
    return data['isDarkMode'] ?? false;
  }

  Future<void> updateUserName(String newName) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utente non autenticato');

    await _db.collection('users').doc(user.uid).set({
      'userName': newName,
    }, SetOptions(merge: true));
  }

  Future<void> updateThemePreference(bool isDarkMode) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).set({
      'isDarkMode': isDarkMode,
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>> getUserInfoSummary({String? uid}) async {
    final currentUser = _auth.currentUser;
    final String userId = uid ?? currentUser!.uid;

    final userDoc = await _db.collection('users').doc(userId).get();
    final userData = userDoc.data() ?? {};

    // Vestiti
    final clothesSnap = await _db
        .collection('vestiti')
        .where('userId', isEqualTo: userId)
        .get();
    final clothes = clothesSnap.docs;
    final totalClothes = clothes.length;
    final favoriteClothes = clothes
        .where((doc) => doc['preferito'] == true)
        .length;

    // Amici: mantieni la lista originale senza forzare 0 se nulla
    final List<dynamic>? friendsList = userData['friends'] as List<dynamic>?;

    final totalFriends = friendsList?.length ?? 0;

    return {
      'userName': userData['userName'] ?? 'Utente',
      'totalClothes': totalClothes,
      'favoriteClothes': favoriteClothes,
      'totalFriends': totalFriends,
    };
  }

  Future<int> getCurrentUserOutfitCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Utente non loggato, ritorna 0 o gestisci come preferisci
      return 0;
    }

    try {
      final querySnapshot = await _db
          .collection('outfits')
          .where('userId', isEqualTo: user.uid)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('Errore nel recuperare il numero di outfit: $e');
      return 0;
    }
  }
}

class UserServiceSettings {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> updateMainColor(String hexColor) async {
    final user = _auth.currentUser;
    if (user == null) return;

    print('updateMainColor: salvando colore $hexColor per utente ${user.uid}');
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('preferences')
        .set({'mainColorHex': hexColor}, SetOptions(merge: true));
    print('updateMainColor: salvataggio completato');
  }

  Future<String> getMainColorHex() async {
    final user = _auth.currentUser;
    if (user == null) return "#2196F3";

    final doc = await _db
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('preferences')
        .get();
    final data = doc.data();
    if (data == null || data['mainColorHex'] == null) {
      return "#2196F3"; // colore di default
    }
    return data['mainColorHex'] as String;
  }

  // Se vuoi mantenere questa funzione, correggi così:
  Future<void> saveMainColorHex(String hexColor) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Utente non loggato");

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('preferences')
        .set({'mainColorHex': hexColor}, SetOptions(merge: true));
  }

  // Recupera il valore booleano per tema automatico (default false)
  Future<bool> getAutoThemeEnabled() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _db
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('preferences')
        .get();
    final data = doc.data();
    if (data == null || data['autoThemeEnabled'] == null) {
      return false;
    }
    return data['autoThemeEnabled'] as bool;
  }

  // Aggiorna il valore booleano per tema automatico
  Future<void> updateAutoThemeEnabled(bool enabled) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('preferences')
        .set({'autoThemeEnabled': enabled}, SetOptions(merge: true));
  }
}

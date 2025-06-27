import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class UserService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> saveUserData({
    required String name,
    required bool isDarkMode,
    String? profileImageUrl,
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

    final userData = {
      'userName': name,
      'email': user.email,
      'isDarkMode': isDarkMode,
      'codiceInvito': codiceInvito,
    };

    if (profileImageUrl != null) {
      userData['profileImageUrl'] = profileImageUrl;
    }

    await docRef.set(userData, SetOptions(merge: true));
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

    final clothesSnap = await _db
        .collection('vestiti')
        .where('userId', isEqualTo: userId)
        .get();
    final clothes = clothesSnap.docs;
    final totalClothes = clothes.length;
    final favoriteClothes = clothes
        .where((doc) => doc['preferito'] == true)
        .length;

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
    if (user == null) return 0;

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

  Future<void> mostraDialogModificaEmail(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final TextEditingController emailController = TextEditingController();

      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      final textColor = isDarkMode ? Colors.white : Colors.black;

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Modifica email'),
          content: TextField(
            controller: emailController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Nuova email',
              hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: textColor.withOpacity(0.5)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: textColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annulla', style: TextStyle(color: textColor)),
            ),
            TextButton(
              onPressed: () async {
                final newEmail = emailController.text.trim();
                try {
                  await user.updateEmail(newEmail);
                  await user.sendEmailVerification();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Email aggiornata. Verifica la nuova email.',
                      ),
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Errore: ${e.toString()}')),
                  );
                }
              },
              child: Text('Conferma', style: TextStyle(color: textColor)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> inviaEmailReimpostaPassword(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && user.email != null) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email di reimpostazione inviata.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Errore: ${e.toString()}')));
      }
    }
  }

  Future<void> eliminaAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: const Text(
          'Sei sicuro di voler eliminare definitivamente il tuo account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (conferma != true) return;

    final password = await chiediPassword(context);
    if (password == null || !(await reauthenticateUser(context, password))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password errata o autenticazione fallita.'),
        ),
      );
      return;
    }

    try {
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        final friendsIds = List<String>.from(userDoc.data()?['friends'] ?? []);

        final batch = FirebaseFirestore.instance.batch();

        for (final friendId in friendsIds) {
          final friendDocRef = FirebaseFirestore.instance
              .collection('users')
              .doc(friendId);
          batch.update(friendDocRef, {
            'friends': FieldValue.arrayRemove([user.uid]),
          });
        }

        batch.delete(userDocRef);
        await batch.commit();
      }

      await user.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account eliminato con successo.')),
      );

      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante l\'eliminazione: ${e.toString()}'),
        ),
      );
    }
  }

  Future<bool> reauthenticateUser(BuildContext context, String password) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) return false;

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );

    try {
      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> chiediPassword(BuildContext context) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Inserisci la tua password',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Conferma'),
          ),
        ],
      ),
    );
  }
}

class GestioneAmiciPage extends StatefulWidget {
  @override
  _GestioneAmiciPageState createState() => _GestioneAmiciPageState();
}

class _GestioneAmiciPageState extends State<GestioneAmiciPage> {
  final user = FirebaseAuth.instance.currentUser;

  Future<List<Map<String, dynamic>>> getAmici() async {
    if (user == null) return [];

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    final friendsIds = List<String>.from(userDoc.data()?['friends'] ?? []);

    final amiciData = await Future.wait(
      friendsIds.map((friendId) async {
        final friendDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(friendId)
            .get();

        if (!friendDoc.exists) return null;

        final data = friendDoc.data()!;

        return {'id': friendId, 'userName': data['userName'] ?? friendId};
      }).toList(),
    );

    return amiciData.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> rimuoviAmico(String friendId) async {
    if (user == null) return;

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid);

    await userRef.update({
      'friends': FieldValue.arrayRemove([friendId]),
    });

    final friendRef = FirebaseFirestore.instance
        .collection('users')
        .doc(friendId);
    await friendRef.update({
      'friends': FieldValue.arrayRemove([user!.uid]),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Amico rimosso')));

    setState(() {}); // Ricarica la pagina per aggiornare la lista
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Gestione Amici')),
        body: Center(child: Text('Utente non loggato')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Gestione Amici')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getAmici(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nessun amico trovato'));
          }

          final amici = snapshot.data!;

          return ListView.builder(
            itemCount: amici.length,
            itemBuilder: (context, index) {
              final amico = amici[index];
              final friendId = amico['id'] as String;
              final userName = amico['userName'] as String;

              return ListTile(
                leading: Icon(Icons.person, color: Colors.blue),
                title: Text(userName),
                trailing: TextButton(
                  onPressed: () async {
                    await rimuoviAmico(friendId);
                  },
                  child: const Text(
                    'Rimuovi',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

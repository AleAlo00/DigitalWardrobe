import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_wardrobe/pagine/Friends/dettagli_vestito_page_friends.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AllClothesPageFriends extends StatefulWidget {
  final String uid;

  const AllClothesPageFriends({super.key, required this.uid});

  @override
  State<AllClothesPageFriends> createState() => _AllClothesPageFriendsState();
}

class _AllClothesPageFriendsState extends State<AllClothesPageFriends> {
  List<Map<String, dynamic>> _tuttiIVestiti = [];
  List<Map<String, dynamic>> _vestitiFiltrati = [];
  bool _isLoading = true;
  bool _mostraSoloPreferiti = false;
  String _criterioOrdinamento = 'nessuno';
  String _queryRicerca = '';
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  Map<String, bool> _likesStatus = {};

  final Map<String, dynamic> categoryStyle = {
    'Calzini': {'icon': FontAwesomeIcons.socks, 'color': Colors.indigo},
    'Intimo': {'icon': 'assets/icons/underwear.png', 'color': Colors.purple},
    'Scarpe': {'icon': FontAwesomeIcons.shoePrints, 'color': Colors.grey},
    'Pantaloni': {'icon': 'assets/icons/pants.png', 'color': Colors.teal},
    'Magliette': {'icon': FontAwesomeIcons.shirt, 'color': Colors.lightGreen},
    'Felpe': {'icon': 'assets/icons/hoodie.png', 'color': Colors.green},
    'Giacche': {'icon': 'assets/icons/jacket.png', 'color': Colors.blue},
    'Cappelli e Sciarpe': {
      'icon': FontAwesomeIcons.hatCowboy,
      'color': Colors.deepOrange,
    },
  };

  @override
  void initState() {
    super.initState();
    _caricaVestiti();
    _caricaLikes();
  }

  Future<String> getUserNameById(String userId) async {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      if (data != null && data.containsKey('userName')) {
        return data['userName'] as String;
      }
    }
    return 'Utente sconosciuto';
  }

  Future<void> _caricaLikes() async {
    try {
      final likesSnapshot = await FirebaseFirestore.instance
          .collection('likes')
          .where('userId', isEqualTo: currentUserId)
          .get();

      final Map<String, bool> likesMap = {};
      for (var doc in likesSnapshot.docs) {
        final vestitoId = doc['vestitoId'];
        likesMap[vestitoId] = true;
      }

      setState(() {
        _likesStatus = likesMap;
      });
    } catch (e) {
      print("Errore nel caricamento dei like: $e");
    }
  }

  Future<void> _caricaVestiti() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('vestiti')
          .where('userId', isEqualTo: widget.uid)
          .get();

      final lista = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;

        String ownerName = 'Utente sconosciuto';
        if (userId != null) {
          ownerName = await getUserNameById(userId);
        }

        lista.add({...data, 'id': doc.id, 'ownerName': ownerName});
      }

      // Gestione likes (se serve, mantieni la tua logica)

      setState(() {
        _tuttiIVestiti = lista;
        _filtraVestiti();
        _isLoading = false;
      });
    } catch (e) {
      print("Errore nel caricamento vestiti: $e");
      setState(() {
        _isLoading = false;
        _tuttiIVestiti = [];
        _vestitiFiltrati = [];
      });
    }
  }

  void _filtraVestiti() {
    List<Map<String, dynamic>> lista = List.from(_tuttiIVestiti);

    if (_mostraSoloPreferiti) {
      lista = lista.where((v) => v['preferito'] == true).toList();
    }

    if (_queryRicerca.trim().isNotEmpty) {
      final query = _queryRicerca.toLowerCase();
      lista = lista.where((v) {
        final marca = (v['marca'] ?? '').toLowerCase();
        final categoria = (v['categoria'] ?? '').toLowerCase();
        return marca.contains(query) || categoria.contains(query);
      }).toList();
    }

    switch (_criterioOrdinamento) {
      case 'marca':
        lista.sort((a, b) => (a['marca'] ?? '').compareTo(b['marca'] ?? ''));
        break;
      case 'colore':
        lista.sort((a, b) => (a['colore'] ?? '').compareTo(b['colore'] ?? ''));
        break;
      case 'categoria':
        lista.sort((a, b) {
          final catA = a['categoria'] ?? '';
          final catB = b['categoria'] ?? '';
          final indexA = categoryStyle.keys.toList().indexOf(catA);
          final indexB = categoryStyle.keys.toList().indexOf(catB);
          return (indexA == -1 ? categoryStyle.length : indexA).compareTo(
            indexB == -1 ? categoryStyle.length : indexB,
          );
        });
        break;
      case 'taglia':
        lista.sort((a, b) => (a['taglia'] ?? '').compareTo(b['taglia'] ?? ''));
        break;
    }

    setState(() {
      _vestitiFiltrati = lista;
    });
  }

  Future<void> _toggleLike(String vestitoId) async {
    final liked = _likesStatus[vestitoId] ?? false;
    final likeDocId = '${currentUserId}_$vestitoId';
    final likeRef = FirebaseFirestore.instance
        .collection('likes')
        .doc(likeDocId);

    if (liked) {
      await likeRef.delete();
    } else {
      // Ottieni userName del proprietario del vestito
      final vestito = _tuttiIVestiti.firstWhere((v) => v['id'] == vestitoId);
      final userName = vestito['ownerName'] ?? 'Utente sconosciuto';

      await likeRef.set({
        'userId': currentUserId,
        'vestitoId': vestitoId,
        'userName': userName, // ➕ aggiunto
        'likedAt': FieldValue.serverTimestamp(),
      });
    }

    setState(() {
      _likesStatus[vestitoId] = !liked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tutti i vestiti')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Cerca per marca o categoria...',
                      hintStyle: const TextStyle(color: Colors.black54),
                      prefixIcon: const Icon(Icons.search, color: Colors.black),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() => _queryRicerca = val);
                      _filtraVestiti();
                    },
                  ),
                ),

                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (val) {
                    setState(() => _criterioOrdinamento = val);
                    _filtraVestiti();
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.white,
                  elevation: 4,
                  icon: Icon(
                    Icons.filter_list_rounded,
                    size: 28,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'nessuno',
                      child: Text('Nessun ordine'),
                    ),
                    PopupMenuItem(
                      value: 'marca',
                      child: Text('Ordina per marca'),
                    ),
                    PopupMenuItem(
                      value: 'colore',
                      child: Text('Ordina per colore'),
                    ),
                    PopupMenuItem(
                      value: 'categoria',
                      child: Text('Ordina per categoria'),
                    ),
                    PopupMenuItem(
                      value: 'taglia',
                      child: Text('Ordina per taglia'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _vestitiFiltrati.isEmpty
                ? const Center(child: Text('Nessun vestito trovato.'))
                : GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                    itemCount: _vestitiFiltrati.length,
                    itemBuilder: (context, index) {
                      final vestito = _vestitiFiltrati[index];
                      final vestitoId = vestito['id'];
                      final categoria = vestito['categoria'];
                      final coloreCategoria =
                          categoryStyle[categoria]?['color'] ??
                          Colors.grey.shade300;
                      final isLiked = _likesStatus[vestitoId] ?? false;

                      return InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DettagliVestitoPageFriends(vestito: vestito),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: coloreCategoria,
                              width: 5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade200,
                                blurRadius: 4,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      vestito['marca'] ?? 'Senza nome',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _toggleLike(vestitoId),
                                    child: Icon(
                                      isLiked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isLiked ? Colors.red : Colors.grey,
                                      size: 28,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                vestito['categoria'] ?? 'Categoria sconosciuta',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Taglia: ${vestito['taglia']}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                'Colore: ${vestito['colore']}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

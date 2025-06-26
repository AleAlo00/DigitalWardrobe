import 'package:digital_wardrobe/GestioneDB/firestore_like.dart';
import 'package:digital_wardrobe/pagine/Friends/dettagli_vestito_page_friends.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FriendsFavoriteClothesPage extends StatefulWidget {
  final String userId;

  const FriendsFavoriteClothesPage({Key? key, required this.userId})
    : super(key: key);

  @override
  State<FriendsFavoriteClothesPage> createState() =>
      _FriendsFavoriteClothesPageState();
}

class _FriendsFavoriteClothesPageState
    extends State<FriendsFavoriteClothesPage> {
  List<Map<String, dynamic>> _clothes = [];
  bool _loading = true;
  final LikeService _firestoreService = LikeService();

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
    _loadLikedClothes();
  }

  Future<void> _loadLikedClothes() async {
    setState(() => _loading = true);
    try {
      final clothes = await _firestoreService.getClothesILiked(widget.userId);
      setState(() {
        _clothes = clothes;
        _loading = false;
      });
    } catch (e) {
      print('Errore caricamento vestiti preferiti: $e');
      setState(() {
        _clothes = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredClothes = _clothes
        .where((item) => item['categoria'] != 'likes')
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Vestiti Preferiti')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : filteredClothes.isEmpty
          ? const Center(
              child: Text("Non hai ancora messo like a nessun vestito."),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: filteredClothes.length,
              itemBuilder: (context, index) {
                final vestito = filteredClothes[index];
                final categoria = vestito['categoria'];
                final coloreCategoria =
                    categoryStyle[categoria]?['color'] ?? Colors.grey.shade300;

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
                      border: Border.all(color: coloreCategoria, width: 5),
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
                        Text(
                          vestito['marca'] ?? 'Senza nome',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          categoria ?? 'Categoria sconosciuta',
                          style: const TextStyle(
                            fontSize: 17,
                            fontStyle: FontStyle.italic,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${vestito['ownerName'] ?? 'Sconosciuto'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.normal,
                            color: Colors.black54,
                          ),
                        ),

                        const Spacer(),
                        Text(
                          'Taglia: ${vestito['taglia'] ?? '-'}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Colore: ${vestito['colore'] ?? '-'}',
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
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_wardrobe/GestioneDB/firestore_like.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../Vestiti/dettagli_vestito_page.dart';

class AllClothesPage extends StatefulWidget {
  final String uid; // campo uid per identificare l'utente

  const AllClothesPage({super.key, required this.uid, required String userId});

  @override
  State<AllClothesPage> createState() => _AllClothesPageState();
}

class _AllClothesPageState extends State<AllClothesPage> {
  List<Map<String, dynamic>> _tuttiIVestiti = [];
  List<Map<String, dynamic>> _vestitiFiltrati = [];
  bool _isLoading = true;
  bool _mostraSoloPreferiti = false;
  String _criterioOrdinamento = 'nessuno';
  String _queryRicerca = '';

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
  }

  Future<void> _caricaVestiti() async {
    print('UID attuale: ${widget.uid}'); // <-- debug
    final snapshot = await FirebaseFirestore.instance
        .collection('vestiti')
        .where('userId', isEqualTo: widget.uid)
        .get();

    print('Numero documenti trovati: ${snapshot.docs.length}'); // <-- debug

    final lista = snapshot.docs.map((doc) {
      final data = doc.data();
      return {...data, 'id': doc.id};
    }).toList();

    setState(() {
      _tuttiIVestiti = lista;
      _filtraVestiti();
      _isLoading = false;
    });
  }

  void _filtraVestiti() {
    List<Map<String, dynamic>> lista = List.from(_tuttiIVestiti);

    if (_mostraSoloPreferiti) {
      lista = lista.where((v) => v['preferito'] == true).toList();
    }

    if (_queryRicerca.isNotEmpty) {
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

          final safeIndexA = indexA == -1 ? categoryStyle.length : indexA;
          final safeIndexB = indexB == -1 ? categoryStyle.length : indexB;

          return safeIndexA.compareTo(safeIndexB);
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

  Future<void> _togglePreferito(String id, bool attuale) async {
    await FirebaseFirestore.instance.collection('vestiti').doc(id).update({
      'preferito': !attuale,
    });
    final index = _tuttiIVestiti.indexWhere((v) => v['id'] == id);
    if (index != -1) {
      _tuttiIVestiti[index]['preferito'] = !attuale;
    }
    _filtraVestiti();
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
                      setState(() {
                        _queryRicerca = val;
                      });
                      _filtraVestiti();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Filtra preferiti',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      setState(() {
                        _mostraSoloPreferiti = !_mostraSoloPreferiti;
                      });
                      _filtraVestiti();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _mostraSoloPreferiti
                            ? Colors.amber
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _mostraSoloPreferiti ? Icons.star : Icons.star_border,
                        color: _mostraSoloPreferiti
                            ? Colors.white
                            : Colors.black54,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (val) {
                    setState(() {
                      _criterioOrdinamento = val;
                    });
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
                      child: Text(
                        'Nessun ordine',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'marca',
                      child: Text(
                        'Ordina per marca',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'colore',
                      child: Text(
                        'Ordina per colore',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'categoria',
                      child: Text(
                        'Ordina per categoria',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'taglia',
                      child: Text(
                        'Ordina per taglia',
                        style: TextStyle(color: Colors.black),
                      ),
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
                      final isPreferito = vestito['preferito'] ?? false;
                      final categoria = vestito['categoria'];
                      final coloreCategoria =
                          categoryStyle[categoria]?['color'] ??
                          Colors.grey.shade300;

                      return InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DettagliVestitoPage(vestito: vestito),
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
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
                                      GestureDetector(
                                        onTap: () => _togglePreferito(
                                          vestito['id'],
                                          isPreferito,
                                        ),
                                        child: Icon(
                                          isPreferito
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: isPreferito
                                              ? Colors.amber
                                              : Colors.grey,
                                          size: 30,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  FutureBuilder<int>(
                                    future: LikeService().countLikesForVestito(
                                      vestito['id'],
                                    ),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        );
                                      }
                                      if (snapshot.hasError ||
                                          (snapshot.data ?? 0) == 0) {
                                        return const SizedBox(); // Non mostra nulla se errore o 0 like
                                      }
                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          const Icon(
                                            Icons.favorite,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${snapshot.data}',
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
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

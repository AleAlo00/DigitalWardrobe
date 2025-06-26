import 'package:digital_wardrobe/pagine/Outfit/OutfitHistoryPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/scheduler.dart';

class OutfitPage extends StatefulWidget {
  const OutfitPage({super.key});

  @override
  State<OutfitPage> createState() => _OutfitPageState();
}

class _OutfitPageState extends State<OutfitPage>
    with SingleTickerProviderStateMixin {
  final List<String> categorieRichieste = [
    'Calzini',
    'Intimo',
    'Scarpe',
    'Magliette',
    'Pantaloni',
    'Felpe',
    'Giacche',
    'Cappelli e Sciarpe',
  ];

  Map<String, List<Map<String, dynamic>>> vestitiPerCategoria = {};
  Map<String, Map<String, dynamic>?> selezionati = {};

  int categoriaIndex = 0;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _outfitGiaSalvato = false;

  DateTime? _prossimoSalvataggio;
  Duration _tempoResiduo = Duration.zero;
  Ticker? _ticker;

  @override
  void initState() {
    super.initState();
    caricaVestiti();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  Future<void> caricaVestiti() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final snapshotVestiti = await FirebaseFirestore.instance
        .collection('vestiti')
        .where('userId', isEqualTo: uid)
        .get();

    final vestiti = snapshotVestiti.docs
        .map((d) => {'id': d.id, ...d.data()})
        .toList();

    final mappa = <String, List<Map<String, dynamic>>>{};
    for (var cat in categorieRichieste) {
      mappa[cat] = vestiti.where((v) => v['categoria'] == cat).toList();
    }

    final snapshotOutfits = await FirebaseFirestore.instance
        .collection('outfits')
        .where('userId', isEqualTo: uid)
        .orderBy('data', descending: true)
        .limit(1)
        .get();

    if (snapshotOutfits.docs.isNotEmpty) {
      final lastOutfitDate = (snapshotOutfits.docs.first['data'] as Timestamp)
          .toDate();
      _prossimoSalvataggio = lastOutfitDate.add(const Duration(hours: 24));
      final now = DateTime.now();

      if (now.isBefore(_prossimoSalvataggio!)) {
        _tempoResiduo = _prossimoSalvataggio!.difference(now);
        _startTimer();
        _outfitGiaSalvato = true;
      }
    }

    setState(() {
      vestitiPerCategoria = mappa;
      _isLoading = false;
    });
  }

  void _startTimer() {
    _ticker?.dispose();
    _ticker = createTicker((elapsed) {
      final now = DateTime.now();
      if (_prossimoSalvataggio == null) return;

      if (now.isAfter(_prossimoSalvataggio!)) {
        setState(() {
          _outfitGiaSalvato = false;
          _tempoResiduo = Duration.zero;
          _ticker?.stop();
        });
      } else {
        setState(() {
          _tempoResiduo = _prossimoSalvataggio!.difference(now);
        });
      }
    });

    _ticker?.start();
  }

  Future<void> salvaOutfit() async {
    final obbligatorie = [
      'Calzini',
      'Intimo',
      'Scarpe',
      'Magliette',
      'Pantaloni',
    ];

    for (var cat in obbligatorie) {
      if (selezionati[cat] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Seleziona un vestito per la categoria $cat")),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    final userId = FirebaseAuth.instance.currentUser!.uid;
    final oggi = DateTime.now();

    final snapshot = await FirebaseFirestore.instance
        .collection('outfits')
        .where('userId', isEqualTo: userId)
        .get();

    final esisteOutfitOggi = snapshot.docs.any((doc) {
      final data = (doc['data'] as Timestamp).toDate();
      return data.year == oggi.year &&
          data.month == oggi.month &&
          data.day == oggi.day;
    });

    if (esisteOutfitOggi) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hai già salvato l'outfit di oggi.")),
      );
      setState(() => _isSaving = false);
      return;
    }

    final Map<String, dynamic> vestitiDaSalvare = {};
    for (var cat in categorieRichieste) {
      final selezione = selezionati[cat];
      vestitiDaSalvare[cat] = selezione?['id'] ?? "nessuno";
    }

    final data = {'userId': userId, 'data': oggi, 'vestiti': vestitiDaSalvare};

    try {
      await FirebaseFirestore.instance.collection('outfits').add(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Outfit salvato con successo!")),
      );

      setState(() {
        _outfitGiaSalvato = true;
        _prossimoSalvataggio = DateTime.now().add(const Duration(hours: 24));
        _tempoResiduo = const Duration(hours: 24);
        _startTimer();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Errore: $e")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void avantiCategoria() {
    final categoriaCorrente = categorieRichieste[categoriaIndex];
    final obbligatorie = [
      'Calzini',
      'Intimo',
      'Scarpe',
      'Magliette',
      'Pantaloni',
    ];

    if (obbligatorie.contains(categoriaCorrente) &&
        selezionati[categoriaCorrente] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seleziona un vestito per continuare")),
      );
      return;
    }

    if (categoriaIndex < categorieRichieste.length - 1) {
      setState(() => categoriaIndex++);
    } else {
      salvaOutfit();
    }
  }

  String formattaDurata(Duration d) {
    final ore = d.inHours;
    final minuti = d.inMinutes % 60;
    final secondi = d.inSeconds % 60;
    return '${ore.toString().padLeft(2, '0')}:'
        '${minuti.toString().padLeft(2, '0')}:'
        '${secondi.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final categoria = categorieRichieste[categoriaIndex];

    if (_outfitGiaSalvato) {
      return Scaffold(
        appBar: AppBar(title: const Text("Outfit")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 32,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.redAccent, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    "Hai già salvato l'outfit di oggi.\nPotrai salvare un nuovo outfit tra:",
                    style: const TextStyle(
                      fontSize: 26, // testo più grande
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                _buildCustomButton(
                  icon: Icons.timer,
                  label: formattaDurata(_tempoResiduo),
                  color: Colors.redAccent,
                  onTap: () {},
                ),
                const SizedBox(height: 24),
                _buildCustomButton(
                  icon: Icons.history,
                  label: 'Storico Outfit',
                  color: Colors.blueAccent,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const OutfitHistoryPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    final vestiti = List<Map<String, dynamic>>.from(
      vestitiPerCategoria[categoria] ?? [],
    );

    final categorieConNessuno = ['Felpe', 'Giacche', 'Cappelli e Sciarpe'];
    if (categorieConNessuno.contains(categoria)) {
      vestiti.insert(0, {
        'id': null,
        'marca': 'Nessuno',
        'colore': '',
        'taglia': '',
        'preferito': false,
      });
    }

    final selezionato = selezionati[categoria]?['id'];

    return Scaffold(
      appBar: AppBar(title: Text("Outfit: $categoria")),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: vestiti.length,
              itemBuilder: (context, index) {
                final v = vestiti[index];
                final isSelected = v['id'] == selezionato;
                final isNessuno = v['id'] == null;
                final isPreferito =
                    v['preferito'] == true; // qui controlli se è preferito

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selezionati[categoria] = isSelected ? null : v;
                    });
                  },
                  onDoubleTap: () {
                    final obbligatorie = [
                      'Calzini',
                      'Intimo',
                      'Scarpe',
                      'Magliette',
                      'Pantaloni',
                    ];
                    if (!obbligatorie.contains(categoria) ||
                        selezionati[categoria] != null) {
                      avantiCategoria();
                    }
                  },
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.green : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected
                              ? Border.all(color: Colors.green, width: 4)
                              : null,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Center(
                          child: isNessuno
                              ? const Icon(
                                  Icons.block,
                                  size: 48,
                                  color: Colors.grey,
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      v['marca'] ?? '',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Taglia: ${v['taglia'] ?? ''}",
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      "Colore: ${v['colore'] ?? ''}",
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      if (isPreferito)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Icon(
                            Icons.star,
                            color: Colors.yellow[700],
                            size: 24,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: _buildCustomButton(
              label: categoriaIndex == categorieRichieste.length - 1
                  ? 'Salva Outfit'
                  : 'Avanti',
              onTap:
                  (_isSaving ||
                      ([
                            'Calzini',
                            'Intimo',
                            'Scarpe',
                            'Magliette',
                            'Pantaloni',
                          ].contains(categoria) &&
                          selezionati[categoria] == null))
                  ? null
                  : avantiCategoria,
              color: Colors.redAccent,
              enabled:
                  !(_isSaving ||
                      ([
                            'Calzini',
                            'Intimo',
                            'Scarpe',
                            'Magliette',
                            'Pantaloni',
                          ].contains(categoria) &&
                          selezionati[categoria] == null)),
              icon: _isSaving
                  ? null
                  : (categoriaIndex == categorieRichieste.length - 1
                        ? Icons.save
                        : null),
              centerText: categoriaIndex != categorieRichieste.length - 1,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildCustomButton({
  required String label,
  required VoidCallback? onTap,
  Color color = Colors.redAccent,
  bool enabled = true,
  IconData? icon,
  bool centerText = false,
}) {
  final backgroundColor = enabled
      ? color.withOpacity(0.1)
      : Colors.grey.withOpacity(0.2);
  final borderColor = enabled ? color : Colors.grey;
  final textColor = enabled ? color.withOpacity(0.8) : Colors.grey;

  return InkWell(
    onTap: enabled ? onTap : null,
    borderRadius: BorderRadius.circular(16),
    splashColor: enabled ? color.withOpacity(0.3) : Colors.transparent,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: centerText
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          if (icon != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: enabled ? color : Colors.grey,
                borderRadius: BorderRadius.circular(12),
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.6),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          if (icon != null && !centerText) const SizedBox(width: 20),
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    ),
  );
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_wardrobe/GestioneDB/firestore_categories.dart';
import 'package:digital_wardrobe/pagine/Wardbrode/all_clothes_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class WardrobePage extends StatefulWidget {
  const WardrobePage({super.key});

  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  List<String> _categoryTitles = [];
  Map<String, List<Map<String, dynamic>>> _vestitiPerCategoria = {};
  bool _isLoading = true;
  String _currentUserId = '';

  // Mappa per tenere traccia di quali categorie sono espanse
  Map<String, bool> _expandedCategories = {};

  // Mappa stile categorie con icona e colore
  final Map<String, dynamic> categoryStyle = {
    'Calzini': {'icon': FontAwesomeIcons.socks, 'color': Colors.indigo},
    'Intimo': {
      'icon': 'assets/icons/underwear.png',
      'color': Colors.deepPurple,
    },
    'Scarpe': {'icon': FontAwesomeIcons.shoePrints, 'color': Colors.grey},
    'Pantaloni': {'icon': 'assets/icons/pants.png', 'color': Colors.teal},
    'Magliette': {'icon': FontAwesomeIcons.shirt, 'color': Colors.lightGreen},
    'Felpe': {'icon': 'assets/icons/hoodie.png', 'color': Colors.green},
    'Giacche': {'icon': 'assets/icons/jacket.png', 'color': Colors.blue},
    'Cappelli e Sciarpe': {
      'icon': FontAwesomeIcons.hatCowboy,
      'color': Colors.orange,
    },
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    await CategoryService().addDefaultCategoriesIfEmpty();
    final categories = await CategoryService().getCategories();

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Gestisci utente non loggato, eventualmente naviga al login o mostra errore
      setState(() => _isLoading = false);
      return;
    }
    _currentUserId = currentUser.uid;

    final vestitiSnapshot = await FirebaseFirestore.instance
        .collection('vestiti')
        .where('userId', isEqualTo: _currentUserId)
        .get();

    final Map<String, List<Map<String, dynamic>>> vestitiPerCategoria = {};
    for (var doc in vestitiSnapshot.docs) {
      final data = doc.data();
      final categoria = data['categoria'] ?? 'Senza categoria';
      if (!vestitiPerCategoria.containsKey(categoria)) {
        vestitiPerCategoria[categoria] = [];
      }
      vestitiPerCategoria[categoria]!.add({...data, 'id': doc.id});
    }

    // Inizializza tutte le categorie come chiuse
    _expandedCategories = {for (var c in categories) c: false};

    setState(() {
      _categoryTitles = categories;
      _vestitiPerCategoria = vestitiPerCategoria;
      _isLoading = false;
    });
  }

  Future<void> _togglePreferito(String vestitoId, bool statoAttuale) async {
    await FirebaseFirestore.instance
        .collection('vestiti')
        .doc(vestitoId)
        .update({'preferito': !statoAttuale});

    setState(() {
      for (var categoria in _vestitiPerCategoria.keys) {
        for (var vestito in _vestitiPerCategoria[categoria]!) {
          if (vestito['id'] == vestitoId) {
            vestito['preferito'] = !statoAttuale;
            return;
          }
        }
      }
    });
  }

  void _toggleCategoryExpand(String category) {
    setState(() {
      _expandedCategories[category] = !(_expandedCategories[category] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Il mio armadio')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  _buildCustomButton(
                    icon: Icons.grid_view,
                    label: 'Tutti i vestiti',
                    color: Colors.red,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AllClothesPage(
                            uid: _currentUserId,
                            userId: _currentUserId,
                          ),
                        ),
                      );
                      await _loadData();
                    },
                  ),

                  ..._categoryTitles.map((title) {
                    final icon =
                        categoryStyle[title]?['icon'] ?? Icons.category;
                    final color =
                        categoryStyle[title]?['color'] ?? Colors.black;
                    final vestiti = _vestitiPerCategoria[title] ?? [];
                    final isExpanded = _expandedCategories[title] ?? false;
                    final count = vestiti.length;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () => _toggleCategoryExpand(title),
                            borderRadius: BorderRadius.circular(16),
                            splashColor: color.withOpacity(0.3),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 24,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withOpacity(0.6),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: _buildIconWidget(icon),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Text(
                                      '$title  ($count)',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: color.withOpacity(0.8),
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    isExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    color: color.withOpacity(0.8),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (isExpanded)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                                bottom: 16,
                              ),
                              child: vestiti.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      child: Text(
                                        "Nessun vestito presente.",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  : Column(
                                      children: vestiti.map((v) {
                                        final bool isPreferito =
                                            v['preferito'] ?? false;
                                        return Slidable(
                                          key: ValueKey(v['id']),
                                          endActionPane: ActionPane(
                                            motion: const ScrollMotion(),
                                            children: [
                                              SlidableAction(
                                                onPressed: (context) =>
                                                    _togglePreferito(
                                                      v['id'],
                                                      isPreferito,
                                                    ),
                                                backgroundColor: isPreferito
                                                    ? Colors.red
                                                    : Colors.amber,
                                                foregroundColor: Colors.white,
                                                icon: isPreferito
                                                    ? Icons.star_outline
                                                    : Icons.star,
                                                label: isPreferito
                                                    ? 'Rimuovi'
                                                    : 'Preferito',
                                              ),
                                            ],
                                          ),
                                          child: ListTile(
                                            leading: const Icon(
                                              Icons.checkroom,
                                            ),
                                            title: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    v['marca'] ?? 'Senza nome',
                                                  ),
                                                ),
                                                if (isPreferito)
                                                  const Icon(
                                                    Icons.star,
                                                    color: Colors.amber,
                                                    size: 20,
                                                  ),
                                              ],
                                            ),
                                            subtitle: Text(
                                              'Taglia: ${v['taglia'] ?? '-'} - Colore: ${v['colore'] ?? '-'}',
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
    );
  }

  // Funzione helper per icone/immagini asset
  Widget _buildIconWidget(dynamic icon) {
    if (icon is IconData) {
      Widget iconBase = Icon(icon, color: Colors.white, size: 26);

      // Sposta a sinistra solo le icone che ne hanno bisogno
      if (icon == FontAwesomeIcons.shirt ||
          icon == FontAwesomeIcons.hatCowboy ||
          icon == FontAwesomeIcons.shoePrints) {
        iconBase = Transform.translate(
          offset: const Offset(-3, 0), // Sposta leggermente a sinistra
          child: iconBase,
        );
      }

      return iconBase;
    } else if (icon is String) {
      return Image.asset(
        icon,
        width: 28,
        height: 28,
        color: Colors.white,
        colorBlendMode: BlendMode.srcIn,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.help_outline, color: Colors.white, size: 26);
        },
      );
    } else {
      return const Icon(Icons.help_outline, color: Colors.white, size: 26);
    }
  }

  Widget _buildCustomButton({
    required dynamic icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.redAccent,
  }) {
    Widget iconWidget;
    if (icon is String) {
      iconWidget = Image.asset(
        icon,
        width: 28,
        height: 28,
        color: Colors.white,
        colorBlendMode: BlendMode.srcIn,
      );
    } else if (icon is IconData) {
      Widget iconBase = Icon(icon, color: Colors.white, size: 26);

      if (icon == FontAwesomeIcons.shirt ||
          icon == FontAwesomeIcons.hatCowboy ||
          icon == FontAwesomeIcons.shoePrints) {
        iconBase = Transform.translate(
          offset: const Offset(-2, 0),
          child: iconBase,
        );
      }

      iconWidget = iconBase;
    } else {
      iconWidget = const Icon(
        Icons.help_outline,
        color: Colors.white,
        size: 26,
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: color.withOpacity(0.3),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.6),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: iconWidget,
            ),
            const SizedBox(width: 20),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

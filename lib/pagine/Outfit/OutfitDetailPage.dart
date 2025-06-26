import 'package:digital_wardrobe/pagine/Vestiti/dettagli_vestito_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OutfitDetailsPage extends StatelessWidget {
  final String outfitId;

  OutfitDetailsPage({super.key, required this.outfitId});

  final Map<String, dynamic> categoryStyle = {
    'Calzini': {'icon': Icons.checkroom, 'color': Colors.indigo},
    'Intimo': {'icon': Icons.checkroom, 'color': Colors.deepPurple},
    'Scarpe': {'icon': Icons.checkroom, 'color': Colors.brown},
    'Pantaloni': {'icon': Icons.checkroom, 'color': Colors.teal},
    'Magliette': {'icon': Icons.checkroom, 'color': Colors.lightGreen},
    'Felpe': {'icon': Icons.checkroom, 'color': Colors.green},
    'Giacche': {'icon': Icons.checkroom, 'color': Colors.blue},
    'Cappelli e Sciarpe': {'icon': Icons.checkroom, 'color': Colors.orange},
  };

  Future<Map<String, Map<String, dynamic>>> fetchClothesInfo(
    Map<String, dynamic> vestiti,
  ) async {
    final clothesInfo = <String, Map<String, dynamic>>{};

    for (final entry in vestiti.entries) {
      final categoria = entry.key;
      final vestitoId = entry.value;

      if (vestitoId != null &&
          vestitoId is String &&
          vestitoId.isNotEmpty &&
          vestitoId != "nessuno") {
        final doc = await FirebaseFirestore.instance
            .collection('vestiti')
            .doc(vestitoId)
            .get();

        if (doc.exists) {
          clothesInfo[categoria] = doc.data()!;
        } else {
          clothesInfo[categoria] = {'marca': 'Non trovato', 'colore': ''};
        }
      } else {
        clothesInfo[categoria] = {'marca': 'Nessuno', 'colore': ''};
      }
    }

    return clothesInfo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dettagli Outfit')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('outfits')
            .doc(outfitId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Errore nel caricamento'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Outfit non trovato.'));
          }

          final outfit = snapshot.data!.data() as Map<String, dynamic>;
          final data = (outfit['data'] as Timestamp?)?.toDate();
          final vestiti = outfit['vestiti'] as Map<String, dynamic>? ?? {};

          return FutureBuilder<Map<String, Map<String, dynamic>>>(
            future: fetchClothesInfo(vestiti),
            builder: (context, vestitiSnapshot) {
              if (vestitiSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final vestitiInfo = vestitiSnapshot.data ?? {};

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data != null)
                      Text(
                        '📅 Data: ${data.day}/${data.month}/${data.year}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      'Vestiti selezionati:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView(
                        children: categoryStyle.keys.map((categoria) {
                          final info = vestitiInfo[categoria];
                          if (info == null) return const SizedBox.shrink();

                          final coloreStr = (info['colore'] ?? '').toString();
                          final marca = (info['marca'] ?? '').toString();
                          final color =
                              categoryStyle[categoria]!['color'] as Color;

                          final vestitoId = vestiti[categoria];

                          return _buildCustomButton(
                            icon: Icons.checkroom,
                            label:
                                '$categoria: ${marca == "Nessuno" ? "Nessuno" : "Marca: $marca | Colore: $coloreStr"}',
                            onTap:
                                (vestitoId != null &&
                                    vestitoId is String &&
                                    vestitoId.isNotEmpty &&
                                    vestitoId != 'nessuno')
                                ? () {
                                    final vestitoData = vestitiInfo[categoria]!;
                                    vestitoData['id'] =
                                        vestitoId; // Se vuoi includere anche l'ID

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DettagliVestitoPage(
                                          vestito: vestitoData,
                                        ),
                                      ),
                                    );
                                  }
                                : () {},

                            color: color,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCustomButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.redAccent,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: color.withOpacity(0.3),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        margin: const EdgeInsets.symmetric(vertical: 8),
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
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_wardrobe/pagine/Outfit/OutfitDetailPage.dart';
import 'package:flutter/material.dart';

class FriendsOutfitsPage extends StatefulWidget {
  final String friendUid;

  const FriendsOutfitsPage({super.key, required this.friendUid});

  @override
  State<FriendsOutfitsPage> createState() => _OutfitHistoryPageState();
}

class _OutfitHistoryPageState extends State<FriendsOutfitsPage> {
  bool _isLoading = true;
  Map<String, List<Map<String, dynamic>>> _outfitsPerGiorno = {};

  @override
  void initState() {
    super.initState();
    _caricaOutfitStorico();
  }

  Future<void> _caricaOutfitStorico() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('outfits')
        .where(
          'userId',
          isEqualTo: widget.friendUid,
        ) // usa friendUid, non userId corrente
        .orderBy('data', descending: true)
        .get();

    final Map<String, List<Map<String, dynamic>>> raggruppati = {};

    for (var doc in snapshot.docs) {
      final data = (doc['data'] as Timestamp).toDate();
      final giornoKey =
          "${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}";

      raggruppati.putIfAbsent(giornoKey, () => []);
      raggruppati[giornoKey]!.add({'id': doc.id, 'data': data});
    }

    setState(() {
      _outfitsPerGiorno = raggruppati;
      _isLoading = false;
    });
  }

  Widget _buildDayButton(String giornoKey, List<Map<String, dynamic>> outfits) {
    final parts = giornoKey.split('-');
    final data = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final label =
        "${data.day}/${data.month}/${data.year} — ${outfits.length} outfit";

    return _buildCustomButton(
      icon: Icons.history,
      label: label,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OutfitDetailsPage(outfitId: outfits.first['id']),
          ),
        );
      },
      color: Colors.cyan,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Storico Outfit")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_outfitsPerGiorno.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Storico Outfit")),
        body: const Center(child: Text("Nessun outfit salvato.")),
      );
    }

    final giorni = _outfitsPerGiorno.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // dal più recente

    return Scaffold(
      appBar: AppBar(title: const Text("Storico Outfit")),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        children: giorni
            .map(
              (giornoKey) =>
                  _buildDayButton(giornoKey, _outfitsPerGiorno[giornoKey]!),
            )
            .toList(),
      ),
    );
  }
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

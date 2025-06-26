import 'package:digital_wardrobe/GestioneDB/firestore_like.dart';
import 'package:flutter/material.dart';
import 'modifica_vestito_page.dart';

class DettagliVestitoPage extends StatefulWidget {
  final Map<String, dynamic> vestito;

  const DettagliVestitoPage({super.key, required this.vestito});

  @override
  State<DettagliVestitoPage> createState() => _DettagliVestitoPageState();
}

class _DettagliVestitoPageState extends State<DettagliVestitoPage> {
  late Map<String, dynamic> vestito;

  @override
  void initState() {
    super.initState();
    vestito = widget.vestito;
  }

  void _aggiornaVestito(Map<String, dynamic> vestitoModificato) {
    setState(() {
      vestito = vestitoModificato;
    });
  }

  @override
  Widget build(BuildContext context) {
    final coloreCategoria = _getCategoriaColor(vestito['categoria']);

    return Scaffold(
      appBar: AppBar(
        title: Text(vestito['marca'] ?? 'Dettagli vestito'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Modifica vestito',
            onPressed: () async {
              final result = await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(
                  builder: (context) => ModificaVestitoPage(vestito: vestito),
                ),
              );
              if (result != null) _aggiornaVestito(result);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(
              color: coloreCategoria.withOpacity(0.8),
              width: 5,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: coloreCategoria.withOpacity(0.4),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vestito['marca'] ?? 'Marca sconosciuta',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Categoria: ${vestito['categoria'] ?? 'Sconosciuta'}',
                style: TextStyle(
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              const Divider(height: 30),
              _buildInfoRow('Taglia', vestito['taglia']),
              _buildInfoRow('Colore', vestito['colore']),
              _buildInfoRow(
                'Preferito',
                (vestito['preferito'] ?? false) ? 'Sì' : 'No',
              ),
              const Divider(height: 30),
              const Text(
                'Descrizione:',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                vestito['descrizione'] ?? 'Nessuna descrizione disponibile.',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              FutureBuilder<List<String>>(
                future: LikeService().getUsernamesWhoLikedVestito(
                  vestito['id'],
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return const Text('Nessun like ricevuto.');
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Piace a:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: snapshot.data!
                            .map((username) => Chip(label: Text(username)))
                            .toList(),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String titolo, dynamic valore) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            '$titolo: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Flexible(
            child: Text(
              valore?.toString() ?? '-',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoriaColor(String? categoria) {
    switch (categoria) {
      case 'Calzini':
        return Colors.indigo;
      case 'Intimo':
        return Colors.deepPurple;
      case 'Scarpe':
        return Colors.grey;
      case 'Pantaloni':
        return Colors.teal;
      case 'Magliette':
        return Colors.lightGreen;
      case 'Felpe':
        return Colors.green;
      case 'Giacche':
        return Colors.blue;
      case 'Cappelli e Sciarpe':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

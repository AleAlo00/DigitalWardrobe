import 'package:digital_wardrobe/GestioneDB/firestore_clothes.dart';
import 'package:flutter/material.dart';

class AddClothingPage extends StatefulWidget {
  const AddClothingPage({super.key});

  @override
  State<AddClothingPage> createState() => _AddClothingPageState();
}

class _AddClothingPageState extends State<AddClothingPage> {
  final _formKey = GlobalKey<FormState>();

  String _marca = '';
  String? _categoriaSelezionata;
  String? _tagliaSelezionata;
  String? _coloreSelezionato;

  final List<String> _categorieDisponibili = [
    'Calzini',
    'Intimo',
    'Scarpe',
    'Pantaloni',
    'Magliette',
    'Felpe',
    'Giacche',
    'Cappelli e Sciarpe',
  ];

  List<String> get _taglieDisponibili {
    if (_categoriaSelezionata == 'Scarpe') {
      return List.generate(21, (i) => (30 + i).toString());
    } else if (_categoriaSelezionata == 'Calzini') {
      return ['30-35', '36-41', '42-45', '46-50'];
    }
    return ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  }

  final List<String> _coloriDisponibili = [
    'Nero',
    'Bianco',
    'Rosso',
    'Blu',
    'Verde',
    'Giallo',
    'Grigio',
    'Rosa',
    'Beige',
    'Marrone',
    'Viola',
    'Arancione',
  ];

  final OutlineInputBorder _inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(30),
    borderSide: const BorderSide(color: Colors.grey),
  );

  Future<void> _salvaVestito() async {
    if (!_formKey.currentState!.validate() ||
        _categoriaSelezionata == null ||
        _tagliaSelezionata == null ||
        _coloreSelezionato == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Compila tutti i campi')));
      return;
    }

    _formKey.currentState!.save();

    try {
      await ClothingService().addClothing(
        marca: _marca,
        categoria: _categoriaSelezionata!,
        taglia: _tagliaSelezionata!,
        colore: _coloreSelezionato!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vestito aggiunto con successo!')),
      );

      // Torna indietro passando true per indicare aggiornamento
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aggiungi Vestito')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // MARCA
              TextFormField(
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Marca',
                  labelStyle: const TextStyle(color: Colors.black),
                  filled: true,
                  fillColor: Colors.white,
                  border: _inputBorder,
                  enabledBorder: _inputBorder,
                  focusedBorder: _inputBorder.copyWith(
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 24,
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Inserisci la marca'
                    : null,
                onSaved: (value) => _marca = value!,
              ),
              const SizedBox(height: 16),

              // CATEGORIA
              DropdownButtonFormField<String>(
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Categoria',
                  labelStyle: const TextStyle(color: Colors.black),
                  filled: true,
                  fillColor: Colors.white,
                  border: _inputBorder,
                  enabledBorder: _inputBorder,
                  focusedBorder: _inputBorder.copyWith(
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 24,
                  ),
                ),
                value: _categoriaSelezionata,
                items: _categorieDisponibili
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _categoriaSelezionata = value;
                    _tagliaSelezionata = null;
                  });
                },
                validator: (value) =>
                    value == null ? 'Seleziona una categoria' : null,
              ),
              const SizedBox(height: 16),

              // TAGLIA
              DropdownButtonFormField<String>(
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: _categoriaSelezionata == 'Scarpe'
                      ? 'Numero Scarpe'
                      : _categoriaSelezionata == 'Calzini'
                      ? 'Taglia Calzini'
                      : 'Taglia',
                  labelStyle: const TextStyle(color: Colors.black),
                  filled: true,
                  fillColor: Colors.white,
                  border: _inputBorder,
                  enabledBorder: _inputBorder,
                  focusedBorder: _inputBorder.copyWith(
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 24,
                  ),
                ),
                value: _taglieDisponibili.contains(_tagliaSelezionata)
                    ? _tagliaSelezionata
                    : null,
                items: _taglieDisponibili
                    .map(
                      (size) =>
                          DropdownMenuItem(value: size, child: Text(size)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _tagliaSelezionata = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Seleziona una taglia' : null,
              ),
              const SizedBox(height: 16),

              // COLORE
              DropdownButtonFormField<String>(
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Colore',
                  labelStyle: const TextStyle(color: Colors.black),
                  filled: true,
                  fillColor: Colors.white,
                  border: _inputBorder,
                  enabledBorder: _inputBorder,
                  focusedBorder: _inputBorder.copyWith(
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 24,
                  ),
                ),
                value: _coloreSelezionato,
                items: _coloriDisponibili
                    .map(
                      (col) => DropdownMenuItem(value: col, child: Text(col)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _coloreSelezionato = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Seleziona un colore' : null,
              ),
              const SizedBox(height: 30),

              // BOTTONE SALVA
              ElevatedButton.icon(
                onPressed: _salvaVestito,
                icon: const Icon(Icons.save, size: 26),
                label: const Text('Salva Vestito'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 28,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 8,
                  shadowColor: Colors.redAccent.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

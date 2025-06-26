import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ModificaVestitoPage extends StatefulWidget {
  final Map<String, dynamic> vestito;

  const ModificaVestitoPage({super.key, required this.vestito});

  @override
  State<ModificaVestitoPage> createState() => _ModificaVestitoPageState();
}

class _ModificaVestitoPageState extends State<ModificaVestitoPage> {
  final _formKey = GlobalKey<FormState>();

  String _marca = '';
  String? _categoriaSelezionata;
  String? _tagliaSelezionata;
  String? _coloreSelezionato;
  String? _descrizione;
  bool _preferito = false;
  bool _isSaving = false;

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

  @override
  void initState() {
    super.initState();
    final v = widget.vestito;
    _marca = v['marca'] ?? '';
    _categoriaSelezionata = v['categoria'];
    _tagliaSelezionata = v['taglia'];
    _coloreSelezionato = v['colore'];
    _descrizione = v['descrizione'];
    _preferito = v['preferito'] ?? false;
  }

  Future<void> _salvaModifiche() async {
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

    setState(() {
      _isSaving = true;
    });

    final docId = widget.vestito['id'];

    final updatedData = {
      'marca': _marca.trim(),
      'categoria': _categoriaSelezionata,
      'taglia': _tagliaSelezionata,
      'colore': _coloreSelezionato,
      'descrizione': _descrizione?.trim() ?? '',
      'preferito': _preferito,
    };

    try {
      await FirebaseFirestore.instance
          .collection('vestiti')
          .doc(docId)
          .update(updatedData);

      Navigator.pop(context, {...widget.vestito, ...updatedData});
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante il salvataggio: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifica Vestito')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isSaving
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // MARCA
                    TextFormField(
                      initialValue: _marca,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Marca',
                        labelStyle: const TextStyle(
                          color: Colors.red,
                        ), // <-- AGGIUNTO
                        border: _inputBorder,
                        enabledBorder: _inputBorder,
                        focusedBorder: _inputBorder.copyWith(
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Inserisci la marca'
                          : null,
                      onSaved: (value) => _marca = value!,
                    ),
                    const SizedBox(height: 16),

                    // CATEGORIA
                    DropdownButtonFormField<String>(
                      value: _categoriaSelezionata,
                      style: const TextStyle(color: Colors.black),
                      dropdownColor: Colors.white,
                      items: _categorieDisponibili
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                c,
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _categoriaSelezionata = val;
                          _tagliaSelezionata = null;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Categoria',
                        labelStyle: const TextStyle(
                          color: Colors.red,
                        ), // <-- AGGIUNTO
                        border: _inputBorder,
                        enabledBorder: _inputBorder,
                        focusedBorder: _inputBorder.copyWith(
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) =>
                          value == null ? 'Seleziona una categoria' : null,
                    ),
                    const SizedBox(height: 16),

                    // TAGLIA
                    DropdownButtonFormField<String>(
                      value: _taglieDisponibili.contains(_tagliaSelezionata)
                          ? _tagliaSelezionata
                          : null,
                      style: const TextStyle(color: Colors.black),
                      dropdownColor: Colors.white,
                      items: _taglieDisponibili
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(
                                t,
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _tagliaSelezionata = val;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: _categoriaSelezionata == 'Scarpe'
                            ? 'Numero Scarpe'
                            : _categoriaSelezionata == 'Calzini'
                            ? 'Taglia Calzini'
                            : 'Taglia',
                        labelStyle: const TextStyle(
                          color: Colors.red,
                        ), // <-- AGGIUNTO
                        border: _inputBorder,
                        enabledBorder: _inputBorder,
                        focusedBorder: _inputBorder.copyWith(
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) =>
                          value == null ? 'Seleziona una taglia' : null,
                    ),
                    const SizedBox(height: 16),
                    // COLORE
                    DropdownButtonFormField<String>(
                      value: _coloreSelezionato,
                      style: const TextStyle(color: Colors.black),
                      dropdownColor: Colors.white,
                      items: _coloriDisponibili
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                c,
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _coloreSelezionato = val;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Colore',
                        labelStyle: const TextStyle(
                          color: Colors.red,
                        ), // label quando non fluttua
                        floatingLabelStyle: const TextStyle(
                          color: Colors.red,
                        ), // label fluttuante
                        border: _inputBorder,
                        enabledBorder: _inputBorder,
                        focusedBorder: _inputBorder.copyWith(
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),

                      validator: (value) =>
                          value == null ? 'Seleziona un colore' : null,
                    ),
                    const SizedBox(height: 16),

                    // DESCRIZIONE
                    TextFormField(
                      initialValue: _descrizione,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Descrizione',
                        labelStyle: const TextStyle(
                          color: Colors.red,
                        ), // <-- AGGIUNTO
                        filled: true,
                        fillColor: Colors.white,
                        border: _inputBorder,
                        enabledBorder: _inputBorder,
                        focusedBorder: _inputBorder.copyWith(
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                      ),
                      onSaved: (val) => _descrizione = val,
                    ),
                    const SizedBox(height: 10),

                    // PREFERITO
                    SwitchListTile(
                      title: const Text(
                        'Preferito',
                        style: TextStyle(color: Colors.red), 
                      ),
                      value: _preferito,
                      activeColor: Colors.red, 
                      onChanged: (val) {
                        setState(() {
                          _preferito = val;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed: _salvaModifiche,
                      icon: const Icon(Icons.save),
                      label: const Text('Salva'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 28,
                        ),
                        textStyle: const TextStyle(fontSize: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

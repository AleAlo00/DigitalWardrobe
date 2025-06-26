import 'package:digital_wardrobe/pagine/Wardbrode/add_clothing_page.dart';
import 'package:digital_wardrobe/pagine/settings_page.dart';
import 'package:flutter/material.dart';
import '../pagine/User/home_page.dart';
import '../pagine/Wardbrode/wardrobe_page.dart';
import '../pagine/Outfit/outfit_page.dart';

class MenuPage extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;
  final VoidCallback showColorPicker;
  final Color mainColor; // aggiunto
  final void Function(Color newColor) onMainColorChanged;

  const MenuPage({
    Key? key,
    required this.onThemeToggle,
    required this.isDarkMode,
    required this.showColorPicker,
    required this.mainColor,
    required this.onMainColorChanged,
  }) : super(key: key);

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (index == 2) {
      _onAddClothes();
      return;
    }
    setState(() {
      _selectedIndex = index > 2 ? index - 1 : index;
    });
  }

  void _onAddClothes() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddClothingPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      const HomePage(),
      WardrobePage(),
      const OutfitPage(),
      SettingsPage(
        onThemeToggle: widget.onThemeToggle,
        isDarkMode: widget.isDarkMode,
        showColorPicker: widget.showColorPicker,
        onMainColorChanged: widget.onMainColorChanged, // AGGIUNGI QUESTO
      ),
    ];

    // Colore principale
    final mainColor = widget.mainColor;
    // Colore per icone non selezionate (versione più chiara o opaca)
    mainColor.withOpacity(0.6);

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: mainColor,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.home, color: Colors.white),
                onPressed: () => _onItemTapped(0),
              ),
              IconButton(
                icon: const Icon(Icons.checkroom, color: Colors.white),
                onPressed: () => _onItemTapped(1),
              ),
              const SizedBox(width: 48),
              IconButton(
                icon: const Icon(Icons.style, color: Colors.white),
                onPressed: () => _onItemTapped(3),
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () => _onItemTapped(4),
              ),
            ],
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        height: 70,
        width: 70,
        child: FloatingActionButton(
          onPressed: _onAddClothes,
          backgroundColor: Colors.white,
          child: Icon(
            Icons.add,
            color: mainColor,
            size: 40,
          ), // usa colore principale
          elevation: 6,
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}

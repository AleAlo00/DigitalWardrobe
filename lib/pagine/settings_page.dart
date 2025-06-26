import 'package:digital_wardrobe/GestioneDB/firestore_users.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;
  final VoidCallback showColorPicker;
  final void Function(Color newColor) onMainColorChanged;

  final settingsService = UserServiceSettings();

  SettingsPage({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
    required this.showColorPicker,
    required this.onMainColorChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String userName = 'User';
  bool isLoading = true;
  Color mainColor = Colors.blueAccent;
  bool autoThemeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final name = await UserService().getUserName();
      final colorHex = await widget.settingsService.getMainColorHex();
      final autoTheme = await widget.settingsService.getAutoThemeEnabled();

      if (mounted) {
        setState(() {
          userName = name;
          mainColor = hexToColor(colorHex);
          autoThemeEnabled = autoTheme;
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          userName = 'User';
          isLoading = false;
        });
      }
    }
  }

  Color hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  Future<void> _toggleAutoTheme() async {
    final newValue = !autoThemeEnabled;
    setState(() => autoThemeEnabled = newValue);
    await widget.settingsService.updateAutoThemeEnabled(newValue);
    widget.onThemeToggle();
  }

  Future<void> _changeUserName() async {
    final controller = TextEditingController(text: userName);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifica nome'),
        content: TextField(
          controller: controller,
          cursorColor: Colors.redAccent,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: const InputDecoration(
            labelText: 'Inserisci il tuo nome',
            labelStyle: TextStyle(color: Colors.redAccent),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Annulla',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != userName) {
                try {
                  await UserService().updateUserName(newName);
                  if (mounted) setState(() => userName = newName);
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Errore durante il salvataggio: $e'),
                    ),
                  );
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        children: [
          Text(
            'Ciao, $userName',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),

          _buildCustomButton(
            icon: Icons.logout,
            label: 'Logout',
            color: Colors.red,
            onTap: _signOut,
          ),
          _buildCustomButton(
            icon: widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            label: widget.isDarkMode ? 'Tema Chiaro' : 'Tema Scuro',
            color: Colors.cyan,
            onTap: () async {
              await UserService().updateThemePreference(!widget.isDarkMode);
              widget.onThemeToggle();
            },
          ),
          _buildCustomButton(
            icon: Icons.edit,
            label: 'Modifica nome',
            color: Colors.cyan,
            onTap: _changeUserName,
          ),

          const SizedBox(height: 20),
          _buildPersonalizationTile(),
          const SizedBox(height: 2),
          _buildPrivacyTile(),
        ],
      ),
    );
  }

  Widget _buildPrivacyTile() {
    const color = Colors.grey;

    return _buildTileContainer(
      title: 'Account e Privacy',
      icon: Icons.lock,
      color: color,
      children: [
        _buildTile(Icons.people, 'Gestione amici', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => GestioneAmiciPage()),
          );
        }),
        _buildTile(Icons.email, 'Modifica email', () {
          widget.settingsService.mostraDialogModificaEmail(context);
        }),
        _buildTile(Icons.lock_reset, 'Reimposta password', () {
          widget.settingsService.inviaEmailReimpostaPassword(context);
        }),
        _buildTile(
          Icons.delete_forever,
          'Elimina account',
          () => widget.settingsService.eliminaAccount(context),
          color: Colors.redAccent,
        ),
      ],
    );
  }

  Widget _buildPersonalizationTile() {
    const color = Colors.blueAccent;

    return _buildTileContainer(
      title: 'Personalizzazione',
      icon: Icons.palette,
      color: color,
      children: [
        _buildTile(
          Icons.color_lens,
          'Colore principale',
          widget.showColorPicker,
          color: color,
        ),
        _buildTile(
          Icons.brightness_auto,
          'Tema automatico',
          _toggleAutoTheme,
          color: color,
        ),
      ],
    );
  }

  Widget _buildTileContainer({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTileTheme(
          data: ExpansionTileThemeData(
            iconColor: color,
            collapsedIconColor: color,
            textColor: color.withOpacity(0.85),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 24,
            ),
            leading: Container(
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
            title: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.85),
              ),
            ),
            childrenPadding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 16,
            ),
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildTile(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    final effectiveColor = color ?? Colors.grey;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Icon(icon, color: effectiveColor),
      title: Text(label, style: TextStyle(color: effectiveColor)),
      onTap: onTap,
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

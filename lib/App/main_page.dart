import 'package:digital_wardrobe/App/menu_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'register_page.dart';

class MainPage extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;
  final VoidCallback showColorPicker;
  final Color mainColor;
  final void Function(Color newColor) onMainColorChanged;

  MainPage({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
    required this.mainColor,
    required this.showColorPicker,
    required this.onMainColorChanged,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool showLogin = true;

  void toggleScreens() => setState(() => showLogin = !showLogin);

  Widget _buildCardButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(width: 20),
            Text(title, style: TextStyle(fontSize: 18, color: color)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Utente autenticato e email verificata: vai a MenuPage
          if (snapshot.hasData && snapshot.data!.emailVerified) {
            return MenuPage(
              onThemeToggle: widget.onThemeToggle,
              isDarkMode: widget.isDarkMode,
              showColorPicker: widget.showColorPicker,
              mainColor: widget.mainColor,
              onMainColorChanged: widget.onMainColorChanged,
            );
          }

          // Utente autenticato ma email non verificata
          if (snapshot.hasData && !snapshot.data!.emailVerified) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Verifica la tua email per continuare."),
                  const SizedBox(height: 16),
                  _buildCardButton(
                    context: context,
                    title: "Invia di nuovo l'email",
                    icon: Icons.email,
                    color: Colors.indigo,
                    onTap: () async {
                      await snapshot.data!.sendEmailVerification();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Email di verifica inviata."),
                        ),
                      );
                    },
                  ),
                  _buildCardButton(
                    context: context,
                    title: "Torna ad Accedi",
                    icon: Icons.logout,
                    color: Colors.red,
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      setState(() {
                        showLogin = true;
                      });
                    },
                  ),
                ],
              ),
            );
          }

          // Non autenticato: login o registrazione
          return showLogin
              ? LoginPage(onClickedRegister: toggleScreens)
              : RegisterPage(onClickedLogin: toggleScreens);
        },
      ),
    );
  }
}

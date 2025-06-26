import 'package:digital_wardrobe/GestioneDB/firebase_options.dart';
import 'package:digital_wardrobe/pagine/Friends/friend_requests_page.dart';
import 'package:digital_wardrobe/pagine/Friends/friends_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'App/main_page.dart';
import 'GestioneDB/firestore_users.dart';

// Notifier globali per tema e colore
final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);
final colorNotifier = ValueNotifier<Color>(Colors.red);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await UserService().ensureInviteCodeExists();
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: colorNotifier,
      builder: (context, color, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, theme, _) {
            return MaterialApp(
              title: 'Armadio Digitale',
              debugShowCheckedModeBanner: false,
              themeMode: theme,
              theme: ThemeData.light().copyWith(
                primaryColor: color,
                appBarTheme: AppBarTheme(
                  backgroundColor: color,
                  centerTitle: true,
                  titleTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  iconTheme: const IconThemeData(color: Colors.white),
                ),
                bottomNavigationBarTheme: BottomNavigationBarThemeData(
                  selectedItemColor: color,
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                ),
              ),
              darkTheme: ThemeData.dark().copyWith(
                primaryColor: color.withOpacity(0.9),
                appBarTheme: AppBarTheme(
                  backgroundColor: color.withOpacity(0.9),
                  centerTitle: true,
                  titleTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  iconTheme: const IconThemeData(color: Colors.white),
                ),
                bottomNavigationBarTheme: BottomNavigationBarThemeData(
                  selectedItemColor: color.withOpacity(0.9),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.withOpacity(0.9),
                  ),
                ),
              ),
              home: DigitalWardrobeApp(),
              routes: {
                '/friendsPage': (context) => const FriendsPage(),
                '/friendRequestsPage': (context) => const FriendRequestsPage(),
              },
            );
          },
        );
      },
    );
  }
}

class DigitalWardrobeApp extends StatefulWidget {
  @override
  State<DigitalWardrobeApp> createState() => _DigitalWardrobeAppState();
}

class _DigitalWardrobeAppState extends State<DigitalWardrobeApp> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettingsFromFirestore();
  }

  Future<void> _loadSettingsFromFirestore() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _setDefaults();
        return;
      }

      final userService = UserService();
      final settingsService = UserServiceSettings();

      final autoThemeEnabled = await settingsService.getAutoThemeEnabled();
      final hexColor = await settingsService.getMainColorHex();

      final parsedColor = Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
      colorNotifier.value = parsedColor;

      if (autoThemeEnabled) {
        themeNotifier.value = getAutoThemeMode();
      } else {
        final isDarkMode = await userService.getSavedTheme();
        themeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      }
    } catch (e) {
      debugPrint('Errore caricamento impostazioni: $e');
      _setDefaults();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  ThemeMode getAutoThemeMode() {
    final hour = DateTime.now().hour;
    debugPrint("Ora corrente: $hour");
    if (hour >= 7 && hour < 20) {
      return ThemeMode.light;
    } else {
      return ThemeMode.dark;
    }
  }

  void _setDefaults() {
    themeNotifier.value = ThemeMode.light;
    colorNotifier.value = Colors.red;
  }

  void _toggleTheme() async {
    final newIsDarkMode = themeNotifier.value == ThemeMode.light;
    themeNotifier.value = newIsDarkMode ? ThemeMode.dark : ThemeMode.light;

    try {
      await UserService().updateThemePreference(newIsDarkMode);
    } catch (e) {
      debugPrint('Errore salvataggio tema: $e');
    }
  }

  void _updateMainColor(Color newColor) async {
    colorNotifier.value = newColor;

    try {
      final hexString =
          '#${newColor.value.toRadixString(16).substring(2).toUpperCase()}';
      await UserServiceSettings().saveMainColorHex(hexString);

      // Ricostruisci l'app dopo il salvataggio del colore
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Ignora se hai già un meccanismo reattivo corretto,
        // altrimenti forza il rebuild completo.
        runApp(MyApp());
      });
    } catch (e) {
      debugPrint('Errore salvataggio colore principale: $e');
    }
  }

  void _showColorPicker() async {
    Color tempColor = colorNotifier.value;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleziona colore principale'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: colorNotifier.value,
            onColorChanged: (color) {
              tempColor = color;
              colorNotifier.value = color; // aggiornamento live del colore
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annulla',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: tempColor,
              foregroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
            onPressed: () {
              Navigator.pop(context);
              _updateMainColor(tempColor);
            },
            child: Text(
              'Salva',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return MainPage(
      onThemeToggle: _toggleTheme,
      isDarkMode: themeNotifier.value == ThemeMode.dark,
      onMainColorChanged: _updateMainColor,
      mainColor: colorNotifier.value,
      showColorPicker: _showColorPicker,
    );
  }
}

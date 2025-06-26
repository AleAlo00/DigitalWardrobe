import 'package:digital_wardrobe/GestioneDB/firestore_users.dart';
import 'package:digital_wardrobe/pagine/Friends/friends_favorite_clothes_page.dart';
import 'package:digital_wardrobe/pagine/Wardbrode/all_clothes_page.dart';
import 'package:digital_wardrobe/pagine/Friends/friends_page.dart';
import 'package:digital_wardrobe/pagine/Outfit/OutfitHistoryPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserInfoPage extends StatefulWidget {
  final String? uid;

  const UserInfoPage({Key? key, this.uid}) : super(key: key);

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  String userName = 'Caricamento...';
  int totalClothes = 0;
  int favoriteClothes = 0;
  int totalFriends = 0;
  bool isLoading = true;
  String? _resolvedUid;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final uid = widget.uid ?? currentUser?.uid;

    if (uid == null) {
      setState(() {
        userName = 'Errore: utente non autenticato';
        isLoading = false;
      });
      return;
    }

    _resolvedUid = uid;

    final service = UserService();
    final data = await service.getUserInfoSummary(uid: uid);

    setState(() {
      userName = data['userName'] ?? 'Sconosciuto';
      totalClothes = data['totalClothes'] ?? 0;
      favoriteClothes = data['favoriteClothes'] ?? 0;
      totalFriends = data['totalFriends'] ?? 0;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Informazioni')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildCustomButton(
                    icon: Icons.checkroom,
                    label: 'Totale vestiti: $totalClothes',
                    onTap: () {
                      if (_resolvedUid != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllClothesPage(
                              uid: _resolvedUid!,
                              userId: _resolvedUid!,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  _buildCustomButton(
                    icon: Icons.people,
                    label: 'Amici: $totalFriends',
                    onTap: () {
                      if (_resolvedUid != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FriendsPage(userId: _resolvedUid),
                          ),
                        );
                      }
                    },
                    color: Colors.green,
                  ),
                  _buildCustomButton(
                    icon: Icons.favorite,
                    label: 'Preferiti dagli altri utenti',
                    onTap: () {
                      if (_resolvedUid != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FriendsFavoriteClothesPage(
                              userId: _resolvedUid!,
                            ),
                          ),
                        );
                      }
                    },
                    color: Colors.deepPurple,
                  ),

                  _buildCustomButton(
                    icon: Icons.history,
                    label: 'Visualizza Storico Outfit',
                    onTap: () {
                      if (_resolvedUid != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OutfitHistoryPage(),
                          ),
                        );
                      }
                    },
                    color: Colors.blueAccent,
                  ),
                ],
              ),
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

import 'package:digital_wardrobe/GestioneDB/firestore_users.dart';
import 'package:digital_wardrobe/pagine/Friends/OutfitHistoryPageFriends.dart';
import 'package:digital_wardrobe/pagine/Friends/all_clothes_page_friends.dart';
import 'package:flutter/material.dart';

class FriendsInfoPage extends StatefulWidget {
  final String? uid; // se null, mostra l'utente attuale

  const FriendsInfoPage({super.key, this.uid});

  @override
  State<FriendsInfoPage> createState() => _FriendsInfoPageState();
}

class _FriendsInfoPageState extends State<FriendsInfoPage> {
  String userName = 'Caricamento...';
  int totalClothes = 0;
  int favoriteClothes = 0;
  int totalFriends = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  bool canViewFriendOutfits = false; // variabile di stato

  Future<void> _loadUserInfo() async {
    final service = UserService();
    final data = await service.getUserInfoSummary(uid: widget.uid);

    // Recupera il numero outfit dell'utente attuale
    final currentUserOutfits = await service.getCurrentUserOutfitCount();

    setState(() {
      userName = data['userName'] ?? 'Sconosciuto';
      totalClothes = data['totalClothes'] ?? 0;
      favoriteClothes = data['favoriteClothes'] ?? 0;
      totalFriends = data['totalFriends'] ?? 0;
      canViewFriendOutfits = currentUserOutfits > 0; // controllo qui
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informazioni Amico'),
        backgroundColor: Colors.redAccent,
      ),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllClothesPageFriends(
                            uid: widget.uid ?? 'defaultUid',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildCustomButton(
                    icon: Icons.style,
                    label: 'Outfit Amico',
                    color: Colors.blueAccent,
                    onTap: () {
                      if (!canViewFriendOutfits) {
                        // Mostra messaggio di errore
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Devi prima aver creato almeno un outfit per vedere quelli degli amici.',
                            ),
                          ),
                        );
                        return;
                      }

                      if (widget.uid != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                FriendsOutfitsPage(friendUid: widget.uid!),
                          ),
                        );
                      }
                    },
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

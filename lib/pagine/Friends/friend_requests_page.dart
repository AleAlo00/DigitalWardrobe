import 'package:digital_wardrobe/GestioneDB/firestore_friends.dart';
import 'package:flutter/material.dart';

class FriendRequestsPage extends StatefulWidget {
  const FriendRequestsPage({super.key});

  @override
  State<FriendRequestsPage> createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  List<Map<String, dynamic>> friendRequests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFriendRequests();
  }

  Future<void> loadFriendRequests() async {
    final requests = await FriendService().getReceivedFriendRequests();
    setState(() {
      friendRequests = requests;
      isLoading = false;
    });
  }

  Future<void> acceptRequest(String userId) async {
    await FriendService().acceptFriendRequest(userId);
    await loadFriendRequests();
  }

  Future<void> rejectRequest(String userId) async {
    await FriendService().rejectFriendRequest(userId);
    await loadFriendRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Richeste di amicizia')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : friendRequests.isEmpty
          ? const Center(child: Text('Nessuna richiesta di amicizia ricevuta.'))
          : ListView.builder(
              itemCount: friendRequests.length,
              itemBuilder: (context, index) {
                final request = friendRequests[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(request['userName'] ?? 'Utente'),
                    subtitle: Text('ID: ${request['uid']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => acceptRequest(request['uid']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => rejectRequest(request['uid']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

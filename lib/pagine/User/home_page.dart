import 'dart:convert';
import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_wardrobe/GestioneDB/firestore_friends.dart';
import 'package:digital_wardrobe/GestioneDB/firestore_users.dart';
import 'package:digital_wardrobe/pagine/User/user_info_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = 'User';
  String inviteCode = '';
  bool isLoading = true;
  bool hasChangedName = false;

  File? _profileImage;
  String? _profileImageUrl;
  String? _profileImageBase64;

  final TextEditingController inviteCodeController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final name = await UserService().getUserName();
    final code = await UserService().getInviteCode();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data();

      final imageUrl = data?['profileImageUrl'] ?? '';
      final imageBase64 = data?['profileImageBase64'];

      setState(() {
        _profileImageUrl = imageUrl.isNotEmpty ? imageUrl : null;
        _profileImageBase64 = imageBase64;
      });
    }

    setState(() {
      userName = name;
      inviteCode = code;
      hasChangedName = name != 'User';
      isLoading = false;
    });
  }

  Future<Uint8List?> loadProfileImage(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (doc.exists &&
        doc.data() != null &&
        doc.data()!['profileImageBase64'] != null) {
      String base64String = doc.data()!['profileImageBase64'];
      return base64Decode(base64String);
    }
    return null;
  }

  Future<Uint8List?> compressImage(Uint8List imageData) async {
    return await FlutterImageCompress.compressWithList(
      imageData,
      quality: 20, // puoi regolare da 0 a 100
      format: CompressFormat.jpeg,
    );
  }

  Future<void> _uploadProfileImage(File image) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final originalBytes = await image.readAsBytes();

      final compressedBytes = await compressImage(originalBytes);
      if (compressedBytes == null) return;

      final base64String = base64Encode(compressedBytes);

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      await docRef.set({
        'profileImageBase64': base64String,
      }, SetOptions(merge: true));

      setState(() {
        _profileImageBase64 = base64String;
        _profileImageUrl = null; // opzionale, se usavi url
        _profileImage = image;
      });
    } catch (e) {
      print("Errore nel caricamento immagine: $e");
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          runSpacing: 20,
          children: [
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Scegli da file'),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile = await _picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (pickedFile != null) {
                  final file = File(pickedFile.path);
                  setState(() {
                    _profileImage = file;
                  });
                  await _uploadProfileImage(
                    file,
                  ); // passa solo il file, senza base64
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Scegli dalla galleria'),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile = await _picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (pickedFile != null) {
                  final file = File(pickedFile.path);
                  setState(() {
                    _profileImage = file;
                  });
                  await _uploadProfileImage(file);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Scatta una foto'),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile = await _picker.pickImage(
                  source: ImageSource.camera,
                );
                if (pickedFile != null) {
                  final file = File(pickedFile.path);
                  setState(() {
                    _profileImage = file;
                  });
                  await _uploadProfileImage(file);
                }
              },
            ),
            if (_profileImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Elimina foto',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _profileImage = null;
                    _profileImageBase64 = null;
                    _profileImageUrl = null;
                  });
                  // eventualmente cancella dal DB o aggiorna utente
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    if (_profileImage != null) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: FileImage(_profileImage!),
      );
    } else if (_profileImageBase64 != null) {
      Uint8List imageBytes = base64Decode(_profileImageBase64!);
      return CircleAvatar(radius: 60, backgroundImage: MemoryImage(imageBytes));
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: CachedNetworkImageProvider(_profileImageUrl!),
      );
    } else {
      return const CircleAvatar(
        radius: 60,
        child: Icon(Icons.person, size: 60, color: Colors.red),
      );
    }
  }

  Future<void> _changeUserName() async {
    final controller = TextEditingController(text: userName);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifica nome'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Inserisci il tuo nome'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != userName) {
                await UserService().updateUserName(newName);
                if (!mounted) return;
                Navigator.pop(context);
                setState(() {
                  userName = newName;
                  hasChangedName = true;
                });
              }
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendFriendRequest() async {
    final code = inviteCodeController.text.trim();
    if (code.isEmpty) return;

    final result = await FriendService().sendFriendRequestByCode(code);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: AutoSizeText(result ?? 'Richiesta inviata!')),
    );
    inviteCodeController.clear();
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
              child: AutoSizeText(
                label,
                maxLines: 1,
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profilo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Center(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  _buildProfileImage(),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              AutoSizeText(
                userName,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              if (!hasChangedName)
                GestureDetector(
                  onTap: _changeUserName,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    margin: const EdgeInsets.only(bottom: 30),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.red, width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.edit, size: 28, color: Colors.red),
                        SizedBox(width: 12),
                        AutoSizeText(
                          'Modifica nome',
                          maxLines: 1,
                          style: TextStyle(fontSize: 18, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
              _buildCustomButton(
                icon: Icons.info_outline,
                label: 'Informazioni',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserInfoPage()),
                  );
                },
                color: Colors.cyan,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: inviteCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: AutoSizeText('Codice copiato!')),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.redAccent),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.key, size: 30, color: Colors.redAccent),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AutoSizeText(
                          'Codice invito: $inviteCode',
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const Icon(Icons.copy, size: 22, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: inviteCodeController,
                cursorColor: Colors.redAccent,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Inserisci codice invito amico',
                  hintStyle: const TextStyle(color: Colors.black54),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.person_add, color: Colors.black),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.redAccent,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.redAccent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildCustomButton(
                icon: Icons.send,
                label: 'Invia richiesta amicizia',
                onTap: _sendFriendRequest,
              ),
              const SizedBox(height: 30),
              _buildCustomButton(
                icon: Icons.group,
                label: 'Amici',
                onTap: () => Navigator.pushNamed(context, '/friendsPage'),
                color: Colors.green,
              ),
              const SizedBox(height: 5),
              _buildCustomButton(
                icon: Icons.mail,
                label: 'Richieste amicizia',
                onTap: () =>
                    Navigator.pushNamed(context, '/friendRequestsPage'),
                color: Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

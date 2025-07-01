import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:pati_yuvaa/view/mesajlasma_ekran.dart';

class MesajlarEkran extends StatelessWidget {
  final String currentUserId;

  const MesajlarEkran({super.key, required this.currentUserId});

  Future<String?> _getProfileImageUrl(String kullaniciId) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profilResimleri/$kullaniciId/profilResmi.png');
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E9), // Açık pastel arka plan
      appBar: AppBar(
        title: const Text(
          "Sohbetler",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFFFFF1E0),
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('conversations')
            .orderBy('lastTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final conversations = snapshot.data!.docs;

          final myChats = conversations.where((doc) {
            final participants = List<String>.from(doc['participants'] ?? []);
            return participants.contains(currentUserId);
          }).toList();

          if (myChats.isEmpty) {
            return const Center(child: Text("Henüz mesajlaşma yok."));
          }

          return ListView.builder(
            itemCount: myChats.length,
            itemBuilder: (context, index) {
              final chat = myChats[index];
              final participants = List<String>.from(chat['participants']);
              final otherUserId = participants.firstWhere((id) => id != currentUserId);
              final lastMessage = chat['lastMessage'] ?? '';
              final lastTime = chat['lastTime']?.toDate();

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('Kullanicilar')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(title: Text("Yükleniyor..."));
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  final userName = userData['kullaniciAdi'] ?? 'Kullanıcı';

                  return FutureBuilder<String?>(
                    future: _getProfileImageUrl(otherUserId),
                    builder: (context, imageSnapshot) {
                      final imageUrl = imageSnapshot.data;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white70,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            leading: CircleAvatar(
                              backgroundImage: imageUrl != null
                                  ? NetworkImage(imageUrl)
                                  : const AssetImage('assets/default_profile.png') as ImageProvider,
                              radius: 26,
                            ),
                            title: Text(
                              userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              lastMessage.length > 50
                                  ? '${lastMessage.substring(0, 50)}...'
                                  : lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black87,
                              ),
                            ),
                            trailing: lastTime != null
                                ? Text(
                              "${lastTime.hour}:${lastTime.minute.toString().padLeft(2, '0')}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            )
                                : null,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MesajlasmaEkrani(
                                    conversationId: chat.id,
                                    currentUserId: currentUserId,
                                    otherUserId: otherUserId,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

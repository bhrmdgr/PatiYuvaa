import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class MesajlasmaEkrani extends StatefulWidget {
  final String conversationId;
  final String currentUserId;
  final String otherUserId;

  const MesajlasmaEkrani({
    required this.conversationId,
    required this.currentUserId,
    required this.otherUserId,
    super.key,
  });

  @override
  State<MesajlasmaEkrani> createState() => _MesajlasmaEkraniState();
}

class _MesajlasmaEkraniState extends State<MesajlasmaEkrani> {
  final TextEditingController _controller = TextEditingController();

  Future<Map<String, dynamic>?> _getOtherUserData() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('Kullanicilar')
        .doc(widget.otherUserId)
        .get();
    return userDoc.data();
  }

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

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final msgRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .collection('messages');

    await msgRef.add({
      'senderId': widget.currentUserId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .update({
      'lastMessage': text,
      'lastTime': FieldValue.serverTimestamp(),
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messagesRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true);

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getOtherUserData(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final userData = userSnapshot.data!;
        final userName = userData['kullaniciAdi'] ?? 'Kullanıcı';

        return Scaffold(
          backgroundColor: const Color(0xFFFFF3E9),
          appBar: AppBar(
            backgroundColor: Color(0xFFFFF1E0),
            elevation: 1,
            title: Row(
              children: [
                FutureBuilder<String?>(
                  future: _getProfileImageUrl(widget.otherUserId),
                  builder: (context, snapshot) {
                    final imageUrl = snapshot.data;
                    return CircleAvatar(
                      radius: 18,
                      backgroundImage: imageUrl != null
                          ? NetworkImage(imageUrl)
                          : const AssetImage('assets/default_profile.png') as ImageProvider,
                    );
                  },
                ),
                const SizedBox(width: 12),
                Text(
                  userName,
                  style: const TextStyle(color: Colors.black),
                ),
              ],
            ),
            iconTheme: const IconThemeData(color: Colors.black),
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: messagesRef.snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();

                    final messages = snapshot.data!.docs;

                    return ListView.builder(
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final data = messages[index].data() as Map<String, dynamic>;
                        final isMe = data['senderId'] == widget.currentUserId;

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            padding: const EdgeInsets.all(12),
                            constraints: const BoxConstraints(maxWidth: 280),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.orange.shade100 : Colors.grey.shade200,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft:
                                isMe ? const Radius.circular(16) : const Radius.circular(0),
                                bottomRight:
                                isMe ? const Radius.circular(0) : const Radius.circular(16),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              data['text'] ?? '',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF1F3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color:  Color(0xFFFFF1E0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: 'Mesaj yaz...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blueAccent),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

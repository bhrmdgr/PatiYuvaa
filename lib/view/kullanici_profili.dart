import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ilan_detay_ekran.dart';
import 'mesajlasma_ekran.dart';

class KullaniciProfiliEkrani extends StatefulWidget {
  final String kullaniciId;
  const KullaniciProfiliEkrani({super.key, required this.kullaniciId});

  @override
  State<KullaniciProfiliEkrani> createState() => _KullaniciProfiliEkraniState();
}

class _KullaniciProfiliEkraniState extends State<KullaniciProfiliEkrani> {
  String? kullaniciAdi;
  String? profilResmiUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Kullanicilar')
          .doc(widget.kullaniciId)
          .get();
      final ref = FirebaseStorage.instance
          .ref()
          .child('profilResimleri/${widget.kullaniciId}/profilResmi.png');
      final imageUrl = await ref.getDownloadURL();
      setState(() {
        kullaniciAdi = userDoc.data()?['kullaniciAdi'] ?? 'Bilinmiyor';
        profilResmiUrl = imageUrl;
        isLoading = false;
      });
    } catch (e) {
      print("Kullanıcı verisi alınamadı: $e");
      setState(() => isLoading = false);
    }
  }

  Future<int> _getPostCount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Kullanicilar')
        .doc(widget.kullaniciId)
        .collection('gonderiler')
        .get();
    return snapshot.size;
  }

  Stream<List<DocumentSnapshot>> _getUserPostsStream() {
    return FirebaseFirestore.instance
        .collection('Kullanicilar')
        .doc(widget.kullaniciId)
        .collection('gonderiler')
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF3E9),
        centerTitle: true,
        //title: const Text("Kullanıcı Profili"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            //const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber.shade400, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.shade100,
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundImage: NetworkImage(profilResmiUrl ?? ''),
                backgroundColor: Colors.grey[200],
                radius: 75,
              ),
            ),
            const SizedBox(height: 10),
            Text(kullaniciAdi ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6.0, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        FutureBuilder<int>(
                          future: _getPostCount(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return const Text("Hata");
                            } else {
                              return Text(
                                "${snapshot.data ?? 0}",
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 4),
                        const Text("post", style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.message, size: 30, color: Colors.black87),
                          onPressed: () {
                            final currentUser = FirebaseAuth.instance.currentUser!;
                            final ids = [currentUser.uid, widget.kullaniciId]..sort();
                            final conversationId = ids.join('_');
                            FirebaseFirestore.instance
                                .collection('conversations')
                                .doc(conversationId)
                                .set({
                              'participants': [currentUser.uid, widget.kullaniciId],
                              'lastMessage': '',
                              'lastTime': FieldValue.serverTimestamp(),
                            }, SetOptions(merge: true));
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MesajlasmaEkrani(
                                  conversationId: conversationId,
                                  currentUserId: currentUser.uid,
                                  otherUserId: widget.kullaniciId,
                                ),
                              ),
                            );
                          },
                        ),
                        const Text("mesaj gönder", style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(thickness: 2),
            const Text("Gönderiler", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            StreamBuilder<List<DocumentSnapshot>>(
              stream: _getUserPostsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Hata: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text("Bu kullanıcıya ait gönderi yok.");
                }
                final posts = snapshot.data!;
                final rows = <Widget>[];
                for (int i = 0; i < posts.length; i += 2) {
                  final first = posts[i];
                  final second = (i + 1 < posts.length) ? posts[i + 1] : null;
                  rows.add(
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Expanded(child: _buildPostCard(first)),
                          const SizedBox(width: 8),
                          if (second != null) Expanded(child: _buildPostCard(second)),
                        ],
                      ),
                    ),
                  );
                }
                return Column(children: rows);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => IlanDetayEkran(
              gonderiData: data,
              gonderiId: doc.id,
            ),
          ),
        );
      },
      child: Card(
        color: const Color(0xFFFFF3E9),
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['gonderiGorselUrl'] != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  data['gonderiGorselUrl'],
                  width: double.infinity,
                  height: 130,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['gonderiBasligi'] ?? 'Başlık Yok',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(data['sehir'] ?? 'Şehir bilgisi yok'),
                  Text(data['yas'] ?? 'Yaş bilgisi yok'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

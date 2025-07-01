import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pati_yuvaa/provider/user_provider.dart';
import 'package:pati_yuvaa/view/kullanici_profili.dart';
import 'package:pati_yuvaa/view/mesajlasma_ekran.dart';
import 'package:provider/provider.dart';

class IlanDetayEkran extends StatefulWidget {
  final Map<String, dynamic> gonderiData;
  final String gonderiId;

  const IlanDetayEkran({super.key, required this.gonderiData, required this.gonderiId});

  @override
  _IlanDetayEkranState createState() => _IlanDetayEkranState();
}

class _IlanDetayEkranState extends State<IlanDetayEkran> {
  late Future<Map<String, dynamic>> _userDataFuture;
  FirebaseAuth auth = FirebaseAuth.instance;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    final kullaniciId = widget.gonderiData['kullaniciId'] as String;
    _userDataFuture = _getUserData(kullaniciId);
    _checkIfFavorite();
  }

  Future<Map<String, dynamic>> _getUserData(String kullaniciId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('Kullanicilar').doc(kullaniciId).get();
      return userDoc.data() ?? {};
    } catch (e) {
      return {};
    }
  }

  Future<String> _getProfileImageUrl(String kullaniciId) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profilResimleri/$kullaniciId/profilResmi.png');
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Profil resmi yüklenemedi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 15,
              right: 10,
              child: Row(
                children: [
                  FutureBuilder<String>(
                    future: widget.gonderiData['kullaniciId'] == auth.currentUser?.uid
                        ? Future.value(Provider.of<UserProvider>(context, listen: false).userProfileUrl)
                        : _getProfileImageUrl(widget.gonderiData['kullaniciId']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                        return const Icon(Icons.error, color: Colors.red);
                      } else {
                        return CircleAvatar(
                          backgroundImage: NetworkImage(snapshot.data!),
                          radius: 20,
                          backgroundColor: Colors.grey[300],
                        );
                      }
                    },
                  ),

                  const SizedBox(width: 8),
                  FutureBuilder<Map<String, dynamic>>(
                    future: _userDataFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final userName = snapshot.data!['kullaniciAdi'] ?? 'Bilinmiyor';
                      return InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => KullaniciProfiliEkrani(
                              kullaniciId: widget.gonderiData['kullaniciId'],
                            ),
                          ),
                        ),
                        child: Text(
                          widget.gonderiData['kullaniciId'] == FirebaseAuth.instance.currentUser?.uid
                              ? Provider.of<UserProvider>(context, listen: false).userName
                              : userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                      );
                    },
                  ),
                ],
              ),
            ),
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Image.network(
                widget.gonderiData['gonderiGorselUrl'] ?? '',
                width: MediaQuery.of(context).size.width,
                height: 250,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 280,
              left: 10,
              right: 10,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9F4),
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 9,
                              child: Text(
                                widget.gonderiData['gonderiBasligi'] ?? 'Başlık Yok',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: IconButton(
                                icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
                                color: _isFavorite ? Colors.red : Colors.grey,
                                onPressed: _toggleFavorite,
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.gonderiData['gonderiAciklamasi'] ?? 'Açıklama Yok',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Divider(height: 30, color: Colors.grey),
                        _buildDetailRow('Şehir', widget.gonderiData['sehir']),
                        _buildDetailRow('Cinsiyet', widget.gonderiData['cinsiyet']),
                        _buildDetailRow('Yaş', widget.gonderiData['yas']),
                        _buildDetailRow('Aşı Durumu', widget.gonderiData['asiDurumu']),
                        _buildDetailRow('İç Parazit Aşısı', widget.gonderiData['icParazitAsisi']),
                        _buildDetailRow('Dış Parazit Aşısı', widget.gonderiData['disParazitAsisi']),
                        _buildDetailRow('Ücretsiz Sahiplendirme', widget.gonderiData['ucretsizSahiplendirme']),
                        _buildDetailRow('Kredi Kartı Ödeme', widget.gonderiData['krediKartiOdeme']),
                        _buildDetailRow('Şehir Dışına Gönderim', widget.gonderiData['sehirDisinaGonderim']),
                        _buildDetailRow('Tuvalet Eğitimi', widget.gonderiData['tuvaletEgitimi']),
                        _buildDetailRow('Kimden', widget.gonderiData['kimden']),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFFF3B0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.message),
                            label: const Text("Sahibe mesaj gönder",
                              style: TextStyle(color: Colors.black54),

                            ),
                            onPressed: () async {
                              final currentUser = FirebaseAuth.instance.currentUser!;
                              final otherUserId = widget.gonderiData['kullaniciId'];
                              final ids = [currentUser.uid, otherUserId]..sort();
                              final conversationId = ids.join('_');

                              final convoRef = FirebaseFirestore.instance.collection('conversations').doc(conversationId);
                              final convoDoc = await convoRef.get();
                              if (!convoDoc.exists) {
                                await convoRef.set({
                                  'participants': [currentUser.uid, otherUserId],
                                  'lastMessage': '',
                                  'lastTime': FieldValue.serverTimestamp(),
                                });
                              }

                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => MesajlasmaEkrani(
                                    conversationId: conversationId,
                                    currentUserId: currentUser.uid,
                                    otherUserId: otherUserId,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value != null ? value.toString() : 'Bilinmiyor',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final favCollection = FirebaseFirestore.instance
          .collection('Kullanicilar')
          .doc(user.uid)
          .collection('favoriler');

      if (_isFavorite) {
        await favCollection.doc(widget.gonderiId).delete();
      } else {
        await favCollection.doc(widget.gonderiId).set(widget.gonderiData);
      }

      setState(() {
        _isFavorite = !_isFavorite;
      });
    }
  }

  void _checkIfFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('Kullanicilar')
          .doc(user.uid)
          .collection('favoriler')
          .doc(widget.gonderiId)
          .get();

      setState(() {
        _isFavorite = doc.exists;
      });
    }
  }
}

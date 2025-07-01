import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pati_yuvaa/view/ana_sayfa.dart';
import 'package:pati_yuvaa/view/ilan_detay_ekran.dart';
import 'package:pati_yuvaa/view/ilan_olusturma_ekran.dart';
import 'package:pati_yuvaa/view/mesajlar_ekran.dart';
import 'package:pati_yuvaa/view/profil_ekran.dart';

class FavorilerEkran extends StatefulWidget {
  const FavorilerEkran({super.key});

  @override
  State<FavorilerEkran> createState() => _FavorilerEkranState();
}

class _FavorilerEkranState extends State<FavorilerEkran> {
  int _selectedIndex = 0;
  List<DocumentSnapshot> _favoritePosts = []; // Favori gönderi verileri

  @override
  void initState() {
    super.initState();
    _fetchFavoritePosts();
  }

  Future<void> _fetchFavoritePosts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final favoritesDoc = await FirebaseFirestore.instance
            .collection('Kullanicilar')
            .doc(user.uid)
            .collection('favoriler')
            .get();

        setState(() {
          _favoritePosts = favoritesDoc.docs;
        });
      } catch (e) {
        print("Favori gönderiler yüklenemedi: $e");
      }
    }
  }

  Future<void> _removeFromFavorites(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('Kullanicilar')
            .doc(user.uid)
            .collection('favoriler')
            .doc(postId)
            .delete();

        setState(() {
          _favoritePosts.removeWhere((post) => post.id == postId);
        });
      } catch (e) {
        print("Gönderi favorilerden çıkarılamadı: $e");
      }
    }
  }

  void _showRemoveConfirmationDialog(String postId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Favorilerden Kaldırma"),
          content: const Text("Bu gönderiyi favorilerden kaldırmak istediğinize emin misiniz?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Hayır"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeFromFavorites(postId);
              },
              child: const Text("Evet"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      centerTitle: true,
      title: const Text(
        "Favori İlanlarım",
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      backgroundColor: Color(0xFFFFF1E0),
      elevation: 1,
      iconTheme: const IconThemeData(color: Colors.black),
    );
  }


  Widget _buildBody() {
    return Container(
      color: const Color(0xFFFFF3E9), // Pastel arka plan
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _favoritePosts.isEmpty
            ? const Center(child: Text("Favori gönderiniz yok."))
            : ListView.builder(
          itemCount: _favoritePosts.length,
          itemBuilder: (context, index) {
            final post = _favoritePosts[index];
            final data = post.data() as Map<String, dynamic>;

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IlanDetayEkran(
                      gonderiData: data,
                      gonderiId: post.id,
                    ),
                  ),
                );
              },
              child: Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data['gonderiGorselUrl'] != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.network(
                          data['gonderiGorselUrl'],
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  data['gonderiBasligi'] ?? 'Başlık Yok',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.favorite, color: Colors.red),
                                onPressed: () {
                                  _showRemoveConfirmationDialog(post.id);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow('Şehir', data['sehir']),
                          _buildDetailRow('Yaş', data['yas']),
                          _buildDetailRow('Ücretsiz Sahiplendirme', data['ucretsizSahiplendirme']),
                          _buildDetailRow('Kimden', data['kimden']),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }


  Widget _buildBottomNavBar() {
    return Container(
      height: 60,
      width: 200,
      margin: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => _onItemTapped(0),
          ),
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () => _onItemTapped(1),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 5.0,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              onPressed: () => _onItemTapped(2),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () => _onItemTapped(3),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => _onItemTapped(4),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 0:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AnaSayfa()),
          );
          break;
        case 1:
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MesajlarEkran(currentUserId: FirebaseAuth.instance.currentUser!.uid),
            ),
          );
          break;
        case 2:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const IlanOlusturmaEkran()),
          );
          break;
        case 3:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FavorilerEkran()),
          );
          break;
        case 4:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfilEkran()),
          );
          break;
      }
    });
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
}

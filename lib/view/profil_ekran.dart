import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pati_yuvaa/provider/user_provider.dart'; // ✅ Eklendi
import 'package:pati_yuvaa/view/ana_sayfa.dart';
import 'package:pati_yuvaa/view/favoriler_ekran.dart';
import 'package:pati_yuvaa/view/giris_ekran.dart';
import 'package:pati_yuvaa/view/ilan_detay_ekran.dart';
import 'package:pati_yuvaa/view/ilan_olusturma_ekran.dart';
import 'package:pati_yuvaa/view/mesajlar_ekran.dart';
import 'package:pati_yuvaa/view/profil_duzenle_ekran.dart';

class ProfilEkran extends StatefulWidget {
  const ProfilEkran({super.key});

  @override
  State<ProfilEkran> createState() => _ProfilEkranState();
}

class _ProfilEkranState extends State<ProfilEkran> {
  int _selectedIndex = 0;
  User? _user;
  late Future<List<DocumentSnapshot>> _postsFuture;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String? indirmeBaglantisi;

  bool _isDeleting = false;


  @override
  void initState() {
    super.initState();
  }







  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFFFF3E9),
          appBar: _buildAppBar(),
          body: SingleChildScrollView(
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.amber.shade400,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.shade100,
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 85,
                          backgroundImage: userProvider.userProfileUrl.isNotEmpty
                              ? NetworkImage(userProvider.userProfileUrl)
                              : null,
                          backgroundColor: Colors.grey[200],
                          child: userProvider.userProfileUrl.isEmpty
                              ? const Icon(Icons.pets, size: 40, color: Colors.grey)
                              : null,
                        )
                      ),
                      Positioned(
                        bottom: 0,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple.shade50,
                            foregroundColor: Colors.deepPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          icon: const Icon(Icons.edit),
                          label: const Text("Profilimi Düzenle"),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProfilDuzenleEkran()),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  /// 👤 Kullanıcı Adı
                  Text(
                    userProvider.userName.isNotEmpty
                        ? userProvider.userName
                        : "Kullanıcı Adı",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6.0,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${userProvider.postCount}',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),

                              const SizedBox(height: 4),
                              Text(
                                "post",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(
                    color: Colors.grey,
                    thickness: 2,
                    indent: 20,
                    endIndent: 20,
                  ),
                  _buildGonderiler(),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomNavBar(),
        );
      },
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFFFF1E0),
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: const Text("Profilim"),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AnaSayfa()),
                (Route<dynamic> route) => false,
          );
        },
      ),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.exit_to_app),
          onPressed: () => _oturumuKapat(context),
        ),
      ],
    );
  }

  Widget _buildGonderiler() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final posts = userProvider.userPosts;

        if (userProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (posts.isEmpty) {
          return const Center(child: Text('Gönderiniz yok.'));
        }

        final rows = <Widget>[];
        for (int i = 0; i < posts.length; i += 2) {
          final firstPost = posts[i];
          final secondPost = (i + 1 < posts.length) ? posts[i + 1] : null;

          rows.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: _buildPostCard(firstPost)),
                if (secondPost != null) const SizedBox(width: 8),
                if (secondPost != null) Expanded(child: _buildPostCard(secondPost)),
              ],
            ),
          );
        }

        return Column(children: rows);
      },
    );
  }


  Widget _buildPostCard(DocumentSnapshot doc) {
    String imageUrl = doc['gonderiGorselUrl'] ?? 'VarsayılanResimURL';
    String title = doc['gonderiBasligi'] ?? 'Başlık Yok';
    String city = doc['sehir'] ?? 'Bilgi Yok';
    String age = doc['yas'] ?? 'Bilgi Yok';
    String freeAdoption = doc['ucretsizSahiplendirme'] ?? 'Bilgi Yok';
    String from = doc['kimden'] ?? 'Bilgi Yok';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IlanDetayEkran(
              gonderiData: doc.data() as Map<String, dynamic>,
              gonderiId: doc.id,
            ),
          ),
        );
      },
      child: Card(
        color: Color(0xFFFFF3E9),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IlanDetayEkran(
                gonderiData: doc.data() as Map<String, dynamic>,
                gonderiId: doc.id,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showDeleteConfirmationDialog(doc.id),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )

    );
  }



  Widget _buildDetailRow(String label, String? value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(value ?? 'Bilgi Yok'),
      ],
    );
  }




  void _showDeleteConfirmationDialog(String docId) {
    showDialog(
      context: context,
      barrierDismissible: false, // Dışarı tıklayınca kapanmasın
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Silme Onayı'),
              content: _isDeleting
                  ? const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              )
                  : const Text('Bu gönderiyi silmek istediğinizden emin misiniz?'),
              actions: _isDeleting
                  ? []
                  : [
                TextButton(
                  child: const Text('İptal'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('Sil'),
                  onPressed: () async {
                    setState(() => _isDeleting = true);
                    try {
                      await FirebaseFirestore.instance
                          .collection('Kullanicilar')
                          .doc(auth.currentUser?.uid)
                          .collection('gonderiler')
                          .doc(docId)
                          .delete();

                      // 🔁 Listeyi güncelle
                      Provider.of<UserProvider>(context, listen: false).fetchUserPosts();

                      Navigator.of(context).pop(); // Dialog kapansın
                    } catch (e) {
                      print("Silme hatası: $e");
                      setState(() => _isDeleting = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Gönderi silinirken hata oluştu.")),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      setState(() {
        _isDeleting = false;
      });
    });
  }


  Widget _buildBottomNavBar() {
    return Container(
      height: 60,
      width: 200,
      margin: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30), // Elips şeklinde
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
            icon: const Icon(Icons.message), // Mesajlar ikonu
            onPressed: () => _onItemTapped(1),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.blue, // Kutunun arka plan rengi
              shape: BoxShape.circle, // Kutunun şeklini daire yap
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 5.0,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.white), // Fotoğraf makinesi ikonu
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
      switch (_selectedIndex) {
        case 0:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AnaSayfa()),
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
            MaterialPageRoute(builder: (context) => const IlanOlusturmaEkran()),
          );
          break;
        case 3:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FavorilerEkran()),
          );
          break;
        case 4:

          break;
      }
    });
  }

  void _oturumuKapat(BuildContext context) async {
    bool? confirmSignOut = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Çıkış Yap"),
          content: const Text("Çıkış yapmak istediğinizden emin misiniz?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Hayır"),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text("Evet"),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmSignOut == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const GirisEkran()),
            (Route<dynamic> route) => false,
      );
    }
  }
}


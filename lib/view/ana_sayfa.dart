import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:pati_yuvaa/provider/user_provider.dart';
import 'package:pati_yuvaa/view/favoriler_ekran.dart';
import 'package:pati_yuvaa/view/ilan_detay_ekran.dart';
import 'package:pati_yuvaa/view/ilan_olusturma_ekran.dart';
import 'package:pati_yuvaa/view/mesajlar_ekran.dart';
import 'package:pati_yuvaa/view/profil_ekran.dart';
import 'package:provider/provider.dart';

import '../model/sehirler.dart';
import '../viewModel/filter_Dialog.dart';

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';


  int _selectedIndex = 0;
  String _selectedCategory = 'Hepsi'; // Kategori seçimi için değişken
  String _selectedCity = 'Hepsi';
  String _selectedAge = 'Hepsi';
  bool _isFreeAdoption = false;
  String _selectedFrom = 'Barınak';

  FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String? indirmeBaglantisi;
  String? kullaniciAdi;
  bool isLoading = true; // Kullanıcı bilgileri yükleniyor mu kontrolü
  List<DocumentSnapshot> _posts = []; // Gönderi verileri için liste
  List<DocumentSnapshot> _filteredPosts = []; // Filtrelenmiş gönderi verileri

  @override
  void initState() {
    super.initState();
    //baglantiAl();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      //_kullaniciBilgileriniGetir();
      _fetchPosts(); // Tüm gönderileri yükle
    });
  }

  void _fetchPosts() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collectionGroup("gonderiler")
          .orderBy('tarih', descending: true)
          .get();

      setState(() {
        _posts = querySnapshot.docs;

        // Burada 'Hepsi' ise filtreleme yapma, hepsini göster
        _filteredPosts = _filterPosts(_posts);

      });
    } catch (e) {
      print("Gönderiler yüklenemedi: $e");
    }
  }


  List<DocumentSnapshot> _filterPosts(List<DocumentSnapshot> posts) {
    return posts.where((post) {
      final data = post.data() as Map<String, dynamic>;

      final matchCategory = _selectedCategory == 'Hepsi' || data['kategori'] == _selectedCategory;
      final matchCity = _selectedCity == 'Hepsi' || data['sehir'] == _selectedCity;
      final matchAge = _selectedAge == 'Hepsi' || data['yas'] == _selectedAge;
      final matchFreeAdoption = _isFreeAdoption ? data['ucretsizSahiplendirme'] == true : true;

      final matchSearch = _searchQuery.isEmpty ||
          (data['gonderiBasligi']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
          (data['aciklama']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
          (data['sehir']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
          (data['kategori']?.toString().toLowerCase().contains(_searchQuery) ?? false);

      return matchCategory && matchCity && matchAge && matchFreeAdoption && matchSearch;
    }).toList();
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF1E0),
      //appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFFFF1E0),
      automaticallyImplyLeading: false,
      toolbarHeight: 100,
      title: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Text(
            "Merhaba ${userProvider.userName.isNotEmpty ? userProvider.userName : 'Misafir'} !",
            style: const TextStyle(
              fontSize: 20,
            ),
          );
        },
      ),
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              return Row(
                children: [
                  ClipOval(
                    child: userProvider.userProfileUrl.isEmpty
                        ? const SizedBox(
                      height: 40,
                      width: 40,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : Image.network(
                      userProvider.userProfileUrl,
                      height: 85,
                      width: 85,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 30),
                ],
              );
            },
          ),
        ),
      ],

    );
  }


  Widget _buildBody() {
    return Consumer<UserProvider>(
        builder: (context, userProvider, child)
    {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildAppBar(),
          Container(
            child: Row(
              children: [
                Image.asset("assets/kedihome.png", height: 60),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Arayın...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                        _filteredPosts = _filterPosts(_posts);
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return FilterDialog(
                      onFilterApplied: (category, city, age, isFreeAdoption) {
                        setState(() {
                          _selectedCategory = category;
                          _selectedCity = city;
                          _selectedAge = age;
                          _isFreeAdoption = isFreeAdoption;
                          _filteredPosts = _filterPosts(_posts);
                        });
                      },
                    );
                  },
                );
              },
              icon: const Icon(Icons.filter_list),
              label: const Text("Filtreleyin"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[200],
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                fixedSize: const Size(500, 36),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildCategoryButtons(),
          const SizedBox(height: 16),

          ..._filteredPosts.map((post) {
            final data = post.data() as Map<String, dynamic>;
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        IlanDetayEkran(
                          gonderiData: data,
                          gonderiId: post.id,
                        ),
                  ),
                );
              },
              child: Card(
                color: Color(0xFFFFF9F9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data['gonderiGorselUrl'] != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius
                            .circular(16)),
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
                          Text(
                            data['gonderiBasligi'] ?? 'Başlık Yok',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildDetailRow('Şehir', data['sehir']),
                          _buildDetailRow('Yaş', data['yas']),
                          _buildDetailRow('Ücretsiz Sahiplendirme',
                              data['ucretsizSahiplendirme']),
                          _buildDetailRow('Kimden', data['kimden']),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      );
    }
    );
  }


  Widget _buildCategoryChips() {
    List<String> categories = ['Hepsi', 'Kedi', 'Köpek', 'Kuş', 'Balık', 'Kaplumbağa'];

    return Wrap(
      spacing: 8,
      children: categories.map((category) {
        return ChoiceChip(
          label: Text(category),
          selected: _selectedCategory == category,
          selectedColor: Colors.orange.shade200,
          onSelected: (bool selected) {
            setState(() {
              _selectedCategory = selected ? category : 'Hepsi';
              _filteredPosts = _filterPosts(_posts);
            });
          },
          backgroundColor: Colors.grey.shade200,
          labelStyle: const TextStyle(fontWeight: FontWeight.w500),
        );
      }).toList(),
    );
  }



  Widget _buildCategoryButtons() {
    List<String> categories = ['Hepsi', 'Kedi', 'Köpek', 'Kuş', 'Balık', 'Kaplumbağa'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Center(
        child: Row(
          children: categories.map((category) {
            final bool isSelected = _selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (category == 'Hepsi') {
                      _selectedCategory = 'Hepsi';
                      _selectedCity = 'Hepsi';
                      _selectedAge = 'Hepsi';
                      _isFreeAdoption = false;
                    } else {
                      _selectedCategory = category;
                    }
                    _filteredPosts = _filterPosts(_posts);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? Colors.orange.shade200 : Colors.grey.shade200,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: isSelected ? 4 : 1,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: Text(
                  category,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            );
          }).toList(),
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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfilEkran()),
          );
          break;
      }
    });
  }

  /*Future<void> _kullaniciBilgileriniGetir() async {
    final user = auth.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('Kullanicilar').doc(user.uid).get();
        setState(() {
          kullaniciAdi = userDoc.data()?['kullaniciAdi'];
          isLoading = false; // Kullanıcı bilgileri yüklendi
        });
        final ref = _storage.ref().child('profilResimleri/${user.uid}/profilResmi.png');
        indirmeBaglantisi = await ref.getDownloadURL();
      } catch (e) {
        print("Profil resmi yüklenemedi: $e");
      }
    }
  }*/

  /*Future<void> baglantiAl() async {
    final user = auth.currentUser;
    if (user != null) {
      try {
        final ref = _storage.ref().child('profilResimleri/${user.uid}/profilResmi.png');
        indirmeBaglantisi = await ref.getDownloadURL();
        setState(() {});
      } catch (e) {
        print("Profil resmi yüklenemedi: $e");
      }
    }
  }*/

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

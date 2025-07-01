import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pati_yuvaa/view/profil_ekran.dart';
import 'dart:io';

class ProfilDuzenleEkran extends StatefulWidget {
  const ProfilDuzenleEkran({super.key});

  @override
  State<ProfilDuzenleEkran> createState() => _ProfilDuzenleEkranState();
}

class _ProfilDuzenleEkranState extends State<ProfilDuzenleEkran> {
  final TextEditingController _isimController = TextEditingController();
  final TextEditingController _telNoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth auth = FirebaseAuth.instance;


  File? yuklenecekDosya;
  String? indirmeBaglantisi;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String? _currentProfileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    baglantiAl();
  }

  Future<void> _loadUserData() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('Kullanicilar')
        .doc(auth.currentUser?.email)
        .get();

    if (userDoc.exists) {
      setState(() {
        _isimController.text = userDoc['isim'] ?? '';
        _emailController.text = userDoc['email'] ?? '';
        _telNoController.text = userDoc['telefon'] ?? '';
        _currentProfileImageUrl = userDoc['profilResmiUrl'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  Color(0xFFFFF3E9),
      appBar: _buildAppBar(context),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Color(0xFFFFF1E0),
      centerTitle: true,
      title: const Text("Profilimi Düzenle"),
      actions: <Widget>[
        TextButton(
          child: const Text(
            "Kaydet",
            style: TextStyle(fontSize: 18),
          ),
          onPressed: () {
            _saveProfile(context);
          },
        )
      ],
    );
  }

  Widget _buildBody() {
    return Container(
      color: const Color(0xFFFFF3E9),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: indirmeBaglantisi != null
                      ? NetworkImage(indirmeBaglantisi!)
                      : null,
                  child: indirmeBaglantisi == null
                      ? const CircularProgressIndicator()
                      : null,
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: _galeridenYukle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            _buildTextField("İsim-Soyisim", _isimController),
            const SizedBox(height: 20),
            _buildTextField("Email", _emailController),
            const SizedBox(height: 20),
            _buildTextField("Telefon Numarası", _telNoController),
            const SizedBox(height: 20),
            _buildTextField("Parola", _passwordController, obscureText: true),
          ],
        ),
      ),
    );
  }


  Widget _buildTextField(String label, TextEditingController controller, {bool obscureText = false}) {
    return Container(
      color:  Color(0xFFFFF3E9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white70,
            ),
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                hintText: label,
              ),
            ),
          ),
        ],
      ),
    );
  }



  Future<void> _saveProfile(BuildContext context) async {
    try {
      // Firestore'da kullanıcı bilgilerini güncelle
      await FirebaseFirestore.instance.collection('Kullanicilar').doc(auth.currentUser?.uid).update({
        'kullaniciAdi': _isimController.text,
        'email': _emailController.text,
        'telefon': _telNoController.text,
        'profilResmiUrl': indirmeBaglantisi, // Profil resmi URL'si de güncellenir
      });

      // Eğer parola değişmişse, Firebase Authentication'da da güncelle
      if (_passwordController.text.isNotEmpty) {
        await auth.currentUser?.updatePassword(_passwordController.text);
      }

      // Eğer email değişmişse, Firebase Authentication'da da güncelle
      if (_emailController.text.isNotEmpty && _emailController.text != auth.currentUser?.email) {
        await auth.currentUser?.updateEmail(_emailController.text);
      }

      // Profil ekranına geri dön
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfilEkran()),
      );
    } catch (e) {
      print("Profil güncelleme hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profil güncellenirken bir hata oluştu: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }


  Future<void> _galeridenYukle() async {
    final ImagePicker picker = ImagePicker();
    final XFile? alinanGorsel = await picker.pickImage(source: ImageSource.gallery);

    if (alinanGorsel != null) {
      setState(() {
        yuklenecekDosya = File(alinanGorsel.path);
      });

      try {
        Reference referansYol = FirebaseStorage.instance
            .ref()
            .child("profilResimleri")
            .child(auth.currentUser!.uid)
            .child("profilResmi.png");

        UploadTask yuklemeGorevi = referansYol.putFile(yuklenecekDosya!);

        TaskSnapshot snapshot = await yuklemeGorevi;
        String url = await snapshot.ref.getDownloadURL();

        setState(() {
          indirmeBaglantisi = url;
        });
      } catch (e) {
        print("Dosya yükleme hatası: $e");
      }
    }
  }

  void baglantiAl() async {
    try {
      String baglanti = await FirebaseStorage.instance
          .ref()
          .child("profilResimleri")
          .child(auth.currentUser!.uid)
          .child("profilResmi.png")
          .getDownloadURL();

      setState(() {
        indirmeBaglantisi = baglanti;
      });
    } catch (e) {
      print("Profil resmi alma hatası: $e");
    }
  }


}

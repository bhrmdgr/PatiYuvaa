import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class KayitEkran extends StatefulWidget {
  const KayitEkran({super.key});

  @override
  State<KayitEkran> createState() => _KayitEkranState();
}

class _KayitEkranState extends State<KayitEkran> {
  final TextEditingController _isimController = TextEditingController();
  final TextEditingController _telNoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth auth = FirebaseAuth.instance;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown[300],
        centerTitle: true,
        title: const Text("Kullanıcı Oluştur",
        style: TextStyle(
          fontSize: 30,
          color: Colors.white
        ),
        ),
      ),
      body: _buildBody(),
    );
  }


  Widget _buildBody(){
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Text("İsim-Soyisim"),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white54,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.brown, width: 2),
              ),
              child: TextFormField(
                controller: _isimController,
                decoration:  const InputDecoration(
                  hintText: "   Adınız",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text("Telefon Numarası"),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white54,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.brown, width: 2),
              ),
              child: TextFormField(
                controller: _telNoController,
                decoration: const InputDecoration(
                  hintText: "   Telefon Numaranız",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text("E-Mail Adresi"),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white54,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.brown, width: 2),
              ),
              child: TextFormField(
                controller: _emailController,
                decoration:  const InputDecoration(
                  hintText: "   E-Mail Adresiniz",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text("Parola"),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white54,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.brown, width: 2),
              ),
              child: TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration:  const InputDecoration(
                  hintText: "   Parolanız",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 100),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[300], // Açık kahverengi arka plan rengi
                minimumSize: const Size(400, 50), // Butonu uzatmak için boyutlandırma
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // İç boşluk ayarlaması
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Buton köşelerini yuvarlatma
                ),
              ),
              child: const Text("Kayıt olun",
                style: TextStyle(
                    fontSize: 25,
                    color: Colors.white
                ),
              ),
              onPressed: (){
                _kayitOL();

              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _kayitOL() async {

    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
          email: _emailController.text, password: _passwordController.text)
          .then((kullanici) {
        FirebaseFirestore.instance
            .collection("Kullanicilar")
            .doc(auth.currentUser?.uid)
            .set({
          "kullaniciAdi": _isimController.text,
          "telefonNumarasi": _telNoController.text,
          "email": _emailController.text,
          "parola": _passwordController.text,

        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kayıt işlemi başarılı. Lütfen Giriş ekranından giriş yapınız.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kayıt sırasında bir hata oluştu: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }



}

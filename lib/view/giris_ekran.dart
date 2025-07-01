import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pati_yuvaa/view/ana_sayfa.dart';
import 'package:pati_yuvaa/view/kayit_ekran.dart';

class GirisEkran extends StatefulWidget {
  const GirisEkran({super.key});

  @override
  State<GirisEkran> createState() => _GirisEkranState();
}

class _GirisEkranState extends State<GirisEkran> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),

    );
  }

  Widget _buildBody() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
            image: AssetImage('assets/backround.png'
            ),
                fit: BoxFit.cover
        )
      ),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height, // Ekran yüksekliği kadar yer kaplar
          ),
          child: Column(
            children: [
              const SizedBox(height: 50,),
              Image.asset('assets/patiyuvagiris.jpg', height: 300,),
              const SizedBox(height: 50,),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 50,),
                          _buildTextField(_emailController, "   e-mail"),
                          const SizedBox(height: 20),
                          _buildTextField(_passwordController, "   password", isPassword: true),
                          const SizedBox(height: 20),
                          if (_errorMessage.isNotEmpty) ...[
                            Text(
                              _errorMessage,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 20),
                          ],
                          const SizedBox(height: 100,),
                          _buildButton(
                            text: "Giriş Yap",
                            onPressed: _girisYap,
                          ),
                          const SizedBox(height: 20,),
                          _buildButton(
                            text: "Kayıt Ol",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const KayitEkran()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white54,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.brown, width: 2),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildButton({required String text, required VoidCallback onPressed}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.brown[300],
        minimumSize: const Size(400, 50),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(fontSize: 25, color: Colors.white),
      ),
    );
  }

  Future<void> _girisYap() async {
    setState(() {
      _errorMessage = ''; // Hata mesajını sıfırla
    });

    try {
      // Giriş işlemi
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // Başarılı giriş sonrası anasayfaya yönlendirme
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AnaSayfa()),
      );
    } on FirebaseAuthException catch (e) {
      // Hata mesajı yakalama
      setState(() {
        if (e.code == 'user-not-found') {
          _errorMessage = 'Kullanıcı bulunamadı. Lütfen kayıt olun.';
        } else if (e.code == 'wrong-password') {
          _errorMessage = 'Hatalı şifre. Lütfen şifrenizi kontrol edin.';
        } else {
          _errorMessage = 'Giriş yapılamadı: ${e.message}';
        }
      });
    }
  }

}

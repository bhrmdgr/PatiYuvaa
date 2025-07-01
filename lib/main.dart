import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Provider'ı ekledik
import 'package:pati_yuvaa/firebase_options.dart';
import 'package:pati_yuvaa/view/ana_sayfa.dart';
import 'package:pati_yuvaa/view/giris_ekran.dart';
import 'package:pati_yuvaa/provider/user_provider.dart'; // UserProvider'ı ekledik

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AnaUygulama());
}

class AnaUygulama extends StatelessWidget {
  const AnaUygulama({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'Pati Yuvaa',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const YonetimEkrani(),
      ),
    );
  }
}

class YonetimEkrani extends StatelessWidget {
  const YonetimEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Kullanıcı varsa bilgilerini yükle
      Provider.of<UserProvider>(context, listen: false).fetchUserData();
      Provider.of<UserProvider>(context, listen: false).fetchUserPosts();
      return const AnaSayfa();
    } else {
      return const GirisEkran();
    }
  }
}

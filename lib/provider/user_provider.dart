import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class UserProvider with ChangeNotifier {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';
  String _userProfileUrl = '';
  List<DocumentSnapshot> _userPosts = [];
  int _postCount = 0;


  // Getter'lar
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userPhone => _userPhone;
  String get userProfileUrl => _userProfileUrl;
  List<DocumentSnapshot> get userPosts => _userPosts;
  int get postCount => _postCount;


  Future<void> fetchUserData() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_currentUser != null) {
        final doc = await _firestore
            .collection('Kullanicilar')
            .doc(_currentUser!.uid)
            .get();

        final data = doc.data();
        if (data != null) {
          _userName = data['kullaniciAdi'] ?? '';
          _userEmail = data['email'] ?? '';
          _userPhone = data['telefon'] ?? '';
        }
        // Profil fotoğrafı bağlantısını al
        try {
          final ref = FirebaseStorage.instance
              .ref()
              .child('profilResimleri/${_currentUser!.uid}/profilResmi.png');
          _userProfileUrl = await ref.getDownloadURL();
        } catch (e) {
          print("Profil fotoğrafı alınamadı: $e");
          _userProfileUrl = '';
        }
      }
    } catch (e) {
      print("Kullanıcı verisi alınırken hata: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchUserPosts() async {
    if (_currentUser == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Kullanicilar')
          .doc(_currentUser!.uid)
          .collection('gonderiler')
          .get();

      _userPosts = snapshot.docs;
      _postCount = snapshot.size;
      notifyListeners();
    } catch (e) {
      print("İlanlar alınamadı: $e");
    }
  }


  void clearUser() {
    _userName = '';
    _userEmail = '';
    _userPhone = '';
    notifyListeners();
  }
}

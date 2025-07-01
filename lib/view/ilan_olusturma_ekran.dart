import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pati_yuvaa/model/sehirler.dart';
import 'package:pati_yuvaa/provider/user_provider.dart';
import 'package:pati_yuvaa/view/profil_ekran.dart';
import 'package:provider/provider.dart';

class IlanOlusturmaEkran extends StatefulWidget {
  const IlanOlusturmaEkran({super.key});

  @override
  State<IlanOlusturmaEkran> createState() => _IlanOlusturmaEkranState();
}

class _IlanOlusturmaEkranState extends State<IlanOlusturmaEkran> {
  final TextEditingController _gonderiBaslikController = TextEditingController();
  final TextEditingController _gonderiAciklamaController = TextEditingController();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  String? indirmeBaglantisi;
  bool _isLoading = false;
  XFile? _image;

  // Seçimler
  String _selectedCategory = 'Kedi';
  String _selectedCity = 'İstanbul';
  String _selectedGender = 'Erkek';
  String _selectedAge = '0-4 ay';
  String _selectedVaccinationStatus = 'Aşılı';
  String _selectedInternalParasiteStatus = 'Yapılmadı';
  String _selectedExternalParasiteStatus = 'Yapılmadı';
  String _selectedFreeAdoption = 'Hayır';
  String _selectedCreditCardPayment = 'Hayır';
  String _selectedShippingOutsideCity = 'Hayır';
  String _selectedToiletTraining = 'Var';
  String _selectedFromWho = 'Sahibinden';

  final List<String> evetHayir = ['Evet', 'Hayır'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F0),
      appBar: AppBar(
        backgroundColor: Color(0xFFFFF1E0),
        centerTitle: true,
        title: const Text("İlan Oluştur"),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildTextInput("Gönderi Başlığı", _gonderiBaslikController),
                const SizedBox(height: 12),
                _buildDropdown("Kategori", _selectedCategory, ['Kedi', 'Köpek', 'Kuş', 'Kaplumbağa', 'Balık'],
                        (val) => setState(() => _selectedCategory = val!)),
                _buildDropdown("İl", _selectedCity, Sehirler.getSehirler(),
                        (val) => setState(() => _selectedCity = val!)),
                _buildDropdown("Cinsiyet", _selectedGender, ['Erkek', 'Dişi'],
                        (val) => setState(() => _selectedGender = val!)),
                _buildDropdown("Yaş", _selectedAge, ['0-4 ay', '4-8 ay', '8-12 ay', '1', '2', '3', '4', '5', '6', '7', '7+'],
                        (val) => setState(() => _selectedAge = val!)),
                _buildDropdown("Aşı Durumu", _selectedVaccinationStatus, ['Aşılı', 'Aşısız'],
                        (val) => setState(() => _selectedVaccinationStatus = val!)),
                _buildDropdown("İç Parazit Aşısı", _selectedInternalParasiteStatus, ['Yapıldı', 'Yapılmadı'],
                        (val) => setState(() => _selectedInternalParasiteStatus = val!)),
                _buildDropdown("Dış Parazit Aşısı", _selectedExternalParasiteStatus, ['Yapıldı', 'Yapılmadı'],
                        (val) => setState(() => _selectedExternalParasiteStatus = val!)),
                _buildDropdown("Ücretsiz Sahiplendirme", _selectedFreeAdoption, evetHayir,
                        (val) => setState(() => _selectedFreeAdoption = val!)),
                _buildDropdown("Kredi Kartı Ödeme", _selectedCreditCardPayment, evetHayir,
                        (val) => setState(() => _selectedCreditCardPayment = val!)),
                _buildDropdown("Şehir Dışına Gönderim", _selectedShippingOutsideCity, evetHayir,
                        (val) => setState(() => _selectedShippingOutsideCity = val!)),
                _buildDropdown("Tuvalet Eğitimi", _selectedToiletTraining, ['Var', 'Yok'],
                        (val) => setState(() => _selectedToiletTraining = val!)),
                _buildDropdown("Kimden", _selectedFromWho, ['Sahibinden', 'Pet Shop dan', 'Barınaktan'],
                        (val) => setState(() => _selectedFromWho = val!)),

                const SizedBox(height: 16),
                const Text("Gönderi Görseli", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.orange.shade200),
                    borderRadius: BorderRadius.circular(12),
                    color: Color(0xFFFFF7F0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.shade100,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _image != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(_image!.path), height: 200, width: double.infinity, fit: BoxFit.cover),
                  )
                      : const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Icon(Icons.photo, size: 100, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[200],
                    foregroundColor: Colors.black54,
                  ),
                  onPressed: _pickImage,
                  child: const Text("Görsel Ekle"),
                ),
                const SizedBox(height: 20),
                _buildTextInput("Açıklama", _gonderiAciklamaController, maxLines: 6),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[200],
                    foregroundColor: Colors.black54,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 4,
                  ),
                  onPressed: _createPost,
                  child: const Text("Gönderiyi Oluştur", style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String currentValue, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        DropdownButtonFormField<String>(
          value: currentValue,
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildTextInput(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() => _image = pickedImage);
    }
  }

  Future<void> _uploadImage() async {
    if (_image != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child("gonderiGorselleri")
          .child(auth.currentUser!.uid)
          .child(_gonderiBaslikController.text)
          .child("myImage.png");

      final snapshot = await storageRef.putFile(File(_image!.path));
      indirmeBaglantisi = await snapshot.ref.getDownloadURL();
    }
  }

  Future<void> _createPost() async {
    if (_gonderiBaslikController.text.isEmpty || _gonderiAciklamaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Başlık ve açıklama boş bırakılamaz')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _uploadImage();
      final uid = auth.currentUser!.uid;

      await FirebaseFirestore.instance
          .collection("Kullanicilar")
          .doc(uid)
          .collection("gonderiler")
          .doc(_gonderiBaslikController.text)
          .set({
        "gonderiBasligi": _gonderiBaslikController.text,
        "gonderiAciklamasi": _gonderiAciklamaController.text,
        "kullaniciId": uid,
        "gonderiGorselUrl": indirmeBaglantisi,
        "kategori": _selectedCategory,
        "sehir": _selectedCity,
        "cinsiyet": _selectedGender,
        "yas": _selectedAge,
        "asiDurumu": _selectedVaccinationStatus,
        "icParazitAsisi": _selectedInternalParasiteStatus,
        "disParazitAsisi": _selectedExternalParasiteStatus,
        "ucretsizSahiplendirme": _selectedFreeAdoption,
        "krediKartiOdeme": _selectedCreditCardPayment,
        "sehirDisinaGonderim": _selectedShippingOutsideCity,
        "tuvaletEgitimi": _selectedToiletTraining,
        "kimden": _selectedFromWho,
        "tarih": Timestamp.now(),


      });
      Provider.of<UserProvider>(context, listen: false).fetchUserPosts();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gönderi başarıyla oluşturuldu')));
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ProfilEkran()),
            (_) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

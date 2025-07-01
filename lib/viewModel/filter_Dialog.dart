import 'package:flutter/material.dart';
import '../model/sehirler.dart';

class FilterDialog extends StatefulWidget {
  final Function(String, String, String, bool) onFilterApplied;

  const FilterDialog({required this.onFilterApplied, super.key});

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  String category = 'Hepsi';
  String city = 'Hepsi';
  String age = 'Hepsi';
  bool isFreeAdoption = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Filtreler"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Cins:", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DropdownButton<String>(
              value: category,
              onChanged: (String? newValue) {
                setState(() {
                  category = newValue!;
                });
              },
              items: ['Hepsi', 'Kedi', 'Köpek', 'Kuş', 'Balık', 'Kaplumbağa']
                  .map((value) => DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              ))
                  .toList(),
            ),

            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Şehir:", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DropdownButton<String>(
              value: city,
              onChanged: (String? newValue) {
                setState(() {
                  city = newValue!;
                });
              },
              items: ['Hepsi', ...Sehirler.getSehirler()]
                  .map((value) => DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              ))
                  .toList(),
            ),

            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Yaş:", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DropdownButton<String>(
              value: age,
              onChanged: (String? newValue) {
                setState(() {
                  age = newValue!;
                });
              },
              items: ['Hepsi', '0-4 ay', '5-12 ay', '1 yaş üstü']
                  .map((value) => DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              ))
                  .toList(),
            ),

            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text("Ücretsiz Sahiplendirme"),
              value: isFreeAdoption,
              onChanged: (bool value) {
                setState(() {
                  isFreeAdoption = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("Kapat"),
        ),
        TextButton(
          onPressed: () {
            widget.onFilterApplied(category, city, age, isFreeAdoption);
            Navigator.of(context).pop();
          },
          child: const Text("Uygula"),
        ),
      ],
    );
  }
}

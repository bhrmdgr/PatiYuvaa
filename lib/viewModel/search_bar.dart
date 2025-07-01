import 'package:flutter/material.dart';

class SearchBar extends StatefulWidget {
  final String hintText;
  final Function(String)? onSearch;

  const SearchBar({Key? key, required this.hintText, this.onSearch})
      : super(key: key);

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Text değiştikçe UI'yi güncelle
    _controller.addListener(() {
      setState(() {}); // suffixIcon tetiklenmesi için
    });
  }

  void _onSearchTextChanged(String text) {
    if (widget.onSearch != null) {
      widget.onSearch!(text.trim()); // Boşlukları temizleyerek gönder
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onSearchTextChanged,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            _controller.clear();
            _onSearchTextChanged('');
          },
        )
            : null,
        filled: true,
        fillColor: Colors.grey[200],
        hintText: widget.hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      ),
    );
  }
}

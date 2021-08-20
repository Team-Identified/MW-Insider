import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mw_insider/config.dart';


class SearchBar extends StatefulWidget {
  final void Function(String) onSubmit;

  SearchBar({Key key, @required this.onSubmit}) : super(key: key);

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  TextEditingController _searchController;
  String _searchText = "";

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth * 0.9,
      // height: 50.0,
      child: Theme(
        data: ThemeData(
          primaryColor: themeColor,
        ),
        child: TextField(
          controller: _searchController,
          onSubmitted: widget.onSubmit,
          decoration: InputDecoration(
            isDense: true,
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: themeColor, width: 1.5),
              borderRadius: BorderRadius.all(
                Radius.circular(20.0),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(20.0),
              ),
            ),
            hintText: "Поиск объектов",
            prefixIcon: Icon(Icons.search, color: themeColorShade),
            suffixIcon: _searchText.isEmpty
                ? null
                : InkWell(
              onTap: () {
                setState(() {
                  _searchController.clear();
                });
              },
              child: Icon(Icons.clear, color: themeColorShade),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mw_insider/config.dart';


class NothingAroundBanner extends StatelessWidget {
  const NothingAroundBanner({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
        child: Column(
          children: [
            Text(
                "Мы не знаем интересных объектов поблизости",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  color: themeColor,
                ),
            ),
            Text(
              "☹",
              style: TextStyle(
                fontSize: 40,
                color: themeColor,
              ),
            ),
          ],
        )
    );
  }
}

